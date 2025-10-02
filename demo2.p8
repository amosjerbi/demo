pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- crystal runner
-- a fast-paced platformer
-- inspired by sonic mechanics

-- game state
game_state = "title" -- title, playing, gameover
frame = 0
cam_x, cam_y = 0, 0

-- player object
player = {
    x = 64,
    y = 64,
    dx = 0,
    dy = 0,
    w = 7,
    h = 7,
    grounded = false,
    facing = 1, -- 1 right, -1 left
    
    -- simplified physics
    acc = 0.5,
    dec = 0.5,
    max_speed = 3,
    jump_power = 5,
    gravity = 0.3,
    friction = 0.2,
    
    -- animation
    sprite = 1,
    anim_timer = 0,
    state = "idle", -- idle, run, jump, fall
    
    -- game stats
    crystals = 0,
    health = 3,
    invuln_timer = 0,
    dash_cooldown = 0,
    can_double_jump = false,
    double_jumped = false,
    
    -- powerup states
    speed_boost = 0,
    shield = false,
    shield_timer = 0,
}

-- level data
level = {
    width = 256,
    height = 16,
}

-- collectibles
crystals = {}
enemies = {}
particles = {}
platforms = {}
springs = {}
checkpoints = {}
powerups = {}

-- game progress
last_checkpoint = {x = 64, y = 64}
level_time = 0
best_time = 999999

-- initialize game
function _init()
    -- setup initial level
    init_level()
    music(0)
end

function init_level()
    -- clear arrays
    crystals = {}
    enemies = {}
    particles = {}
    platforms = {}
    springs = {}
    checkpoints = {}
    powerups = {}
    
    -- reset timer
    level_time = 0
    
    -- create crystals in patterns
    for i = 1, 20 do
        add(crystals, {
            x = 32 + i * 32 + rnd(16),
            y = 32 + rnd(64),
            collected = false,
            timer = rnd(60),
            type = flr(rnd(3)) + 1, -- 1-3 for different colors
        })
    end
    
    -- create crystal formations
    for i = 0, 3 do
        local base_x = 200 + i * 100
        local base_y = 50
        for j = 0, 2 do
            add(crystals, {
                x = base_x + j * 12,
                y = base_y - j * 8,
                collected = false,
                timer = j * 10,
                type = 2,
            })
        end
    end
    
    -- create enemies
    for i = 1, 8 do
        add(enemies, {
            x = 100 + i * 64,
            y = 80,
            dx = 0.5,
            w = 8,
            h = 8,
            type = flr(rnd(2)) + 1,
            health = 1,
            sprite = 16,
        })
    end
    
    -- create flying enemy
    add(enemies, {
        x = 300,
        y = 40,
        dx = 0,
        dy = 0,
        w = 10,
        h = 10,
        type = 3, -- flying type
        health = 2,
        sprite = 20,
        home_y = 40,
        target = nil,
    })
    
    -- create moving platforms
    add(platforms, {
        x = 150,
        y = 90,
        w = 24,
        h = 4,
        dx = 0.5,
        dy = 0,
        x_min = 140,
        x_max = 200,
    })
    
    add(platforms, {
        x = 250,
        y = 70,
        w = 16,
        h = 4,
        dx = 0,
        dy = 0.3,
        y_min = 60,
        y_max = 100,
    })
    
    -- create springs
    add(springs, {
        x = 120,
        y = 104,
        power = 8,
        used = false,
    })
    
    add(springs, {
        x = 320,
        y = 104,
        power = 10,
        used = false,
    })
    
    -- create checkpoints
    add(checkpoints, {
        x = 200,
        y = 80,
        activated = false,
    })
    
    add(checkpoints, {
        x = 400,
        y = 80,
        activated = false,
    })
    
    -- create powerups
    add(powerups, {
        x = 180,
        y = 60,
        type = "speed", -- speed boost
        collected = false,
    })
    
    add(powerups, {
        x = 350,
        y = 50,
        type = "shield", -- temporary shield
        collected = false,
    })
end

-- update game
function _update60()
    frame += 1
    
    if game_state == "title" then
        update_title()
    elseif game_state == "playing" then
        update_game()
    elseif game_state == "gameover" then
        update_gameover()
    end
end

function update_title()
    -- start game on button press
    if btnp(❎) or btnp(🅾️) then
        game_state = "playing"
        reset_player()
        init_level()
    end
end

function update_game()
    -- update timer
    level_time += 1/60
    
    -- update player
    update_player()
    
    -- update camera
    update_camera()
    
    -- update enemies
    update_enemies()
    
    -- update platforms
    update_platforms()
    
    -- update particles
    update_particles()
    
    -- update collectibles
    update_crystals()
    
    -- update springs
    update_springs()
    
    -- update checkpoints
    update_checkpoints()
    
    -- update powerups
    update_powerups()
    
    -- check win condition (reached end of level)
    if player.x > level.width * 8 - 32 then
        if level_time < best_time then
            best_time = level_time
        end
        game_state = "gameover"
        music(-1)
        sfx(7)
    end
    
    -- check game over
    if player.health <= 0 then
        game_state = "gameover"
        music(-1)
        sfx(5)
    end
end

function update_gameover()
    if btnp(❎) or btnp(🅾️) then
        game_state = "title"
        _init()
    end
end

function reset_player()
    player.x = last_checkpoint.x
    player.y = last_checkpoint.y
    player.dx = 0
    player.dy = 0
    player.health = 3
    player.crystals = 0
    player.invuln_timer = 0
    player.double_jumped = false
    player.speed_boost = 0
    player.shield = false
    player.shield_timer = 0
end

function update_player()
    local p = player
    
    -- handle invulnerability
    if p.invuln_timer > 0 then
        p.invuln_timer -= 1
    end
    
    -- handle dash cooldown
    if p.dash_cooldown > 0 then
        p.dash_cooldown -= 1
    end
    
    -- simple horizontal movement
    if btn(⬅️) then
        p.dx = -p.max_speed
        p.facing = -1
    elseif btn(➡️) then
        p.dx = p.max_speed
        p.facing = 1
    else
        -- quick stop
        p.dx *= 0.7
        if abs(p.dx) < 0.1 then
            p.dx = 0
        end
    end
    
    -- simple jumping - just press button to jump
    if (btnp(❎) or btnp(🅾️)) and p.grounded then
        p.dy = -p.jump_power
        p.grounded = false
        p.double_jumped = false
        sfx(0)
        
        -- create jump particles
        for i = 1, 3 do
            create_particle(p.x, p.y + p.h, rnd(2) - 1, -rnd(2), 7)
        end
    end
    
    -- optional double jump (if unlocked)
    if (btnp(❎) or btnp(🅾️)) and not p.grounded and p.can_double_jump and not p.double_jumped then
        p.dy = -p.jump_power * 0.75
        p.double_jumped = true
        sfx(1)
        
        -- create double jump particles
        for i = 1, 5 do
            local angle = i / 5
            create_particle(p.x, p.y, cos(angle) * 2, sin(angle) * 2, 12)
        end
    end
    
    -- simple dash (optional)
    if btn(❌) and p.grounded and p.dash_cooldown == 0 then
        p.dx = p.facing * p.max_speed * 2
        p.dash_cooldown = 30
        sfx(2)
        
        -- create dash particles
        for i = 1, 5 do
            create_particle(p.x - p.facing * 4, p.y + rnd(p.h), -p.facing * rnd(2), 0, 8)
        end
    end
    
    -- apply gravity
    if not p.grounded then
        p.dy += p.gravity
        p.dy = min(p.dy, 8) -- terminal velocity
    else
        p.dy = 0
    end
    
    -- move and check collisions
    move_player()
    
    -- update animation state
    update_player_animation()
    
    -- check enemy collisions
    check_enemy_collision()
    
    -- check crystal collection
    check_crystal_collection()
end

function move_player()
    local p = player
    
    -- horizontal movement
    p.x += p.dx
    
    -- check horizontal collision
    if check_solid(p.x, p.y, p.w, p.h) then
        -- push back
        if p.dx > 0 then
            -- moving right, push left
            while check_solid(p.x, p.y, p.w, p.h) do
                p.x -= 1
            end
        else
            -- moving left, push right
            while check_solid(p.x, p.y, p.w, p.h) do
                p.x += 1
            end
        end
        p.dx = 0
    end
    
    -- vertical movement
    p.y += p.dy
    
    -- check vertical collision
    if check_solid(p.x, p.y, p.w, p.h) then
        if p.dy > 0 then
            -- falling, push up to ground
            while check_solid(p.x, p.y, p.w, p.h) do
                p.y -= 1
            end
            p.grounded = true
            p.dy = 0
            p.double_jumped = false
        else
            -- jumping, push down from ceiling
            while check_solid(p.x, p.y, p.w, p.h) do
                p.y += 1
            end
            p.dy = 0
        end
    else
        -- check if we're standing on ground
        if check_solid(p.x, p.y + 1, p.w, p.h) then
            p.grounded = true
        else
            p.grounded = false
        end
    end
    
    -- simple platform collision
    for plat in all(platforms) do
        -- only check if falling
        if p.dy >= 0 then
            -- check if player overlaps platform
            if p.x + p.w > plat.x and
               p.x < plat.x + plat.w and
               p.y + p.h > plat.y and
               p.y + p.h < plat.y + 8 then
                
                -- land on platform
                p.y = plat.y - p.h
                p.dy = 0
                p.grounded = true
                p.double_jumped = false
                
                -- move with platform
                p.x += plat.dx
            end
        end
    end
    
    -- keep player in bounds
    p.x = mid(4, p.x, level.width * 8 - p.w - 4)
    p.y = max(0, p.y)
    
    -- respawn if fell off
    if p.y > 120 then
        p.x = last_checkpoint.x
        p.y = last_checkpoint.y
        p.dx = 0
        p.dy = 0
        player.health -= 1
        sfx(4)
    end
end

function check_solid(x, y, w, h)
    -- check map collision
    local x1 = flr(x / 8)
    local y1 = flr(y / 8)
    local x2 = flr((x + w - 1) / 8)
    local y2 = flr((y + h - 1) / 8)
    
    for i = x1, x2 do
        for j = y1, y2 do
            if fget(mget(i, j), 0) then
                return true
            end
        end
    end
    
    return false
end

function update_player_animation()
    local p = player
    
    -- determine animation state
    if not p.grounded then
        if p.dy < 0 then
            p.state = "jump"
        else
            p.state = "fall"
        end
    elseif abs(p.dx) > 0.1 then
        p.state = "run"
    else
        p.state = "idle"
    end
    
    -- update animation timer
    p.anim_timer += 1
    
    -- set sprite based on state
    if p.state == "idle" then
        -- blink animation for cuteness
        if p.anim_timer % 120 < 5 then
            p.sprite = 3  -- blinking sprite
        else
            p.sprite = 1  -- normal sprite
        end
    elseif p.state == "run" then
        local frame = flr(p.anim_timer / 6) % 4
        p.sprite = 2 + frame
    elseif p.state == "jump" then
        p.sprite = 6
    elseif p.state == "fall" then
        p.sprite = 7
    end
end

function check_enemy_collision()
    local p = player
    
    if p.invuln_timer > 0 then return end
    
    for e in all(enemies) do
        if abs(p.x + p.w/2 - e.x - e.w/2) < (p.w + e.w)/2 and
           abs(p.y + p.h/2 - e.y - e.h/2) < (p.h + e.h)/2 then
            
            -- check if bouncing on enemy
            if p.dy > 0 and p.y < e.y then
                -- bounce off enemy
                p.dy = -3
                e.health -= 1
                sfx(3)
                
                -- create hit particles
                for i = 1, 10 do
                    create_particle(e.x + e.w/2, e.y, rnd(4) - 2, -rnd(3), 8)
                end
                
                if e.health <= 0 then
                    del(enemies, e)
                    player.crystals += 5
                end
            elseif p.shield then
                -- shield protects player
                p.shield = false
                p.shield_timer = 0
                p.dx = -p.facing * 2
                p.dy = -1
                sfx(3)
                
                -- destroy enemy
                e.health = 0
                del(enemies, e)
                
                -- create shield break particles
                for i = 1, 15 do
                    create_particle(p.x + p.w/2, p.y + p.h/2, rnd(6) - 3, rnd(6) - 3, 12)
                end
            else
                -- take damage
                player.health -= 1
                player.invuln_timer = 60
                p.dx = -p.facing * 3
                p.dy = -2
                sfx(4)
                
                -- create damage particles
                for i = 1, 8 do
                    create_particle(p.x + p.w/2, p.y + p.h/2, rnd(4) - 2, rnd(4) - 2, 8)
                end
            end
        end
    end
end

function check_crystal_collection()
    local p = player
    
    for c in all(crystals) do
        if not c.collected and
           abs(p.x + p.w/2 - c.x) < 12 and
           abs(p.y + p.h/2 - c.y) < 12 then
            c.collected = true
            player.crystals += 1
            sfx(6)
            
            -- special bonus for collecting certain amounts
            if player.crystals % 10 == 0 then
                player.can_double_jump = true
                sfx(7)
                
                -- create bonus particles
                for i = 1, 20 do
                    local angle = i / 20
                    create_particle(c.x, c.y, cos(angle) * 3, sin(angle) * 3, 12)
                end
            else
                -- create collection particles
                for i = 1, 6 do
                    create_particle(c.x, c.y, rnd(2) - 1, -rnd(2) - 1, c.type + 8)
                end
            end
        end
    end
    
    -- remove collected crystals
    for c in all(crystals) do
        if c.collected then
            del(crystals, c)
        end
    end
end

function update_enemies()
    for e in all(enemies) do
        if e.type == 3 then
            -- flying enemy AI
            if abs(player.x - e.x) < 64 then
                e.target = player
            else
                e.target = nil
            end
            
            if e.target then
                -- chase player
                local dx = player.x - e.x
                local dy = player.y - e.y
                e.dx += sgn(dx) * 0.05
                e.dy += sgn(dy) * 0.05
                e.dx = mid(-1.5, e.dx, 1.5)
                e.dy = mid(-1.5, e.dy, 1.5)
            else
                -- return to home position
                e.dy += (e.home_y - e.y) * 0.02
                e.dx *= 0.95
            end
            
            e.x += e.dx
            e.y += e.dy
            e.sprite = 20 + flr(frame / 4) % 2
        else
            -- simple patrol AI
            e.x += e.dx
            
            -- reverse direction at edges
            if check_solid(e.x + (e.dx > 0 and e.w or 0), e.y + e.h + 1, 1, 1) == false or
               check_solid(e.x + (e.dx > 0 and e.w + 1 or -1), e.y, 1, e.h) then
                e.dx = -e.dx
            end
            
            -- animate
            if e.type == 1 then
                e.sprite = 16 + flr(frame / 8) % 2
            else
                e.sprite = 18 + flr(frame / 6) % 2
            end
        end
    end
end

function update_platforms()
    for plat in all(platforms) do
        -- move platform
        if plat.dx != 0 then
            plat.x += plat.dx
            if plat.x <= plat.x_min or plat.x >= plat.x_max then
                plat.dx = -plat.dx
            end
        end
        
        if plat.dy != 0 then
            plat.y += plat.dy
            if plat.y <= plat.y_min or plat.y >= plat.y_max then
                plat.dy = -plat.dy
            end
        end
    end
end

function update_crystals()
    for c in all(crystals) do
        c.timer += 1
    end
end

function update_springs()
    for s in all(springs) do
        -- check if player lands on spring
        if s.used == false and
           abs(player.x + player.w/2 - s.x - 4) < 8 and
           player.y + player.h >= s.y and
           player.y + player.h <= s.y + 4 and
           player.dy >= 0 then
            
            player.dy = -s.power
            player.grounded = false
            s.used = true
            sfx(2)
            
            -- create spring particles
            for i = 1, 10 do
                create_particle(s.x + 4, s.y, rnd(2) - 1, -rnd(4), 11)
            end
        end
        
        -- reset spring
        if s.used then
            s.timer = (s.timer or 0) + 1
            if s.timer > 10 then
                s.used = false
                s.timer = 0
            end
        end
    end
end

function update_checkpoints()
    for cp in all(checkpoints) do
        if not cp.activated and
           abs(player.x - cp.x) < 8 and
           abs(player.y - cp.y) < 16 then
            
            cp.activated = true
            last_checkpoint.x = cp.x
            last_checkpoint.y = cp.y - 16
            sfx(7)
            
            -- create checkpoint particles
            for i = 1, 20 do
                local angle = i / 20
                create_particle(cp.x, cp.y, cos(angle) * 4, sin(angle) * 4, 7)
            end
        end
    end
end

function update_powerups()
    local p = player
    
    -- update powerup timers
    if p.speed_boost > 0 then
        p.speed_boost -= 1
        p.max_speed = 6
        p.acc = 0.5
    else
        p.max_speed = 4
        p.acc = 0.3
    end
    
    if p.shield_timer > 0 then
        p.shield_timer -= 1
        if p.shield_timer == 0 then
            p.shield = false
        end
    end
    
    -- collect powerups
    for pu in all(powerups) do
        if not pu.collected and
           abs(p.x + p.w/2 - pu.x) < 8 and
           abs(p.y + p.h/2 - pu.y) < 8 then
            
            pu.collected = true
            
            if pu.type == "speed" then
                p.speed_boost = 300 -- 5 seconds
                sfx(6)
                
                -- speed particles
                for i = 1, 15 do
                    create_particle(pu.x, pu.y, rnd(6) - 3, rnd(6) - 3, 8)
                end
            elseif pu.type == "shield" then
                p.shield = true
                p.shield_timer = 600 -- 10 seconds
                sfx(6)
                
                -- shield particles
                for i = 1, 15 do
                    create_particle(pu.x, pu.y, rnd(4) - 2, rnd(4) - 2, 12)
                end
            end
            
            del(powerups, pu)
        end
    end
end

function update_particles()
    for p in all(particles) do
        p.x += p.dx
        p.y += p.dy
        p.dy += 0.1 -- gravity
        p.life -= 1
        
        if p.life <= 0 then
            del(particles, p)
        end
    end
end

function create_particle(x, y, dx, dy, col)
    add(particles, {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        color = col,
        life = 20 + rnd(10),
    })
end

function update_camera()
    -- smooth camera follow
    local target_x = player.x - 64
    local target_y = player.y - 64
    
    cam_x += (target_x - cam_x) * 0.1
    cam_y += (target_y - cam_y) * 0.1
    
    -- clamp camera
    cam_x = mid(0, cam_x, level.width * 8 - 128)
    cam_y = mid(0, cam_y, level.height * 8 - 128)
end

-- draw game
function _draw()
    cls(1)
    
    if game_state == "title" then
        draw_title()
    elseif game_state == "playing" then
        draw_game()
    elseif game_state == "gameover" then
        draw_gameover()
    end
end

function draw_title()
    -- vibrant animated background
    for i = 0, 15 do
        for j = 0, 15 do
            local col = ({12, 13, 1, 2})[((i + j + flr(frame / 20)) % 4) + 1]
            rectfill(i * 8, j * 8, i * 8 + 7, j * 8 + 7, col)
        end
    end
    
    -- title text with outline
    outline_text("SPEED RUNNER", 35, 10)
    outline_text("gotta go fast!", 48, 7)
    
    -- flashing prompt
    if frame % 40 < 25 then
        outline_text("press x or c to start", 80, 11)
    end
    
    -- draw rotating rings
    for i = 1, 6 do
        local x = 10 + i * 20
        local y = 100 + sin(frame / 40 + i * 0.3) * 8
        spr(32 + (frame / 4 + i) % 4, x, y)
    end
end

function outline_text(text, y, col)
    local x = 64 - #text * 2
    for i = -1, 1 do
        for j = -1, 1 do
            print(text, x + i, y + j, 0)
        end
    end
    print(text, x, y, col)
end

function draw_game()
    -- set camera
    camera(cam_x, cam_y)
    
    -- draw vibrant sky gradient
    for i = 0, 127 do
        local col = 12  -- light blue
        if i > 40 then col = 13 end  -- darker blue
        if i > 80 then col = 1 end   -- dark blue
        rectfill(0, i, level.width * 8, i, col)
    end
    
    -- draw background
    draw_background()
    
    -- draw level with checkerboard pattern
    for i = 0, level.width - 1 do
        for j = 0, level.height - 1 do
            local tile = mget(i, j)
            if tile > 0 then
                if tile == 1 then
                    -- checkerboard pattern for borders
                    local pattern = (i + j) % 2 == 0
                    spr(pattern and 1 or 2, i * 8, j * 8)
                else
                    spr(tile, i * 8, j * 8)
                end
            end
        end
    end
    
    -- draw platforms with orange-brown colors
    for plat in all(platforms) do
        rectfill(plat.x, plat.y, plat.x + plat.w - 1, plat.y + plat.h - 1, 9)
        rect(plat.x, plat.y, plat.x + plat.w - 1, plat.y + plat.h - 1, 4)
    end
    
    -- draw springs
    for s in all(springs) do
        local offset = s.used and 2 or 0
        spr(36, s.x, s.y + offset)
    end
    
    -- draw checkpoints
    for cp in all(checkpoints) do
        if cp.activated then
            spr(38, cp.x - 4, cp.y - 8)
            -- glow effect
            if frame % 20 < 10 then
                circfill(cp.x, cp.y, 2, 7)
            end
        else
            spr(37, cp.x - 4, cp.y - 8)
        end
    end
    
    -- draw powerups
    for pu in all(powerups) do
        if not pu.collected then
            local bob = sin(frame / 20) * 2
            if pu.type == "speed" then
                spr(39, pu.x - 4, pu.y - 4 + bob)
            elseif pu.type == "shield" then
                spr(40, pu.x - 4, pu.y - 4 + bob)
            end
        end
    end
    
    -- draw crystals
    for c in all(crystals) do
        if not c.collected then
            draw_crystal(c.x, c.y + sin(c.timer / 30) * 2, c.type)
        end
    end
    
    -- draw enemies
    for e in all(enemies) do
        spr(e.sprite, e.x, e.y, 1, 1, e.dx < 0)
    end
    
    -- draw particles
    for p in all(particles) do
        local size = p.life / 10
        circfill(p.x, p.y, size, p.color)
    end
    
    -- draw player
    draw_player()
    
    -- reset camera for UI
    camera(0, 0)
    
    -- draw UI
    draw_ui()
end

function draw_background()
    -- moving clouds
    for i = 0, 8 do
        local x = i * 32 - (cam_x * 0.2 + frame * 0.5) % 256
        local y = 20 + sin(i * 0.2) * 5
        circfill(x, y, 8, 7)
        circfill(x + 6, y, 7, 7)
        circfill(x - 5, y + 2, 6, 7)
    end
    
    -- loop-de-loops in background
    for i = 0, 4 do
        local x = i * 64 - (cam_x * 0.4) % 256
        local y = 60
        circ(x, y, 20, 5)
        circ(x, y, 19, 5)
        circ(x, y, 18, 6)
    end
    
    -- speed lines
    if abs(player.dx) > 2 then
        for i = 1, 5 do
            local x = player.x - player.facing * (10 + i * 5) - cam_x * 0.8
            local y = player.y + rnd(8) - 4
            line(x, y, x - player.facing * 10, y, 7)
        end
    end
end

function draw_player()
    local p = player
    
    -- draw shadow
    if not p.grounded then
        local shadow_y = p.y + p.h
        -- find ground below
        for i = 1, 64 do
            if check_solid(p.x, p.y + p.h + i, p.w, 1) then
                shadow_y = p.y + p.h + i
                break
            end
        end
        
        local shadow_size = 1 + min(3, (shadow_y - p.y - p.h) / 16)
        ovalfill(p.x + p.w/2 - shadow_size, shadow_y - 1, 
                 p.x + p.w/2 + shadow_size, shadow_y, 1)
    end
    
    -- draw shield
    if p.shield then
        local shield_col = 12
        if p.shield_timer < 60 and frame % 4 < 2 then
            shield_col = 7
        end
        circ(p.x + p.w/2, p.y + p.h/2, 10 + sin(frame / 10), shield_col)
    end
    
    -- flashing when invulnerable
    if p.invuln_timer > 0 and p.invuln_timer % 4 < 2 then
        return
    end
    
    -- draw player sprite (centered for cute character)
    spr(p.sprite, p.x, p.y, 1, 1, p.facing == -1)
    
    -- draw dash effect
    if p.dash_cooldown > 20 then
        spr(8, p.x - p.facing * 8, p.y, 1, 1, p.facing == -1)
    end
    
    -- draw speed effect
    if p.speed_boost > 0 and frame % 3 == 0 then
        create_particle(p.x - p.facing * 4, p.y + p.h/2, -p.facing * 2, 0, 8)
    end
end

function draw_crystal(x, y, type)
    -- draw like sonic rings
    local spin = frame / 8 % 8
    if spin < 2 then
        -- front view
        circ(x, y, 3, 10)
        circ(x, y, 2, 9)
    elseif spin < 4 then
        -- turning
        rectfill(x - 1, y - 3, x + 1, y + 3, 10)
        rectfill(x, y - 2, x, y + 2, 9)
    elseif spin < 6 then
        -- side view
        line(x, y - 3, x, y + 3, 10)
    else
        -- turning back
        rectfill(x - 1, y - 3, x + 1, y + 3, 10)
        rectfill(x, y - 2, x, y + 2, 9)
    end
end

function draw_ui()
    -- health
    for i = 1, 3 do
        if i <= player.health then
            spr(32, 4 + i * 9, 4)
        else
            spr(33, 4 + i * 9, 4)
        end
    end
    
    -- crystal counter
    spr(34, 4, 14)
    print("x" .. player.crystals, 14, 15, 7)
    
    -- timer
    local minutes = flr(level_time / 60)
    local seconds = flr(level_time % 60)
    local ms = flr((level_time % 1) * 100)
    local time_str = minutes .. ":" .. (seconds < 10 and "0" or "") .. seconds .. "." .. (ms < 10 and "0" or "") .. ms
    print(time_str, 80, 4, 7)
    
    -- double jump indicator
    if player.can_double_jump then
        spr(35, 108, 14)
        if not player.double_jumped then
            print("jump", 100, 22, 11)
        end
    end
    
    -- speed boost indicator
    if player.speed_boost > 0 then
        local flash = player.speed_boost < 60 and frame % 4 < 2
        print("speed!", 54, 14, flash and 7 or 8)
    end
    
    -- shield indicator
    if player.shield then
        local flash = player.shield_timer < 60 and frame % 4 < 2
        print("shield", 54, 22, flash and 7 or 12)
    end
    
    -- dash cooldown
    if player.dash_cooldown > 0 then
        local bar_width = player.dash_cooldown / 30 * 20
        rectfill(54, 4, 54 + bar_width, 6, 8)
        rect(54, 4, 74, 6, 2)
    end
end

function draw_gameover()
    draw_game() -- draw game in background
    
    -- darken screen
    fillp(0b1010010110100101)
    rectfill(0, 0, 127, 127, 0)
    fillp()
    
    -- check if won
    local won = player.x > level.width * 8 - 32
    
    if won then
        -- victory screen
        print_centered("level complete!", 40, 11)
        print_centered("time: " .. format_time(level_time), 50, 7)
        if level_time == best_time then
            print_centered("new best time!", 58, 10)
        end
        print_centered("crystals: " .. player.crystals, 68, 12)
    else
        -- game over text
        print_centered("game over", 50, 8)
        print_centered("crystals: " .. player.crystals, 60, 7)
    end
    
    if frame % 60 < 40 then
        print_centered("press x or c to retry", 80, 7)
    end
end

function format_time(t)
    local minutes = flr(t / 60)
    local seconds = flr(t % 60)
    local ms = flr((t % 1) * 100)
    return minutes .. ":" .. (seconds < 10 and "0" or "") .. seconds .. "." .. (ms < 10 and "0" or "") .. ms
end

function print_centered(text, y, col)
    local x = 64 - #text * 2
    print(text, x, y, col)
end

__gfx__
00000000000cc000000cc000000cc000000cc000000cc000000cc000000cc000000cc0000000000000000000000000000000000000000000000000000000000000
000000000cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00000000000000000000000000000000000000000000000000000000000
007007000cc11cc00cc11cc00cc11cc00cc11cc00cc11cc00cc11cc00cc11cc00cc11cc00000000000000000000000000000000000000000000000000000000000
00077000cc1001cccc1001cccc0110cccc1001cccc0110cccc1001cccc0110cccc1001cc0000000000000000000000000000000000000000000000000000000000
00077000cc0770cccc0770cccc0770cccc0770cccc0770cccc0770cccc0770cccc0770cc0000000000000000000000000000000000000000000000000000000000
007007000cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00000000000000000000000000000000000000000000000000000000000
0000000000cccc0000cccc0000cccc0000cccc0000cccc0000cccc0000cccc0000cccc000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000888800008888000088880000888800008888000088880000000000000000000000000000000000000000000000000000000000
99999999494949499999999944444444ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999944444444ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99444499949949949944449944ffff44ff4444ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94444449999999999999999944444444ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94444449999999999999999944444444ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99444499949949949944449944ffff44ff4444ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999944444444ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999494949499999999944444444ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800008888000088880000888800008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08e22e8008e22e8008e22e8008e22e8008e22e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e2002e88e2cc2e88e0220e88e2cc2e88e0220e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e2cc2e88e2002e88e2cc2e88e2002e88e2cc2e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e2002e88e2cc2e88e2002e88e2cc2e88e2002e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08e22e8008e22e8008e22e8008e22e8008e22e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800008888000088880000888800008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000880000008800000088000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088880000aaaa000099990000cccc0000eeee00005555000055005500bbbb00007777000077700000888000088800000000000000000000000000000000000
088888800aaaaaa00999999009cccc900eeeee005588885555888855bbbbbb007777770077777700888888008888880000000000000000000000000000000000
8880088888aaaa889999999099cccc9099eeee9058888885588888858bbbbbb877777777777777788888888888888888000000000000000000000000000000
880000888aa00aa899999999cc0000cc9e0000e058888885588888858bbbbbb877777777777777788888888888888888000000000000000000000000000000
8880088888aaaa88999999999cccccc9ee0ee0e058888885588888858bbbbbb877777777777777788888888888888888000000000000000000000000000000
088888800aaaaaa00999999009cccc900eeeee005588885555888855bbbbbb007777770077777700888888008888880000000000000000000000000000000000
0088880000aaaa000099990000cccc0000eeee00005555000055005500bbbb00007777000077700000888000088800000000000000000000000000000000000
00000000000aa00000099000000cc000000ee0000005500000550000000bb0000007700000770000008800000880000000000000000000000000000000000000
__gff__
0001010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000202020200000000000000000000000000000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000202020202000000000000000000000000000000000000000202020202020000000000000000000000000000000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0101010101010000000000000000000000000000000101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
__sfx__
000200001d0501b0501905017050150501305011050100500e0500c0500a05008050060500405002050000500000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000290502b0502d0502f050310503305035050370503905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f0501f050
000200002405024050240502405024050240502405024050240502405024050240502405024050240502405024050240502405024050240502405024050240502405024050240502405024050240502405024050
000400000c0500f05013050180501d050230502905030050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c050
000200002c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c0502c050
000400003505035050350503505035050350503505035050350503505035050350503505035050350503505035050350503505035050350503505035050350503505035050350503505035050350503505035050
__music__
01 41084344
00 01084344
00 02084344
00 03084344
00 04084344
00 05084344
00 06084344
02 07084344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
