# ge1_ca1_musicvisulaizer
 Game engines CA Music Visualizer
 ![image](https://github.com/user-attachments/assets/e8129813-9269-413f-aabb-6c3c5dbe2f1a)


System Overview

This project is an XR-based audio visualization system that creates an immersive experience where shapes respond to different frequency ranges of music. The system runs on the Meta Quest platform using Godot 4.3 and OpenXR.

Core Features:

- Real-time audio frequency analysis
- Dynamic visual feedback through shape manipulation
- XR performance
- Interactive object placement (Play/pause, next, prev, pitch up/down)

Visual response

Each frequency range corresponds to a specific shape:

- Cube: Bass frequencies
- Prism: Low-mid frequencies
- Sphere: High-mid frequencies
- Cylinder: Treble frequencies

- Motion System
Shapes exhibit movements:

- rotation around the player
- Vertical oscillation
- Audio-reactive scaling
- Color cycling based on audio energy
- Dynamic material properties

Frequencies were divided into
- bass
- low mid
- high mid
- treble

Which were then assigned to the different shapes (bass - cube , low mid - prism, high mid - sphere and treble - cylinder)

The shapes then react to the songs played and will rotate and orbit the player. The player can then play or pause the song, go to the next or previous song. They can also adjust the pitch up and down which affects the speed of the song.

Export Settings:

- Platform: Android
- XR Mode: OpenXR
- Vulkan Mobile: Enabled
- Minimum API Level: 29

Git Work flow
- main
- shapes
- playPause (latest work)

Future improvements
- adding more effects to songs like reverb, compression, volume control
- a more user friendly UI
- player movement
- ability to add more shapes and more control

By Eric O'Brien C21750829

