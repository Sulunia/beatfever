local mx = 0
local my = 0
local scaleMultiplier = 1.9

-- Parallax effect intensity
local mouseSens = 0.03
local mouseWheel = 0
screenAlpha = 0
local yMouse = 0

-- Vars
local songVol = 0.82
local lastClickedOption = 1
local fadePos = 0
local gameTransition = false
local xButtonModifier = 0
local buttonAlpha = 0

local backButtonPos = {}
local backButtonSize = {}
local backButtonBoundaries = {}
local backMult = 1
local backX = 0
local selectionDt = 0.16

function selectionLoad()
	
	love.graphics.setBackgroundColor(0, 0, 0, 255)
	songsInstalled = getOsuFiles("")
	listButtons = {}
	
	
	buttonImage = love.graphics.newImage("img/frame_idle.png")
	buttonImageSelected = love.graphics.newImage("img/frame_selected.png")
	backButton = love.graphics.newImage("img/backbutton.png")
	backButtonSize, backButtonPos, backButtonBoundaries = getCurrentSize(backButton, "Back", 1, 0, 0, false)
	
	for i = 1, #songsInstalled do
		listButtons[i] = MenuObject(buttonImage, buttonImageSelected, songsInstalled[i])
		--buttonProperties = getCurrentSize(listButtons[i].image, songsInstalled[i].name, 1, 0, 0, false)
	end
	
	if #songsInstalled > 0 then
		print("Mouse wheel or Up/Down arrow keys to scroll through song list.")
		print("Select a song twice to play it.")
	end
end



function love.wheelmoved(x, y)
	yMouse = yMouse + y*ScreenSizeH*0.06
end



function selectionUpdate(dt)
	--Automagically reloads song selection screen when a song is installed
	selectionDt = dt
	if reloadSelectionScreen then
		selectionDispose()
		selectionLoad()
		debugLog("Reloaded selection screen", 1, moduleName)
		reloadSelectionScreen = false
	end
	
	--Lerps alpha effect used to draw UI items
	if screenAlpha < 253 and (not gameTransition) then
		screenAlpha = lerp(screenAlpha, 255, 0.024)
		buttonAlpha = lerp(buttonAlpha, 255, 0.04)
	end
	
	--Variable updates
	mouseWheel = lerp(mouseWheel, yMouse, 0.18*dt*100)
	mx, my = love.mouse.getPosition()	
	updateMainMenuTrails(dt)	
	xButtonModifier = lerp(xButtonModifier, 22, 0.06*dt*100)
	
	--Updates selection menu button states
	for i = 1, #songsInstalled do								
		if isHovered(listButtons[i].boundaries) then
			listButtons[i].hovered = true
			if(oldMouseClicked == false and newMouseClicked == true) then
				if i ~= lastClickedOption then
					listButtons[lastClickedOption].clicked = false
				end
				gameTransition = listButtons[i]:click() --Returns true if user selected twice
				songVol = 0
				musicVolume(songVol)
				screenAlpha = 70
				background = love.graphics.newImage(listButtons[i].BGFile)
				debugLog("Set new background image!", 1, moduleName)
				lastClickedOption = i
				xButtonModifier = 0
			end
			
		else
			listButtons[i].hovered = false
		end
	end
	
	if isHovered(backButtonBoundaries) then
		backMult = lerp(backMult, 1.1, 0.08*dt*100)
		backX = lerp(backX, 30, 0.2*dt*100)
		if (oldMouseClicked == false and newMouseClicked == true) then
			musicRewind()
			splashLoad()
			loadSongData()
			selectionDispose()
			Screen = 0
		end
	else
		backMult = lerp(backMult, 1, 0.08*dt*100)
		backX = lerp(backX, 0, 0.2*dt*100)
	end
	
	--Smooth volume increase when song is selected
	if songVol < 0.74 and (not gameTransition) then	
		musicVolume(songVol)
		songVol = lerp(songVol, 0.82, 0.005*dt*100)
	end
	
	--Input
	if love.keyboard.isDown("down") then 
		yMouse = yMouse - 0.3*ScreenSizeH*0.06
	end
	
	if love.keyboard.isDown("up") then
		yMouse = yMouse + 0.3*ScreenSizeH*0.06
	end
	--Input end
	
	--User chose a song to play, so...
	if gameTransition then
		screenAlpha = lerp(screenAlpha, 58, 0.019*dt*100)
		fadePos = lerp(fadePos, ScreenSizeW/2, 0.04*dt*100)
		buttonAlpha = lerp(buttonAlpha, 0, 0.02*dt*100)
		if screenAlpha < 62 then
			gameLoad(listButtons[lastClickedOption])
			selectionDispose()
			Screen = 2
			gameTransition = false
			screenAlpha = 60
		end
	end
	
end



function selectionDraw()	
	--Draw BG with parallax effect and trail effect
	if not gameTransition then
		drawBGParallax(mx * mouseSens, my * mouseSens, true)
	else
		drawBGParallax(mx * mouseSens, my * mouseSens, false)
	end
	
	--Draws song selection buttons
	for i = 1, #songsInstalled do
		love.graphics.setColor(255, 255, 255, screenAlpha)
		if listButtons[i].clicked == false then
			listButtons[i]:draw(ScreenSizeW/4+fadePos,(ScreenSizeH/2-(i*(ScreenSizeH*0.18)+mouseWheel)), buttonAlpha, selectionDt)
		else
			listButtons[i]:draw(ScreenSizeW/4+fadePos-xButtonModifier,(ScreenSizeH/2-(i*(ScreenSizeH*0.18)+mouseWheel)), buttonAlpha, selectionDt)
		end
	end
	--Draw top and bottom fade effects
	
	drawFades(true, true) --Should render top, should render bottom
	love.graphics.setColor(255, 255, 255, buttonAlpha)
	backButtonSize, backButtonPos, backButtonBoundaries = getCurrentSize(backButton, "Back", 0.5*backMult, -ScreenSizeW/2+ScreenSizeW*0.04+backX, -(ScreenSizeH/2)+ScreenSizeH*0.1, true)
	
	
	debugDrawMousePos(mx, my)
	
	--Draws message if the player has no songs installed
	if #songsInstalled == 0 then
		love.graphics.setFont(font)
		love.graphics.print("No songs installed!", ScreenSizeW/2-ScreenSizeW*0.11, ScreenSizeH/2*0.8)
		love.graphics.setFont(fontSelectionArtistName)
		love.graphics.print("To install a song, drop a '.osz' file in this window!", ScreenSizeW/2-ScreenSizeW*0.135, ScreenSizeH/2*1 )
	else
		love.graphics.setFont(fontSelectionSongTitle)
		love.graphics.setColor(255, 255, 255, buttonAlpha)
		love.graphics.print("Song selection", ScreenSizeW-ScreenSizeW/8, 0)
	end
	love.graphics.setColor(255, 255, 255, 255)
	
end


function selectionDispose()
	local memoryAmountBefore = collectgarbage("count")
	
	for i = 1, #songsInstalled do 
		listButtons[i] = nil
	end
	songsInstalled = nil
	collectgarbage("collect")
	local memoryAmountAfter = collectgarbage("count")
	debugLog("Disposed of resources! "..round(memoryAmountBefore-memoryAmountAfter, 3).."kB memory freed.", 1, moduleName)
end

function love.filedropped(file)
	--Checks if file is a .osz file
	filePath = file:getFilename()
	if getFileExtension(filePath) == ".osz" and Screen == 1 then
		print("Installing a new .osz file!")
		fileNameFull = filePath:match("([^\\/]-%.?)$") --I could use a single pattern to get everything i wanted..
		fileName = string.match(fileNameFull, "(.+)%.") -- Too bad i find patterns very confusing.. someone might be able to pull this off on one line
		love.timer.sleep(0.01)
		if not love.filesystem.exists(fileName) then
			extractZIP(filePath, fileName, false)
			print("Done!")
			reloadSelectionScreen = true
		else
			print("This song already exists!")
		end
	end
end