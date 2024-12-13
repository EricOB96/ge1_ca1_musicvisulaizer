extends Node3D

# Frequencies
const FREQ_RANGES = {
	"bass": Vector2(20.0, 250.0),      # For the cube
	"low_mid": Vector2(250.0, 1000.0),  # For the prism
	"high_mid": Vector2(1000.0, 4000.0),# For the sphere
	"treble": Vector2(4000.0, 20000.0)  # For the cylinder
}


# Rotation of the shapes around the player
var rotation_center: Vector3
var rotation_radius: float = 3.0
var rotation_speed: float = 0.2
var individual_angles = {}

# References to our mesh instances
@onready var shapes = {
	"cube": null,
	"prism": null,
	"sphere": null,
	"cylinder": null
}

# Store original properties
var original_scales = {}
var materials = {}
var prev_energies = {}
var color_phases = {}

# Smoothing factor for transitions
var smooth_factor = 0.3

func _ready():
	# Find all mesh instances in the scene
	for child in get_children():
		if child is MeshInstance3D:
			var shape_name = child.name.to_lower()
			shapes[shape_name] = child
			original_scales[shape_name] = child.scale
			color_phases[shape_name] = 0.0
			setup_material(shape_name, child)
	
	var shape_count = shapes.size()
	var angle_step = 2.0 * PI / shape_count
	var i = 0
	for shape_name in shapes.keys():
		individual_angles[shape_name] = i * angle_step
		i += 1
			
	# Initialize energy tracking
	for range_name in FREQ_RANGES.keys():
		prev_energies[range_name] = 0.0
	
	# Make sure we have a spectrum analyzer
	ensure_spectrum_analyzer()
	
	# Get audio player
	var audio_player = get_node("../AudioStreamPlayer3D")
	if audio_player:
		var audio_stream = load("res://Assets/Sounds/lofi-beat-chill.mp3")
		audio_player.stream = audio_stream
		audio_player.play()

func ensure_spectrum_analyzer():
	# Check if we already have a spectrum analyzer
	var bus_index = AudioServer.get_bus_index("Master")
	var effect = AudioServer.get_bus_effect_instance(bus_index, 0)
	
	if !effect:
		# Add spectrum analyzer if it doesn't exist
		var spectrum = AudioEffectSpectrumAnalyzer.new()
		spectrum.buffer_length = 0.1
		AudioServer.add_bus_effect(bus_index, spectrum)

func setup_material(shape_name: String, mesh: MeshInstance3D):
	# Create unique material for each shape
	var material = StandardMaterial3D.new()
	
	# Set initial colors based on shape
	match shape_name:
		"cube":
			material.albedo_color = Color.RED
		"prism":
			material.albedo_color = Color.YELLOW
		"sphere":
			material.albedo_color = Color.GREEN
		"cylinder":
			material.albedo_color = Color.BLUE
	
	# Configure material properties
	material.metallic = 0.8
	material.metallic_specular = 0.7
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	material.emission_energy = 1.0
	
	# Assign material to mesh
	mesh.material_override = material
	materials[shape_name] = material

func _process(delta):
	
	# Movement of shapes
	var player_origin = get_node("../Player")
	if player_origin:
		rotation_center = player_origin.global_position
		
	for shape_name in shapes:
		var shape = shapes[shape_name]
		if shape:
			individual_angles[shape_name] += rotation_speed * delta
			
			var angle = individual_angles[shape_name]
			var x = rotation_center.x + rotation_radius * cos(angle)
			var z = rotation_center.z + rotation_radius * sin(angle)
			
			var y = shape.global_position.y
			shape.global_position = Vector3(x, y, z)
			shape.look_at(rotation_center)
	
	var bus_index = AudioServer.get_bus_index("Master")
	var spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)
	if !spectrum:
		return
	
	# Process each shape
	process_shape("cube", "bass", 2.0, spectrum, delta)
	process_shape("prism", "low_mid", 1.5, spectrum, delta)
	process_shape("sphere", "high_mid", 1.0, spectrum, delta)
	process_shape("cylinder", "treble", 1.2, spectrum, delta)

func process_shape(shape_name: String, range_name: String, intensity: float, spectrum, delta: float):
	var mesh = shapes[shape_name]
	if !mesh:
		return
		
	var freq_range = FREQ_RANGES[range_name]
	
	# Get magnitude for frequency range
	var magnitude = spectrum.get_magnitude_for_frequency_range(
		freq_range.x, 
		freq_range.y
	).length()
	
	# Convert to decibels and normalize - ensure float values
	var energy = float(clamp((60.0 + linear_to_db(magnitude)) / 60.0, 0.0, 1.0))
	
	# Smooth the energy value - explicitly convert to float
	energy = lerp(float(prev_energies[range_name]), energy, smooth_factor)
	prev_energies[range_name] = energy
	
	# Update scale (pulsing effect)
	var base_scale = original_scales[shape_name]
	var target_scale = base_scale * (1.0 + energy * intensity)
	mesh.scale = mesh.scale.lerp(target_scale, smooth_factor)
	
	# Add rotation based on energy
	mesh.rotate_y(energy * delta * 2.0)
	
	# Update material
	update_material(shape_name, energy, delta)

func update_material(shape_name: String, energy: float, delta: float):
	var material = materials[shape_name]
	if !material:
		return
	
	# Update color phase
	color_phases[shape_name] += delta * (1 + energy * 2)
	
	# Create smooth color transition
	var hue = fmod(color_phases[shape_name], 1.0)
	var saturation = 0.8 + (energy * 0.2)
	var value = 0.8 + (energy * 0.2)
	var color = Color.from_hsv(hue, saturation, value)
	
	# Apply material updates
	material.albedo_color = color
	material.emission = color * (0.3 + energy * 2.0)
	material.emission_energy = 1 + energy * 2
	material.metallic = 0.8 + (energy * 0.2)
	material.roughness = max(0.1, 0.3 - (energy * 0.2))
