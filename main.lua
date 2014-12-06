gamestate = require "lib.hump.gamestate"
sti       = require "lib.sti"
require "resource_loader"
require "game"

g_menu = {}

g_screenres = {
    w=200,h=150
}

function love.load()
    gamestate.registerEvents()
    gamestate.switch(game)
end


function g_menu:keyreleased(key, code)
    if key == 'escape' then
        gamestate.switch(game)
    end
end

