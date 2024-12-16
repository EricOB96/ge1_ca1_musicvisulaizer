extends Node3D

# Define frequency ranges for audio analysis
# Each range corresponds to a different shape and part of the audio spectrum
const FREQ_RANGES = {
	"bass": Vector2(20.0, 250.0),      # Low frequencies - Cube
	"low_mid": Vector2(250.0, 1000.0),  # Low-mid frequencies - Prism
	"high_mid": Vector2(1000.0, 4000.0),# High-mid frequencies - Sphere
	"treble": Vector2(4000.0, 20000.0)  # High frequencies - Cylinder
}

# Variables controlling visual effects
var hover_offset = 0.0          # Controls up/down floating motion
var pulse_offset = 0.0          # Controls pulsing/breathing effect
var shape_heights = {}          # Stores original height of each shape
var max_height_variation = 2.0  # Maximum distance shapes can move up/down
var twist_angle = 0.0          # Controls rotation/twisting motion
var spiral_height = 0.0        # Controls height in spiral movement

# Variables for shape rotation around player
var rotation_center: Vector3    # Center point of rotation (player position)
@export_range(1.0, 20.0, 0.5) var rotation_radius: float = 10.0  # Distance from center
@export_range(0.0, 2.0, 0.1) var rotation_speed: float = 0.2    # Speed of rotation
var individual_angles = {}      # Tracks rotation angle of each shape

# Dictionary to store references to all shapes in the scene
@onready var shapes = {
	"Cube": null,
	"Prism": null,
	"Sphere": null,
	"Cylinder": null,
	"Planet_stars": null
}

# Storage for shape properties
var original_scales = {}    # Original size of each shape
var materials = {}         # Material references for each shape
var prev_energies = {}     # Previous frame's audio energy values
var color_phases = {}      # Controls color cycling for each shape

# Smoothing factor for transitions (0.0 to 1.0)
var smooth_factor = 0.3    # Lower = smoother, higher = more responsive

func _ready():
	# Initialize shapes and their properties
	for child in get_children():
		if child is MeshInstance3D or child.name == "Planet_stars":
			var shape_name = child.name
			shapes[shape_name] = child # Store shape reference
			original_scales[shape_name] = child.scale # Store original size
			color_phases[shape_name] = 0.0 # Initialize color phase
			shape_heights[shape_name] = child.global_position.y # Store original height
			if child is MeshInstance3D:
				setup_material(shape_name, child) # Setup materials for mesh instances
	
	# Space shapes evenly around the circle
	var shape_count = shapes.size()
	var angle_step = 2.0 * PI / shape_count
	var i = 0
	for shape_name in shapes.keys():
		individual_angles[shape_name] = i * angle_step
		i += 1
			
	# Initialize audio energy tracking
	for range_name in FREQ_RANGES.keys():
		prev_energies[range_name] = 0.0
	
	# Setup audio analysis
	ensure_spectrum_analyzer()

func _process(delta):
	# Update effect timers
	hover_offset += delta * 2.0
	pulse_offset += delta * 1.5
	twist_angle += delta * 0.3
	
	# Get player position as rotation center
	var player_origin = get_node("../Player")
	if player_origin:
		rotation_center = player_origin.global_position
		
	# Update each shape's position and rotation
	for shape_name in shapes:
		var shape = shapes[shape_name]
		if shape:
			# Calculate orbital movement with spiral effect
			individual_angles[shape_name] += rotation_speed * delta
			var angle = individual_angles[shape_name]
			
			# Calculate position with height variation and spiral motion
			var height_offset = sin(hover_offset + angle) * max_height_variation
			var spiral_radius = rotation_radius + (cos(pulse_offset + angle) * 2.0)
			
			# Set new position
			var x = rotation_center.x + spiral_radius * cos(angle)
			var z = rotation_center.z + spiral_radius * sin(angle)
			var base_height = shape_heights.get(shape_name, 0.0)
			var y = base_height + height_offset
			shape.global_position = Vector3(x, y, z)
			
			# Add tumbling based on audio energy
			var shape_energy = get_shape_energy(shape_name)
			var tumble_speed = shape_energy * 5.0
			shape.rotate_x(sin(twist_angle) * delta * tumble_speed)
			shape.rotate_z(cos(twist_angle) * delta * tumble_speed)
			
			# Make shapes face player smoothly
			var current_rot = shape.rotation
			shape.look_at(rotation_center)
			var target_rot = shape.rotation
			shape.rotation = current_rot.lerp(target_rot, delta * 5.0)
	
	# Get audio spectrum data
	var bus_index = AudioServer.get_bus_index("Master")
	var spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)
	if !spectrum:
		return
	
	# Process audio reactivity for each shape
	process_shape("Cube", "bass", 2.0, spectrum, delta)
	process_shape("Prism", "low_mid", 1.5, spectrum, delta)
	process_shape("Sphere", "high_mid", 1.0, spectrum, delta)
	process_shape("Cylinder", "treble", 1.2, spectrum, delta)

# Helper function to get audio energy values for each shape
func get_shape_energy(shape_name: String) -> float:
	# Return the appropriate frequency range energy for each shape
	match shape_name:
		"Cube": return prev_energies.get("bass", 0.0)      # Bass frequencies
		"Prism": return prev_energies.get("low_mid", 0.0)  # Low-mid frequencies
		"Sphere": return prev_energies.get("high_mid", 0.0)# High-mid frequencies
		"Cylinder": return prev_energies.get("treble", 0.0)# High frequencies
	return 0.0  # Default return if shape not found

# Setup the audio analyzer for frequency analysis
func ensure_spectrum_analyzer():
	# Get the master audio bus
	var bus_index = AudioServer.get_bus_index("Master")
	var effect = AudioServer.get_bus_effect_instance(bus_index, 0)
	
	# Add spectrum analyzer if it doesn't exist
	if !effect:
		var spectrum = AudioEffectSpectrumAnalyzer.new()
		spectrum.buffer_length = 0.1  # How much audio to analyze at once
		AudioServer.add_bus_effect(bus_index, spectrum)

# Setup materials for each shape
func setup_material(shape_name: String, mesh: MeshInstance3D):
	var material = StandardMaterial3D.new()
	
	# Assign initial colors based on shape type
	match shape_name:
		"Cube":
			material.albedo_color = Color.RED
		"Prism":
			material.albedo_color = Color.YELLOW
		"Sphere":
			material.albedo_color = Color.GREEN
		"Cylinder":
			material.albedo_color = Color.BLUE
	
	# Configure material properties
	material.metallic = 0.8               # How metallic the material looks
	material.metallic_specular = 0.7      # Intensity of specular highlights
	material.roughness = 0.2              # How smooth/rough the surface appears
	material.emission_enabled = true       # Enable glowing effect
	material.emission = material.albedo_color * 0.3  # Base glow color
	material.emission_energy = 1.0         # Initial glow intensity
	
	# Apply material to mesh and store reference
	mesh.material_override = material
	materials[shape_name] = material

# Process audio reactivity for each shape
func process_shape(shape_name: String, range_name: String, intensity: float, spectrum, delta: float):
	var mesh = shapes[shape_name]
	if !mesh:
		return
		
	# Get the frequency range for this shape
	var freq_range = FREQ_RANGES[range_name]
	
	# Calculate audio magnitude for the frequency range
	var magnitude = spectrum.get_magnitude_for_frequency_range(
		freq_range.x, 
		freq_range.y
	).length()
	
	# Convert to decibels and normalize to 0-1 range
	var energy = float(clamp((60.0 + linear_to_db(magnitude)) / 60.0, 0.0, 1.0))
	# Smooth the energy value for more fluid transitions
	energy = lerp(float(prev_energies[range_name]), energy, smooth_factor)
	prev_energies[range_name] = energy
	
	# Scale the shape based on audio energy
	var base_scale = original_scales[shape_name]
	var target_scale = base_scale * (1.0 + energy * intensity)
	mesh.scale = mesh.scale.lerp(target_scale, smooth_factor)
	
	# Add wobble effect based on audio energy
	var wobble = sin(Time.get_ticks_msec() * 0.005 * energy) * 0.2 * energy
	mesh.scale += Vector3(wobble, wobble, wobble)
	
	# Update material effects
	update_material(shape_name, energy, delta)

# Update material properties based on audio energy
func update_material(shape_name: String, energy: float, delta: float):
	var material = materials[shape_name]
	if !material:
		return
	
	# Update color cycling phase
	color_phases[shape_name] += delta * (1 + energy * 2)
	
	# Create smooth color transitions
	var hue = fmod(color_phases[shape_name], 1.0)  # Cycle through colors
	var saturation = 0.8 + (energy * 0.2)          # Increase color intensity with energy
	var value = 0.8 + (energy * 0.2)               # Increase brightness with energy
	var color = Color.from_hsv(hue, saturation, value)
	
	# Apply material updates
	material.albedo_color = color                   # Base color
	material.emission = color * (0.3 + energy * 2.0)# Glow color
	# Pulsing glow intensity based on audio
	material.emission_energy = 1 + energy * 2 + (sin(Time.get_ticks_msec() * 0.003) * energy)
	material.metallic = 0.8 + (energy * 0.2)       # Dynamic metallic effect
	material.roughness = max(0.1, 0.3 - (energy * 0.2))  # Dynamic smoothness
