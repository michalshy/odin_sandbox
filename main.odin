package main

import "core:fmt"
import rl "vendor:raylib"

BACKGROUND_COLOR :: rl.Color{20,20,20,255}

load :: proc() {
    rl.InitWindow(320, 240, "Demo")
    rl.SetTargetFPS(60)
}

draw :: proc() {
    rl.BeginDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.EndDrawing()
}

main :: proc() {
    load()
    for !rl.WindowShouldClose() {
        draw()
    }
    rl.CloseWindow()
}