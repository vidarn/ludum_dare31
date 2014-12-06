bump      = require "lib.bump.bump"
anim8     = require "lib.anim8.anim8"
timer     = require "lib.hump.timer"
require "common"
game = {}

game.camera = {
    x = 0.0, y=0.0,
    shake_amplitude = 0.0, shake_frequency = 0.0,
    offset_x = 0.0, offset_y = 0.0,
}


game.shake_time = 0.0

game.tile_size = {
    w=20,h=20,
}

game.alive = {}

game.components = {
    "sprites",
    "pos",
    "direction",
    "players",
    "dynamic",
    "coins",
    "tiles",
}

function create_component_managers()
    for _,component in pairs(game.components) do
        game[component] = {}
    end
end

function kill_entity(id)
    game.alive[id] = false
    for _,component in pairs(game.components) do
        game[component][id] = nil
    end
end

function new_entity()
    for key,val in pairs(game.alive) do
        if(val == false) then
            game.alive[key] = true
            return key
        end
    end
    table.insert(game.alive,true)
    return table.getn(game.alive)
end

function handle_collision(id, other, cols)
    if game.players[id] then
        if game.coins[other] then
            kill_entity(other)
        end
        if game.tiles[other] then
            for _,col in pairs(cols) do
                local tl, tt, nx, ny = col.col:getTouch()
                if ny == -1 and col.dir == 'y' then
                    game.players[id].jump_cooldown = 0.2
                elseif ny == 1 and col.dir == 'y' then
		    game.pos[id].vy = 0
                end
            end
        end
    end
end

function prerun_physics(steps)
    game.prerun = true
    local dt = 0.01
    for step = 1,steps do
        for id,val in pairs(game.dynamic) do 
            if game.alive[id] and val==true then
                update_physics(dt,id)
            end
        end
    end
    game.prerun = false
end

function spawn_from_map(map,layername,hide_layer)
    local layer = map.layers[layername]
    if layer then 
        for x = 1, layer.width do
            for y = 1, layer.height do
                local tile = layer.data[x+(y-1)*layer.width] - 1
                if tile ~= nil then
                    local tileset = nil
                    for _,ts in pairs(map.tilesets) do
                        if(tile < ts.lastgid) then
                            tileset = ts
                            break
                        end
                    end
                    if tile > -1 then
                        local properties = tileset.properties[tile]
                        if properties then
                            local px = x*map.tilewidth
                            local py = y*map.tilewidth
                            for key,val in pairs(properties) do
                                if key == "spawn" then
                                    if val == "coin" then
                                        add_coin(px,py)
                                    end
                                    if val == "player" then
                                        game.pos[game.player].x = px
                                        game.pos[game.player].y = py
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if hide_layer then
            layer.visible = false
        end
    else
        print("Error in spawn_from_map: layer\""..layername.."\" does not exist")
    end
end

function set_sprite(id,name,frames_x,frames_y,speed,direction,tile_w, tile_h, offset_x, offset_y)
    local sprite = load_resource(name,"sprite")
    local grid = anim8.newGrid(tile_w,tile_h,sprite:getWidth(),sprite:getHeight())
    local anim = anim8.newAnimation(grid(frames_x,frames_y),speed)
    if direction==-1 then
        anim:flipH()
    end
    game.sprites[id] = {anim = anim, sprite = sprite, direction=direction, offset_x=offset_x, offset_y=offset_y}
    game.direction[id] = direction
end

function add_player()
    local id = new_entity()
    local x = 100
    local y = 20
    local w = 8
    local h = 12
    local center_x = 0.5
    local center_y = 1.0
    local tile_w = 20
    local tile_h = 20
    local offset_x = (w-tile_w)*center_x
    local offset_y = (h-tile_h)*center_y
    set_sprite(id,"human_regular_hair.png","3-5",2,0.2,1,tile_w,tile_h,offset_x, offset_y)
    game.players[id] = {jump_cooldown = 0}
    game.dynamic[id] = true

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

function add_coin(x,y)
    local id = new_entity()
    local w = 16
    local h = 16
    local center_x = 0.5
    local center_y = 1.0
    local tile_w = 16
    local tile_h = 16
    local offset_x = (w-tile_w)*center_x
    local offset_y = (h-tile_h)*center_y
    set_sprite(id,"puhzil_0.png",2,7,0.2,1,tile_w,tile_h,offset_x,offset_y)
    --game.dynamic[id] = true
    game.coins[id] = true

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

function add_tile(x,y,w,h)
    local id = new_entity()
    game.tiles[id] = "sand"

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end


function game:init()
    create_component_managers()
    game.canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    game.canvas:setFilter('nearest','nearest')
    game.bkg = load_resource("bkg.png","sprite")
    game.world = bump.newWorld(game.tile_size.w)
    game.player = add_player()

    -- load map
    game.map = load_resource("data/levels/test.lua","map")
    for _,layer in pairs(game.map.layers) do
        for _,col in pairs(layer.colliders) do 
            add_tile(col.x,col.y,col.w,col.h)
        end
    end
    spawn_from_map(game.map,"objects",true)

    prerun_physics(100)
end

function game:keyreleased(key, code)
    if key == 'escape' then
        gamestate.switch(g_menu)
    end
    if key == 'f1' then
        debug.debug()
    end
end

function update_player(dt,id)
    local accel = 600.0
    local jump = 400.0
    local damping = -game.pos[id].vx*0.3
    local walk_dir = 0
    if(love.keyboard.isDown('left') or love.keyboard.isDown("a")) then
        game.pos[id].vx = game.pos[id].vx - accel*dt
        game.direction[id] = -1
        walk_dir = -1
    end
    if(love.keyboard.isDown('right') or love.keyboard.isDown("d")) then
        game.pos[id].vx = game.pos[id].vx + accel*dt
        game.direction[id] = 1
        walk_dir = 1
    end
    if(love.keyboard.isDown('up') or love.keyboard.isDown("w")) then
        if(game.players[id].jump_cooldown > 0) then 
            game.pos[id].vy = -jump
        end
    end
    game.players[id].jump_cooldown = game.players[id].jump_cooldown - dt
    if(walk_dir ~= sign(game.pos[id].vx)) then 
        game.pos[id].vx = game.pos[id].vx + damping
    end
    -- DEBUG, temporary allow player to jump even when not on the ground
    --game.players[id].jump_cooldown = 0.1
end

function update_physics(dt,id)
    local max_speed = 200.0
    -- Update physics
    game.pos[id].vy = game.pos[id].vy + 20
    local sx = sign(game.pos[id].vx)
    local sy = sign(game.pos[id].vy)
    game.pos[id].vy = math.min(math.abs(game.pos[id].vy),max_speed)*sy
    game.pos[id].vx = math.min(math.abs(game.pos[id].vx),max_speed)*sx
    local dy = dt*(game.pos[id].vy)
    local dx = dt*(game.pos[id].vx) 
    local new_x = game.pos[id].x + dx
    local new_y = game.pos[id].y + dy
    local x = math.floor(game.pos[id].x/game.tile_size.w)
    -- collisions
    local colliders = {}

    -- check y
    local collisions, len = game.world:check(id, game.pos[id].x, new_y)
    local moved = false -- Make sure we move to the first (closest) intersected tile
    if len >= 1 then
        for _,col in pairs(collisions) do
            local tl, tt, nx, ny = col:getTouch()
            local other = col.other
            if game.tiles[other] then
                if not moved then
                    new_y = tt
                    -- TODO(Vidar) check the normal of the surface
                    --if game.players[id] then
                        --game.players[id].jump_cooldown = 0.2
                    --end
                    moved = true
                end
            end
            if colliders[other] == nil then
                colliders[other] = {}
            end
            table.insert(colliders[other],{col=col, dir='y'})
        end
    end

    -- check x
    collisions, len = game.world:check(id, new_x, new_y)
    moved = false
    if len >= 1 then
        for _,col in pairs(collisions) do
            local tl, tt, nx, ny = col:getTouch()
            local other = col.other
            if game.tiles[other] then
                if not moved then
                    new_x = tl
                    moved = true
                end
            end
            if colliders[other] == nil then
                colliders[other] = {}
            end
            table.insert(colliders[other],{col=col, dir='x'})
        end
    end
    if not game.prerun then
        for other,cols in pairs(colliders) do 
            handle_collision(id,other,cols)
        end
    end
    game.pos[id].x = new_x
    game.pos[id].y = new_y
    game.world:move(id, new_x, new_y)
end

function game:update(dt)
    timer.update(dt)
    for id,sprite in pairs(game.sprites) do 
        if game.alive[id] then
            sprite.anim:update(dt)
        end
    end
    for id,val in pairs(game.dynamic) do 
        if game.alive[id] and val==true then
            update_physics(dt,id)
        end
    end
    update_player(dt,game.player)
    -- Update camera
    local camera_offset = 7
    game.camera.offset_x = game.camera.offset_x + (game.direction[game.player]*camera_offset - game.camera.offset_x)*0.3
    game.camera.x = game.pos[game.player].x + game.camera.offset_x + game.tile_size.w
    game.camera.y = game.pos[game.player].y
    game.camera.x = game.camera.x + game.camera.shake_amplitude*love.math.noise(12345.2 + game.shake_time*game.camera.shake_frequency)
    game.camera.y = game.camera.y + game.camera.shake_amplitude*love.math.noise(31.5232 + game.shake_time*game.camera.shake_frequency)

    game.shake_time = (game.shake_time + dt)%1.0
end

function game:draw()
    love.graphics.setCanvas(game.canvas)

    love.graphics.setBackgroundColor(1,1,1)
    love.graphics.clear()

    love.graphics.push()
    local bkg_parallax = 0.4
    love.graphics.translate(math.floor(-game.camera.x*bkg_parallax), math.floor(-game.camera.y*bkg_parallax))
    love.graphics.draw(game.bkg)
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(math.floor(-game.camera.x + g_screenres.w*0.5), math.floor(-game.camera.y + g_screenres.h*0.5))

    love.graphics.setColor(255,255,255)
    -- draw map
    for _,layer in pairs(game.map.layers) do
        if layer.name ~= "player" and layer.visible ~= false then
            for _,sprite_batch in pairs(layer.sprite_batches) do
                love.graphics.draw(sprite_batch)
            end
        else
            -- draw entities on the correct layer
            -- draw all sprites
            for id,sprite in pairs(game.sprites) do
                if game.alive[id] == true then
                    if game.direction[id] ~= sprite.direction then
                        sprite.direction = game.direction[id]
                        sprite.anim:flipH()
                    end
                    sprite.anim:draw(sprite.sprite,math.floor(game.pos[id].x)+sprite.offset_x,math.floor(game.pos[id].y)+sprite.offset_y)
                end
            end
        end
    end

    -- Draw scaled canvas to screen
    love.graphics.pop()
    love.graphics.setBackgroundColor(0,0,0,0)
    love.graphics.setColor(255,255,255)
    love.graphics.setCanvas()
    love.graphics.clear()
    local h = love.graphics.getHeight()
    local w = love.graphics.getWidth()
    local aspect = g_screenres.w/g_screenres.h
    if aspect < w/h then
        local w = love.graphics.getWidth()
        local quad = love.graphics.newQuad(0,0,h*aspect,h,h*aspect,h)
        love.graphics.draw(game.canvas, quad, (w-h*aspect)*0.5, 0)
    else
        aspect = 1/aspect
        local quad = love.graphics.newQuad(0,0,w,w*aspect,w,w*aspect)
        love.graphics.draw(game.canvas, quad, 0, (h-w*aspect)*0.5)
    end
end

