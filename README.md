# Great Firewall Simulator

> **Engine**: Godot 4.6 (GDScript)  
> **Genre**: Cyber-Noir Rhythm Logic Shooter

## Overview

Play as a digital ghost filtering data packets with **subnet masks**. Use bitwise operations to block or pass IP addresses falling from the network stream.

> "Beneath this mask there is more than flesh..."

## Project Structure

- **`great_firewall_simulator/`**: Godot project source
- **`docs/`**: Documentation
    - [`DESIGN_DOC.md`](docs/DESIGN_DOC.md): Game Design Document
    - [`PROJECT_RECORD.md`](docs/PROJECT_RECORD.md): Development history & feature status
- **`marketing/`**: Itch.io assets

## Getting Started

1. Download [Godot 4.6](https://godotengine.org/)
2. Import `great_firewall_simulator/project.godot`
3. Press F5 to run

## Controls

| Key | Action |
|-----|--------|
| Mouse | Move cursor |
| Left Click | Apply mask to IP |
| Q | /8 Mask (255.0.0.0) |
| W | /16 Mask (255.255.0.0) |
| E | /24 Mask (255.255.255.0) |
| R | /32 Mask (255.255.255.255) |
| ESC | Pause |

## License

All Rights Reserved.
