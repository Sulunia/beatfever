--Love2d conf file
--DON'T MESS AROUND!

function love.conf(t)
t.console = false
t.window.title = "BeatFever Mania"
--t.window.width = 864
--t.window.height = 486
t.window.width = 1280
t.window.height = 720
t.window.display = 2
t.window.vsync = false
t.window.resizable = true
t.identity = "BeatFever-Songs"
t.window.msaa = 1
end
