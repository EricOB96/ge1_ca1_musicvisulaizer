extends Node3D

# Array to hold all your music tracks
var playlist = [
	"res://Assets/Sounds/lofi-beat-chill.mp3",
	"res://Assets/Sounds/chroma-dusk.mp3",
	"res://Assets/Sounds/night-detective.mp3"
]

var current_track = 0  # Index of current playing track
@onready var audio_player = get_node("../AudioStreamPlayer3D")

# Called when the scene loads
func _ready():
	# Load the first track
	load_track(current_track)

# Function to load and play a track
func load_track(track_index):
	var stream = load(playlist[track_index])
	audio_player.stream = stream
	audio_player.play()

# Functions for track control
func play_pause():
	if audio_player.playing:
		audio_player.stream_paused = true
	else:
		audio_player.stream_paused = false

func next_track():
	current_track = (current_track + 1) % playlist.size()
	load_track(current_track)

func previous_track():
	current_track = (current_track - 1) if current_track > 0 else playlist.size() - 1
	load_track(current_track)

# Function to handle sphere interactions
func _on_sphere_play_pause_area_entered(area):
	if area.is_in_group("controller"):
		play_pause()

func _on_sphere_next_area_entered(area):
	if area.is_in_group("controller"):
		next_track()

func _on_sphere_previous_area_entered(area):
	if area.is_in_group("controller"):
		previous_track()
