-- Debug utilities for Love2d and Beatfever debugging
debugFont = love.graphics.newFont("fonts/bignoodle.ttf", 16)

function debugTimer()
startTime = love.timer.getTime()
return startTime
end

function debugLog(text, level, moduleName)
	newTime = love.timer.getTime()
	debugTime = newTime - startTime
	if (debuggingEnabled) then 
		if level == 1 then
			print(round(debugTime, 2).." \t"..moduleName.." Info: \t" .. text)
		elseif level == 2 then
			print(round(debugTime, 2).." \t"..moduleName.." Warning: \t" .. text)
		end
	end
	
	if level == 3 then
		print(round(debugTime, 2).." \t"..moduleName.." CRITICAL: \t" .. text)
	end
	
end

function debugDrawObjectBoundaries(boundaries)
	if debuggingEnabled then
		if boundaries.identifier ~= "HO" then
			love.graphics.setFont(debugFont)
			love.graphics.setColor(255, 255, 0, 255)
			love.graphics.print(boundaries.identifier, boundaries.X1, boundaries.Y1-15)
			love.graphics.rectangle("fill", boundaries.X1, boundaries.Y1, 10, 10)
			love.graphics.rectangle("fill", boundaries.X2-10, boundaries.Y1, 10, 10)
			love.graphics.rectangle("fill", boundaries.X1, boundaries.Y2-10, 10, 10)
			love.graphics.rectangle("fill", boundaries.X2-10, boundaries.Y2-10, 10, 10)
			love.graphics.line(boundaries.X1,boundaries.Y1, boundaries.X1, boundaries.Y2)
			love.graphics.line(boundaries.X2, boundaries.Y2, boundaries.X1, boundaries.Y2)
			love.graphics.line(boundaries.X2, boundaries.Y2, boundaries.X2, boundaries.Y1)
			love.graphics.line(boundaries.X1, boundaries.Y1, boundaries.X2, boundaries.Y1)
			--love.graphics.rectangle("line", boundaries.X2, boundaries.Y2, 10, 10)
			love.graphics.setFont(font)
			love.graphics.setColor(255, 255, 255, 255)
		end
	end
 end
 
 function debugDrawMousePos(mx, my)
	if debuggingEnabled then
		love.graphics.setFont(debugFont)
		love.graphics.rectangle("fill", mx, my, 4, 4)
		love.graphics.print("X: "..mx.." Y: "..my, mx-28, my-23)
		love.graphics.setFont(font)
	end
 end
