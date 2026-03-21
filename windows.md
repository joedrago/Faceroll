# Faceroll on Windows

## Prerequisites

Place these in the Faceroll addon root (`Interface/AddOns/Faceroll/`):

- **`ffmpeg.exe`** — grab a recent static build from https://www.gyan.dev/ffmpeg/builds/
- **`wabits.exe`** — either get a prebuilt copy or build it yourself (see below)

## Setup

1. Copy `Settings.example.lua` to `Settings.lua` and adjust keybinds/positioning.
2. Copy `wabits.cfg.example` to `wabits.cfg` and set the `crop=` rectangle (see below).

## Configuring the crop rectangle

The `crop=` value in `wabits.cfg` tells ffmpeg which part of your screen contains the
Faceroll bits panel. The format is `W:H:X:Y`.

To find the right values:

1. Launch WoW and position/size the window how you normally play.
2. Set an initial guess in `wabits.cfg` based on your `bitsPanelX`/`bitsPanelY` in `Settings.lua`.
3. Run `wabits.exe test.png` — this captures a single frame and saves it.
4. Open `test.png` and verify it shows exactly the bits panel (the small grid of black/white squares).
5. Adjust `crop=` and repeat until the capture is correct.

## Running

Double-click `wabits.exe`. It runs as a system tray icon (keyboard icon labeled "Faceroll").
Right-click the tray icon and choose **Exit** to stop it. Only one instance can run at a time.

All output goes to `wabits.log`. To watch it live, run `tail.bat`.

## Building from source

Requires Visual Studio with C++ workload and CMake.

```
build.bat           # debug build
build.bat release   # release build
```

The resulting `wabits.exe` is placed in the addon root.
