require("modules/externals/luafft") 	-- we need to add this to the game folder
require("audioManager")					-- Game modules
require("modules/utils/miscUtils")
require("modules/utils/fxUtils")
require("modules/utils/debugUtils")
require("splash")
require("selection")
require("gameover")
require("fileParser")
class = require("modules/externals/30log") -- Object Orientation library, needed for some stuff
require("modules/gameObjects") 		 -- Now we create the objects we need in order to get stuff working
--require("modules/externals/lovedebug")
require("game")
require("modules/externals/extractor")
bit = require("bit")

reloadSelectionScreen = false

-- Enables debugging in the game section, can be enabled by lovedebug console
debuggingEnabled = false


-- Module name for debug infos
local moduleName = "[MainThread]"

-- Debug infos
debugTimer()
debugLog("BeatFever Mania Debugger, v0.8 =-=-=-=", 1, moduleName)

-- gets screen dimensions.
ScreenSizeW = love.graphics.getWidth()
ScreenSizeH = love.graphics.getHeight() 
ScreenSizeHOld = ScreenSizeH
ScreenSizeWOld = ScreenSizeW
debugLog("Initial screen res is: " .. ScreenSizeW .. "x" .. ScreenSizeH, 1, moduleName)

-- Current screen to render
Screen = 0
Count = 0

-- Font
font = love.graphics.newFont("fonts/bignoodle.ttf", ScreenSizeH / 16)
fontSelectionSongTitle = love.graphics.newFont("fonts/bignoodle.ttf", ScreenSizeH / 25)
fontSelectionArtistName = love.graphics.newFont("fonts/bignoodle.ttf", ScreenSizeH / 32)
ingameFont = love.graphics.newFont("fonts/bignoodle.ttf", ScreenSizeH / 8)

-- Window settings
--Window = love.window.setMode(1280, 720, {resizable = true, vsync = false})

-- Vars for mouse control
oldMouseClicked = nil
newMouseClicked = nil
mouseTrail = 10

function love.load()
	mx, my = love.mouse.getPosition()
	mouseScreenX, mouseScreenY = mx, my
	
	min_dt = 1/120
    next_time = love.timer.getTime()
	love.mouse.setVisible(false)
	--Creates mouse cursor
	mouseCursor = love.graphics.newImage("img/lecursor.png")
	mouseList = {}
	
	lowerScreenAlpha = love.graphics.newImage("img/gradient.png")
	
	
	splashLoad()
end

function love.update(dt)
    --MouseTrail
	mx, my = love.mouse.getPosition()
	mouseScreenX, mouseScreenY = mx, my
	mouseInfo = {X = mouseScreenX, Y = mouseScreenY}
	
	table.insert(mouseList, mouseInfo)
	
	if #mouseList > mouseTrail then
		table.remove(mouseList, 1)
	end
	
	-- Make sure mouse clicks only once
	oldMouseClicked = newMouseClicked
	newMouseClicked = love.mouse.isDown(1)
	
	--FPS at 120 on menus, 200 ingame
	if Screen == 2 then
		min_dt = 1/200
	else
		min_dt = 1/120
	end
	
	next_time = next_time + min_dt
	
	-- Update screen sizes only on some frames
	if Count % 5 == 0 then
		ScreenSizeW = love.graphics.getWidth() -- gets screen dimensions.
		ScreenSizeH = love.graphics.getHeight() -- gets screen dimensions.
	end
	
	-- If size changed, update accordingly
	if ScreenSizeWOld ~= ScreenSizeW or ScreenSizeH ~= ScreenSizeHOld then
		ScreenSizeHOld = ScreenSizeH
		ScreenSizeWOld = ScreenSizeW
		debugLog("Screen size changed! Redefining certain assets...", 2, moduleName)
		font = love.graphics.newFont("fonts/bignoodle.ttf", clamp(ScreenSizeH / 16, ScreenSizeH, 1))
		fontSelectionSongTitle = love.graphics.newFont("fonts/bignoodle.ttf", clamp(ScreenSizeH / 25, ScreenSizeH, 1))
		fontSelectionArtistName = love.graphics.newFont("fonts/bignoodle.ttf", clamp(ScreenSizeH / 32, ScreenSizeH, 1))
		ingameFont = love.graphics.newFont("fonts/bignoodle.ttf", ScreenSizeH / 8)
	end
	
	-- Update FPS only on some frames
	if Count % 120 == 0 then
		local stats = love.graphics.getStats()
		memUsage = stats.texturememory + round(collectgarbage("count"), 2)
		love.window.setTitle("BeatFever Mania -- "..love.timer.getFPS().." FPS || Game Memory: "..round(memUsage/1024, 2).."kb")
	end
	
	-- Screen switcharoo magic
	if Screen == 0 then
		splashUpdate(dt)
	elseif Screen == 1 then 
		selectionUpdate(dt)
	elseif Screen == 2 then
		gameUpdate(dt)
	end
	

end

function love.draw()
	-- Screen switcharoo magic
	if Screen == 0 then
		splashDraw()
	elseif Screen == 1 then
		selectionDraw()
	elseif Screen == 2 then
		gameDraw()
	end
	Count = Count + 1
	
	if Screen == 2 then
		love.graphics.setColor(255, 255, 255, 23)
	end
	love.graphics.draw(mouseCursor, mouseScreenX, mouseScreenY, 0,(ScreenSizeW/1280)*1.6,(ScreenSizeH/720)*1.6, mouseCursor:getWidth()/2, mouseCursor:getHeight()/2)
	for i = 1, #mouseList do
		love.graphics.setColor(255, 255, 255, (124/#mouseList*1.5)*i)
		if (i > 1) and (mouseList[i].X == mouseList[i - 1].X and mouseList[i].Y == mouseList[i-1].Y) == false then
			love.graphics.draw(mouseCursor, mouseList[i].X, mouseList[i].Y, 0,(ScreenSizeW/1280)*1.6,(ScreenSizeH/720)*1.6, mouseCursor:getWidth()/2, mouseCursor:getHeight()/2)  
		end
	end
	
	-- 120fps cap
	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
      next_time = cur_time
      return
	end
	love.timer.sleep(next_time - cur_time)
end

-- TODO list
-- Arrumar barras do FFT e trails atualizando mais lentamente se framerate/update rate diminuir
