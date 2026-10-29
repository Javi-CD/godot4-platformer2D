<div align="center">
  <img src="icon.svg" width="96" height="96" alt="Godot Engine Logo" />
  <h1>Pixel Platformer 2D</h1>
  <p>A 2D precision arcade platformer developed with Godot Engine 4, focusing on modular architecture, finite state machines, and responsive gameplay physics.</p>

  <p>
    <a href="https://godotengine.org/"><img src="https://img.shields.io/badge/Godot_Engine-4.x-478CBF?logo=godotengine&logoColor=white" alt="Godot 4" /></a>
    <img src="https://img.shields.io/badge/Language-GDScript_2.0-355570" alt="GDScript 2.0" />
    <img src="https://img.shields.io/badge/Genre-2D_Precision_Platformer-2B2D42" alt="Genre" />
    <img src="https://img.shields.io/badge/Architecture-FSM_%26_Observer-4A4E69" alt="Architecture" />
    <img src="https://img.shields.io/badge/Purpose-Educational_Study-2A9D8F" alt="Educational Project" />
  </p>
</div>

---

## Project Overview and Purpose

This project was developed strictly for learning and practical experimentation purposes within game development and software engineering for games. The core objective is to gain hands-on experience designing robust 2D mechanics and scalable project structures in Godot Engine 4, including:

- Designing an isolated, typed Finite State Machine (FSM) in GDScript.
- Fine-tuning responsive platformer physics (coyote time, input buffering, variable jump cut, wall-sliding, and locked-angle wall jumps).
- Managing level lifecycles, scene switching, and custom shader wipe transitions via autoload singletons.
- Integrating multi-layered audiovisual feedback (screen shake, procedural sinusoidal text animation, contextual CPU particles, and polyphonic sound management).
- Building reusable, decoupled obstacle and interactive entity components.

---

## System Architecture

The project adheres to the Single Responsibility Principle and loose coupling through Godot signals (Observer Pattern) and autoload singletons.

```text
+-------------------------------------------------------------------------------+
|                           Global Services (Autoloads)                         |
|   SceneManager (Shader Wipe)  |  SoundManager (SFX/BGM)  |  MainCamera (Shake)|
+-------------------------------------------------------------------------------+
                                        ^
                                        | (Direct Access / Signals)
+---------------------------------------+---------------------------------------+
|                         Game Controller (game.gd)                             |
|          Central orchestrator: transitions, HUD binding, and level loading    |
+---------------------------------------+---------------------------------------+
                                        |
                                        v (Instantiated as child)
+-------------------------------------------------------------------------------+
|                          Active Level (level.gd)                              |
|  - TileMapLayers : Collision world, terrain tiles, and parallax backgrounds   |
|  - Checkpoints   : StartPoint (Initial spawn) and ExitFlag (Level complete)   |
|  - Hazards       : Traps (RockHeads, Saws, SpikedBalls, Spikes, Platforms)    |
|  - Collectibles  : Fruit items with floating effects                          |
|  - Player        : CharacterBody2D controlled by hierarchical FSM             |
+-------------------------------------------------------------------------------+
```

---

## Player Finite State Machine (FSM)

Player locomotion and actions are governed by a hierarchical state machine. This structure eliminates invalid state overlapping and centralizes physics, timers, and animation callbacks.

```text
 [Respawn] ---> [Idle] <=======> [Run]
     ^             | \          / |
     |             |  \        /  |
     |             v   v      v   v
     |           [Jump] <======> [Fall]
     |              \            /  ^
     |               v          v   |
     |               [WallSlide] ---+
     |                     |
     +---- [Hurt] <--------+ (Triggered by lethal collision from any active state)
```

| State | Operational Responsibility | Outgoing Transitions |
| :--- | :--- | :--- |
| `Respawn` | Plays the entrance appearance animation upon initial load or death reset. | Transitions to `Idle` once the spawn animation completes. |
| `Idle` | Grounded rest state applying horizontal friction and updating jump buffers. | Moves to `Run` on directional input, `Jump` on keypress, or `Fall` when ungrounded. |
| `Run` | Horizontal locomotion with ground acceleration and footstep dust emission. | Returns to `Idle` when input drops, or transitions to `Jump` / `Fall`. |
| `Jump` | Upward impulse with variable cut-off support and double-jump replenishment tracking. | Transitions to `Fall` upon passing peak velocity, or `WallSlide` on wall contact. |
| `Fall` | Downward descent with amplified gravity, active coyote time, and input buffering. | Transitions to `Idle`/`Run` on landing, `Jump` within coyote window, or `WallSlide`. |
| `WallSlide` | Controlled vertical wall descent speed with localized lateral particle emission. | Exits to `Jump` via wall-jump impulse, or `Fall` when detached from the surface. |
| `Hurt` | One-hit death handling: directional parabolic arc, dizzy sprite freeze, and rotation. | Transitions to `Respawn` once the player falls below the viewport threshold. |

---

## Core Technical Features

### 1. Locomotion and Jump Physics

- **Coyote Time (0.10s)**: Grace window permitting jump execution shortly after running off an edge.
- **Jump Buffering (0.10s)**: Captures early jump inputs before floor contact to prevent dropped commands.
- **Variable Jump Height**: Truncates upward vertical velocity immediately when releasing the jump button early (`JUMP_CUT_MULTIPLIER = 0.5`).
- **Wall Navigation**:
  - Clamped sliding terminal velocity (`WALL_SLIDE_SPEED = 60.0 px/s`).
  - Diagonal wall-jump pushback with temporary horizontal input lock (`WALL_JUMP_LOCK_TIME = 0.15s`) to prevent instant re-sticking.
- **Air Jump Recovery**: Configurable single double-jump allowance restored upon clean floor landing.

### 2. Arcade Death System

- **One-Hit Death**: Direct hazard contact triggers immediate defeat, bypassing hit points for an arcade feel.
- **Kinematic Death Sequence**: Knocks the player backward along a parabolic arc away from the hazard origin, locks the sprite to frame 6 (dizzy expression), applies angular tumble rotation, and restarts the level cleanly once off-screen.

### 3. Audiovisual Polish and Game Feel

- **Contextual Dust Particles (`CPUParticles2D`)**: Separate dust emitters for running footsteps, wall sliding friction, and hard jump landings.
- **Traumatic Screen Shake**: Managed globally via `MainCamera` with decay-damped random offsets.
- **Procedural Waving Text**: Mathematical sine wave modulation calculating individual character vertical offsets for the end-game "WINNER" banner.
- **Custom Shader Screen Wipe**: Matrix grid tile wipe transition powered by `transition.gdshader` and driven by `SceneManager`.

---

## Technical Specifications

| Parameter | Configuration / Value |
| :--- | :--- |
| **Engine** | Godot Engine 4.x |
| **Scripting Language** | GDScript 2.0 (Strict typing) |
| **Render Method** | GL Compatibility / Mobile |
| **Base Viewport Resolution** | 500 x 300 px |
| **Stretch Mode** | Canvas Items (Integer pixel scaling) |
| **Default Texture Filter** | Nearest (Point filtering) |
| **Version Control** | Git / GitHub |

---

## Default Input Mapping

| Action | Primary Key | Alternative Key | Function |
| :--- | :--- | :--- | :--- |
| **Move Left** | `A` | `Left Arrow` | Horizontal leftward movement |
| **Move Right** | `D` | `Right Arrow` | Horizontal rightward movement |
| **Jump / Double Jump** | `Space` | `Up Arrow` | Ground jump, air jump, and wall jump |
| **Restart Level** | `HUD Button` | - | Instant reload of the current level |
| **Level Navigation** | `HUD Buttons` | - | Skip backward or forward in the level sequence |

---

## Repository Structure

<details>
<summary>Click to view project directory tree</summary>

```text
platformer/
├── assets/                     # Graphic and audio source assets
│   ├── Background/             # Repeating parallax background textures
│   ├── Items/                  # Checkpoints, finish flags, and fruit sprites
│   ├── Main Characters/        # Character animation sprite sheets
│   ├── Menu/                   # UI buttons and typography sprite sheets
│   ├── Sounds/                 # SFX audio clips and background music
│   └── Traps/                  # Hazard tiles and obstacle sprite sheets
├── src/
│   ├── frames/                 # Shared SpriteFrames resources
│   ├── resources/
│   │   └── shaders/            # Custom visual shaders (transition.gdshader)
│   ├── scenes/
│   │   ├── autoload/           # Global singletons (SceneManager, SoundManager)
│   │   ├── camera/             # Camera controller and screen shake logic
│   │   ├── collectables/       # Collectible items (Fruit scenes)
│   │   ├── effects/            # Particle scenes and procedural waving text
│   │   ├── exit_flag/          # Level completion goal area
│   │   ├── game/               # Master game orchestrator scene
│   │   ├── hud/                # CanvasLayer user interface overlay
│   │   ├── kill_zone/          # Fall-off kill boundary trigger
│   │   ├── levels/             # Playable levels (Level 01 to Level 05 and Final Level)
│   │   ├── player/             # Player scene, character controller, and states (states/)
│   │   ├── start_point/        # Interactive spawn pad with collision and trigger area
│   │   └── traps/              # Obstacle modules (RockHead, Saw, SpikedBall, Spikes, etc.)
│   ├── scripts/
│   │   └── level/              # Base level template script (level.gd)
│   └── tile_sets/              # TileSet resource with world collision layers (world.tres)
├── icon.svg                    # Project and repository logo
├── project.godot               # Godot Engine master project configuration
└── README.md                   # Project documentation
```

</details>

---

## Core Component Highlights

<details>
<summary>Click to expand implementation notes</summary>

### Autoload Singletons

- **SceneManager (`scene_manager.gd`)**: Coordinates level loading with screen transitions. Controls an overlay `CanvasLayer` backed by `transition.gdshader` to ensure smooth visual wipes between stages while keeping overlays hidden during isolated scene tests.
- **SoundManager (`sound_manager.gd`)**: Centralizes polyphonic SFX playback with subtle random pitch variation to minimize acoustic repetition, along with persistent background music streaming.

### Traps and Level Mechanics

- **RockHead (`rock_head.gd`)**: Linear patrol hazard supporting configurable local coordinate waypoints, directional collision sounds, and camera shakes upon landing impacts.
- **FallingPlatform (`falling_platform.gd`)**: Touch-activated platform that trembles upon player contact, drops after a calibrated delay, and resets itself cleanly.
- **StartPoint (`start_point.gd`)**: Dual-layer architecture combining a `StaticBody2D` solid footing with an `Area2D` activation trigger that plays a dynamic deployment animation, sound effect, and screen shake on first contact.

</details>

---

## Installation and Local Setup

### Prerequisites

- [Godot Engine 4.2+](https://godotengine.org/download) (Standard or .NET build).

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/Javi-CD/godot4-platformer2D.git
   ```

2. Launch Godot Engine.
3. Click **Import** and navigate to the project directory containing `project.godot`.
4. Click **Import & Edit** to open the project in the editor.
5. Press **F5** to run the complete game sequence starting from `res://src/scenes/game/game.tscn`.
6. To test an individual level in isolation, open the target level scene and press **F6**.

---

## Credits and Attributions

- **Art and Visual Assets**: Pixel art tilesets, characters, traps, and UI elements created by Pixel Frog under the [Pixel Adventure 1](https://pixelfrog-assets.itch.io/pixel-adventure-1) asset pack.
- **Audio and Sound Effects**: Public domain and open license retro sound effects curated for dynamic gameplay feedback.
- **Development**: Created as an individual educational initiative to master 2D gameplay architecture and game development practices in Godot Engine.
