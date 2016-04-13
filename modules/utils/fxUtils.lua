--FX lib for use with love2D
--This is used by BeatFever as helper to draw certain effects and keep the main game
--loops as clean as possible.
local moduleName = "[FX Helper]"

local trailListX = {}
local trailListY = {}

function generateMainMenuTrails(amountX, amountY)

debugLog("Generating list of trails with "..amountX.." trails", 1, moduleName)
for t = 1, amountX do
		local side = math.random(100)

		if side > 50 then
			trailListX[t] = {0 - math.random(ScreenSizeW), math.random(ScreenSizeH), math.random(4), math.random(5, 13)}
		else
			trailListX[t] = {ScreenSizeW + math.random(ScreenSizeW), math.random(ScreenSizeH), math.random(4), math.random(5, 13) * - 1}
		end
	end
	
	for t = 1, amountY do
		local side = math.random(100)

		if side > 50 then
			trailListY[t] = {math.random(ScreenSizeW), 0 - math.random(ScreenSizeH), math.random(4), math.random(5, 13)}
		else
			trailListY[t] = {math.random(ScreenSizeW), ScreenSizeH + math.random(ScreenSizeH), math.random(4), math.random(5, 13) * - 1}
		end
	end
debugLog("Done", 1, moduleName)
return trailListX, trailListY
end

function updateMainMenuTrails()
	for t = 1, #trailListX do
			trailListX[t][1] = trailListX[t][1] + trailListX[t][4]

			if trailListX[t][1] > ScreenSizeW + 1480 or trailListX[t][1] < -1400 then
				if trailListX[t][4] > 0 then
					trailListX[t][1] = 0 - math.random(300)
					trailListX[t][2] = math.random(ScreenSizeH)
					trailListX[t][4] = math.random(5, 13)
				else
					trailListX[t][1] = ScreenSizeW + math.random(300)
					trailListX[t][2] = math.random(ScreenSizeH)
					trailListX[t][4] = -1 * math.random(5, 13)
				end
			end
		end

		for t = 1, #trailListY do
			trailListY[t][2] = trailListY[t][2] + trailListY[t][4]

			if trailListY[t][2] > ScreenSizeH + 800 or trailListY[t][2] < -800 then
				if trailListY[t][4] > 0 then
					trailListY[t][1] = math.random(ScreenSizeW)
					trailListY[t][2] = 0 - math.random(ScreenSizeH)
					trailListY[t][4] = math.random(5, 13)
				else
					trailListY[t][1] = math.random(ScreenSizeW)
					trailListY[t][2] = ScreenSizeH + math.random(ScreenSizeH)
					trailListY[t][4] = -1 * math.random(5, 13)
				end
			end
		end
--Does this need a return? I don't know!
end

function drawMainMenuTrails()
for t = 1, #trailListX do
		if trailListX[t][4] > 0 then
			if trailListX[t][3] == 1 then love.graphics.draw(trailred, trailListX[t][1], trailListX[t][2], 0, -1)
			elseif trailListX[t][3] == 2 then love.graphics.draw(trailblue, trailListX[t][1], trailListX[t][2], 0, -1)
			elseif trailListX[t][3] == 3 then love.graphics.draw(trailgreen, trailListX[t][1], trailListX[t][2], 0, -1)
			elseif trailListX[t][3] == 4 then love.graphics.draw(trailyellow, trailListX[t][1], trailListX[t][2], 0, -1) end
		else
			if trailListX[t][3] == 1 then love.graphics.draw(trailred, trailListX[t][1], trailListX[t][2])
			elseif trailListX[t][3] == 2 then love.graphics.draw(trailblue, trailListX[t][1], trailListX[t][2])
			elseif trailListX[t][3] == 3 then love.graphics.draw(trailgreen, trailListX[t][1], trailListX[t][2])
			elseif trailListX[t][3] == 4 then love.graphics.draw(trailyellow, trailListX[t][1], trailListX[t][2]) end
			-- love.graphics.draw(trailred, trailListX[t][1], trailListX[t][2])
		end
	end

	for t = 1, #trailListY do
		if trailListY[t][4] > 0 then
			if trailListY[t][3] == 1 then love.graphics.draw(trailred, trailListY[t][1], trailListY[t][2], math.rad(270))
			elseif trailListY[t][3] == 2 then love.graphics.draw(trailblue, trailListY[t][1], trailListY[t][2], math.rad(270))
			elseif trailListY[t][3] == 3 then love.graphics.draw(trailgreen, trailListY[t][1], trailListY[t][2], math.rad(270))
			elseif trailListY[t][3] == 4 then love.graphics.draw(trailyellow, trailListY[t][1], trailListY[t][2], math.rad(270)) end
		else
			if trailListY[t][3] == 1 then love.graphics.draw(trailred, trailListY[t][1], trailListY[t][2], math.rad(90))
			elseif trailListY[t][3] == 2 then love.graphics.draw(trailblue, trailListY[t][1], trailListY[t][2], math.rad(90))
			elseif trailListY[t][3] == 3 then love.graphics.draw(trailgreen, trailListY[t][1], trailListY[t][2], math.rad(90))
			elseif trailListY[t][3] == 4 then love.graphics.draw(trailyellow, trailListY[t][1], trailListY[t][2], math.rad(90)) end
			-- love.graphics.draw(trailred, trailListX[t][1], trailListX[t][2])
		end
	end

end

function getCurrentSize(image, name, scaleMultiplier, positionModifierX, positionModifierY, draw)
	if scaleMultiplier == nil then
		
	end
	
	if positionModifierX == nil then positionModifierX = 0 end
	if positionModifierY == nil then positionModifierY = 0 end
	
	size = 
	{
		x = (ScreenSizeW/1280)*scaleMultiplier, -- DONE
		y = (ScreenSizeH/720)*scaleMultiplier, --X and Y values of the current size of the picture drawn (scale factor) DONE
	}
	
	boundaries = {
		X1 = (ScreenSizeW / 2) - (image:getWidth() *size.x / 2)-positionModifierX, X2 = (ScreenSizeW / 2) + (image:getWidth()*size.x / 2)-positionModifierX, --100% TESTED
		Y1 = (ScreenSizeH / 2) - (image:getHeight()*size.y / 2)-positionModifierY, Y2 = (ScreenSizeH / 2) + (image:getHeight()*size.y / 2)-positionModifierY,--DONE ASWELL
		identifier = name --so debug knows what's drawing (refer to debugDrawBoundaries)
	}
	
	position = {
		centerX =(((ScreenSizeW / 2) - (image:getWidth() *size.x / 2) + (image:getWidth()*size.x)/2)-positionModifierX), --TESTED 100%
		centerY=(((ScreenSizeH / 2) - (image:getHeight()*size.y / 2) + (image:getHeight()*size.y)/2)-positionModifierY), --TESTED 100%
		x = (image:getWidth() * ScreenSizeW/1280), --UNTESTED
		y = (image:getHeight() * ScreenSizeH/720) --UNTESTED
	}

	if draw then
		love.graphics.draw(image, position.centerX, position.centerY, 0, size.x, size.y, (image:getWidth()/2), (image:getHeight()/2))
		debugDrawObjectBoundaries(boundaries)
	end
	
	return size, position, boundaries
end

function isHovered(boundaries)
	
	local mouseScreenX, mouseScreenY = love.mouse.getPosition()
	if (mouseScreenX > boundaries.X1 and mouseScreenX < boundaries.X2) and (mouseScreenY > boundaries.Y1 and mouseScreenY < boundaries.Y2) then
		return true
	else
		return false
	end

end

function drawFades(bottom, top)
	--Draws top and bottom fade alpha effects
	if bottom then
		love.graphics.draw(lowerScreenAlpha, 0, ScreenSizeH-ScreenSizeH/10, 0, ScreenSizeW/lowerScreenAlpha:getWidth(), (ScreenSizeH/lowerScreenAlpha:getHeight())*0.1)
	end
	if top then
		love.graphics.draw(lowerScreenAlpha, 0, ScreenSizeH/12, 0, ScreenSizeW/lowerScreenAlpha:getWidth(), -(ScreenSizeH/lowerScreenAlpha:getHeight())*0.1)
	end
end

function drawBGParallax(modX, modY, drawTrails)
	love.graphics.push()
		-- Center everything
		love.graphics.translate(modX, modY)
		--Apply effect to BG
		love.graphics.setColor(255, 255, 255, clamp(screenAlpha/1.6, 255, 1))
		love.graphics.draw(background, 0, 0, 0, ScreenSizeW/(background:getWidth()-(background:getWidth()*0.2)), ScreenSizeH/(background:getHeight()-(background:getHeight()*0.2)), background:getWidth()*0.1, background:getHeight()*0.1)
		--Draw main menu trails
		if drawTrails then
			love.graphics.shear(-0.2, 0)
			love.graphics.setColor(255, 255, 255, screenAlpha)
			drawMainMenuTrails()
		end
	love.graphics.pop()

end