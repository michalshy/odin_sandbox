package main

import "core:math"
import rl "vendor:raylib"

BACKGROUND_COLOR :: rl.Color{20,20,20,255}

Point :: struct {
    prev_pos: rl.Vector2,
    pos: rl.Vector2,
    init_pos: rl.Vector2,
    pinned: bool,
    selected: bool
}

Stick :: struct {
    p0: ^Point,
    p1: ^Point,
    active: bool
}

Cloth :: struct {
    points: [dynamic]^Point,
    sticks: [dynamic]^Stick
}

load :: proc() {
    rl.InitWindow(1280, 720, "Cloth")
    rl.SetTargetFPS(300)
}

create_cloth :: proc(width, height, spacing, start_x, start_y: int) -> (c: Cloth) {
    for y := 0; y <= height; y += 1 {
        for x := 0; x <= width; x += 1 {
            point := new(Point)
            point.init_pos = { f32(start_x + spacing * x), f32(start_y + spacing * y) }
            point.pos = point.init_pos
            point.prev_pos = point.init_pos
            // point.pinned = y == 0 && (x == 0 || x == width)
            point.pinned = y == 0 
            point.selected = false
            append(&c.points, point)

            if x != 0 {
                stick := new(Stick)
                stick.p0 = c.points[len(c.points) - 2]
                stick.p1 = c.points[len(c.points) - 1]
                stick.active = true
                append(&c.sticks, stick)
            }

            if y != 0 {
                stick := new(Stick)
                stick.p0 = c.points[(y - 1) * (width + 1) + x]
                stick.p1 = c.points[y * (width + 1) + x]
                stick.active = true
                append(&c.sticks, stick)
            }
        }
    }
    return c
}

handle_mouse :: proc(cloth: ^Cloth) {
    @(static) prev_mouse: rl.Vector2

    pos: rl.Vector2 = rl.GetMousePosition()
    delta: rl.Vector2 = pos - prev_mouse
    delta = rl.Vector2Clamp(delta, {0,0}, {100,100})

    for &point in cloth.points {
        dist: f32 = rl.Vector2Distance(pos, point.pos)
        if dist < 10 {
            if rl.IsMouseButtonDown(.LEFT) { 
                point.prev_pos = point.prev_pos + delta
                point.pos = point.pos + delta
            }
            point.selected = true
        } else {
            point.selected = false
        }
    }
}

update :: proc(
    cloth: ^Cloth, 
    delta_time: f32, 
    spacing: int, 
    drag: f32, 
    acceleration: 
    rl.Vector2, 
    iterations: int,
    elasticity: f32,
    stiffness: f32
) {
    for point in cloth.points {
        if point.pinned {
            point.pos = point.init_pos
            continue
        }

        velocity: rl.Vector2 = point.pos - point.prev_pos
        point.prev_pos = point.pos
        point.pos += velocity * (1 - drag) + acceleration * delta_time * delta_time
    }

    factor := 1.0 - math.pow(1.0 - stiffness, 1.0 / f32(iterations))

    for i := 0; i < iterations; i+=1 {
        for stick in cloth.sticks {
            delta: rl.Vector2 = stick.p1.pos - stick.p0.pos
            dist: f32 = rl.Vector2Length(delta)

            if dist > elasticity {
                stick.active = false
            }

            dir: rl.Vector2 = delta / dist
            correction: rl.Vector2 = dir * ((dist - f32(spacing)) * 0.5)
            correction *= factor

            if !stick.p0.pinned && stick.active {
                stick.p0.pos += correction
            }
    
            if !stick.p1.pinned && stick.active  {
                stick.p1.pos -= correction
            }
        }
    }
}

draw :: proc(cloth: ^Cloth, spacing: int, elasticity: f32) {
    for stick in cloth.sticks {
        if stick.active {
            distance := rl.Vector2Distance(stick.p0.pos, stick.p1.pos)
            color := stick.p0.selected || stick.p1.selected ? rl.BLUE : get_color(distance, elasticity, spacing)
            rl.DrawLineV(stick.p0.pos, stick.p1.pos, color)
        }
    }    

    get_color :: proc(distance: f32, elasticity: f32, spacing: int) -> rl.Color {
        if distance <= f32(spacing) {
            return {44, 255, 130, 255}
        } else if distance <= f32(spacing) * 1.33 {
            return {255, 255, 44, 255}
        } else {
            return {255, 130, 44, 255}
        }
    }
}

main :: proc() {
    load()

    SCREEN_WIDTH := rl.GetScreenWidth()
    SCREEN_HEIGHT := rl.GetScreenHeight()
    
    SPACING :: 10
    WIDTH :: 100
    HEIGHT :: 50
    
    cloth := create_cloth(WIDTH, HEIGHT, SPACING, (int(SCREEN_WIDTH) - (WIDTH * SPACING)) / 2, 20)

    defer {
        for &point in cloth.points {
            free(point)
        }
        for &stick in cloth.sticks {
            free(stick)
        }
    }

    ELASTICITY: f32 = 80

    ACCELERATION: rl.Vector2 = { 0, 980 }
    DRAG: f32 = 0.05 
    ITERATIONS :: 3
    STIFFNESS :: 1


    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground({33, 40, 48, 255})
        handle_mouse(&cloth)
        update(&cloth, rl.GetFrameTime(), SPACING, DRAG, ACCELERATION, ITERATIONS, ELASTICITY, STIFFNESS);
        draw(&cloth, SPACING, ELASTICITY)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}