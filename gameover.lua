moduleName = "[GameOverScreen]"

local mouseSens = 0.01 --this var has to be global on main.lua
local rating = "??"
local scoreRecv = nil
local precisionRecv = nil

local backButtonPos = {}
local backButtonSize = {}
local backButtonBoundaries = {}
local backMult = 1
local backX = 0
local sizeBack = 1

function gameOverLoad(score, precision)
	precisionRecv = (round(precision, 4)*100)
	scoreRecv = score
	
	backButton = love.graphics.newImage("img/backbutton.png")
	backButtonSize, backButtonPos, backButtonBoundaries = getCurrentSize(backButton, "Back", 1, 0, 0, false)
	
	--Stupid if's for precision checking
	if precisionRecv == 100 then
		rating = "SS"
	elseif precisionRecv > 98.01 and precisionRecv <= 99.99 then
		rating = "S"
	elseif precisionRecv > 94.01 and precisionRecv <= 98.00 then
		rating = "A"
	elseif precisionRecv > 90.01 and precisionRecv <= 94.00 then
		rating = "B"
	elseif precisionRecv > 85.01 and precisionRecv <= 90.00 then
		rating = "C"
	else
		rating = "D"
	end
	
	
end

function gameOverUpdate(dt)
	screenAlpha = lerp(screenAlpha, 120, 0.03*dt*100)
	
	if isHovered(backButtonBoundaries) then
		sizeBack = lerp(sizeBack, 1.3, 0.12*dt*100)
		if (oldMouseClicked == false and newMouseClicked == true) then
			musicRewind()
			musicPlay()
			backButton = nil
			backButtonSize, backButtonPos, backButtonBoundaries = nil
			--GOD, THESE LINES BELOW STINK SO GODDAMN MUCH
			selectionLoad()
			selectionReset()
			gameReset()
			objectParser.reset()
			Screen = 1
		end
	else
		sizeBack = lerp(sizeBack, 1, 0.12*dt*100)
	end
	
end

function gameOverDraw()
	drawBGParallax(mx * mouseSens, my * mouseSens, false)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(fontRating)
	love.graphics.print(rating, ScreenSizeW*0.14, ScreenSizeH*0.08)
	love.graphics.setFont(ingameFont)
	love.graphics.print("Score: "..scoreRecv, ScreenSizeW*0.15, ScreenSizeH*0.7)
	love.graphics.setFont(fontSelectionSongTitle)
	love.graphics.print("Precision: "..precisionRecv.."%", ScreenSizeW*0.15, ScreenSizeH*0.82)
	love.graphics.print("Song: "..parser.getSongTitle().." ["..parser.getSongVersion().."]", ScreenSizeW*0.15, ScreenSizeH*0.86 )
	drawFades(true, true)
	backButtonSize, backButtonPos, backButtonBoundaries = getCurrentSize(backButton, "Back", sizeBack, -ScreenSizeW/2+ScreenSizeW*0.1, -(ScreenSizeH/2)+ScreenSizeH*0.1, true)
	
end
