extends Node3D

# Array to hold all your music tracks
var playlist = [
	"res://Assets/Sounds/lofi-beat-chill.mp3",
	"res://Assets/Sounds/chroma-dusk.mp3",
	"res://Assets/Sounds/night-detective.mp3"
]

var current_track = 0  # Index of current playing track
@onready var audio_player = get_node("../AudioStreamPlayer3D")

# Pitch control variables
var base_pitch = 1.0
var pitch_step = 0.1
var min_pitch = 0.5
var max_pitch = 2.0

func _ready():
	# Load the first track
	load_track(current_track)

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

# New pitch control functions
func pitch_up():
	var new_pitch = min(audio_player.pitch_scale + pitch_step, max_pitch)
	audio_player.pitch_scale = new_pitch
	print("Pitch up: ", new_pitch)

func pitch_down():
	var new_pitch = max(audio_player.pitch_scale - pitch_step, min_pitch)
	audio_player.pitch_scale = new_pitch
	print("Pitch down: ", new_pitch)

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

# New functions for pitch control spheres
func _on_sphere_pitch_up_area_entered(area):
	if area.is_in_group("controller"):
		pitch_up()

func _on_sphere_pitch_down_area_entered(area):
	if area.is_in_group("controller"):
		pitch_down()
