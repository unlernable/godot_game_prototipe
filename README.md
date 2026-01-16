# Godot Procedural Level Generator (Split & Fill)

A robust procedural 2D level generator for Godot 4, implementing a **Split and Fill** algorithm to create varied and navigable platformer levels.

## 🎮 Overview

This project demonstrates a recursive space partitioning approach to level design. It splits a large room into smaller sub-regions and applies different "filling strategies" to populate them with platforms, obstacles, and gameplay elements. It is designed to be highly customizable, allowing for rapid prototyping of platformer environments.

## ✨ Key Features

### 🏗 Procedural Generation
*   **Split & Fill Algorithm**: Recursively divides the map into smaller sections (Split) and fills them with content (Fill).
*   **Customizable Strategies**: Includes multiple generation strategies:
    *   **Pyramid**: Creates step-like pyramid structures.
    *   **Grid**: Fills areas with regular grid patterns.
    *   **Jump Pad**: Places traversal mechanics like jump pads.
*   **Smart Connections**: Automatically manages entrances, exits, and paths between regions to ensure levels are completable.

### 🛠 Interactive Tools
*   **Real-time Sidebar Control**: Adjust generation parameters on the fly:
    *   Dimensions (Width/Height) and Grid Step.
    *   Split & Cut Rates (how aggressively space is divided).
    *   Entrance/Exit positioning and direction settings.
    *   Randomization seeds.
    *   Toggle specific strategies (enable/disable Pyramid, Grid, etc.).
*   **Debug Visualization**: Toggle visibility for:
    *   Grid lines.
    *   Spawn regions.
    *   Strategy labels and bounds.
    *   Pathfinding lines/arrows.

### 🏃 Player Controller & Physics
*   **Built-in Player**: Includes a fully playable character to test generated levels immediately.
*   **Physics Tuner**: A dedicated UI panel to tweak player movement values in real-time:
    *   Jump Height/Speed.
    *   Gravity & Fall Speed.
    *   Ground/Air acceleration and friction (Inertia).
    *   Wall interaction and ceiling crash behavior.
*   **Profiles**: Save and load different physics profiles to test how different "feels" work with the generated geometry.

### 🎥 Camera System
*   **Modes**:
    *   **Static**: View the entire generated room scaled to fit the screen.
    *   **Follow**: Standard platformer camera following the player.
*   **Settings**: Adjustable zoom, smoothness, and dead zones.

## 🚀 Getting Started

1.  Clone the repository.
2.  Open the project in **Godot 4**.
3.  Run the `scenes/Main.tscn` scene.
4.  Use the **Sidebar** on the left to configure generation settings and click **Generate**.
5.  Press **O** to open Player Physics settings.
6.  Press **P** to open Camera settings.
7.  Press **U** to open Enemy Physics settings.

## 🧩 Technical Details

*   **Engine**: Godot 4.x
*   **Language**: GDScript
*   **Core Logic**:
    *   `SplitAndFillGenerator.gd`: The heart of the procedural algorithm.
    *   `DirectedRegion`: Represents a space with defined entry and exit points.
    *   `WorldRenderer.gd` & `Renderer.gd`: Handle the visual representation of the abstract map data.

## 🤝 Contributing

This is a prototype project. Feel free to fork, experiment, and submit pull requests!