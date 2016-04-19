-- HitObject parsing for BeatfFever
-- This is where all note related calculations will be done
moduleName = "[ObjectParser]"
objectParser = {}

hitcircleGraphic = nil
slidertickGraphic = nil
local fileTimingPoints = nil


function objectParser.setNoteGraphics(c, s)
	-- Receives love textures to be used in notes.
	assert(c, "HitCircle image is nil!")
	assert(s, "Slidertick image is nil!")
	hitcircleGraphic = c
	slidertickGraphic = s
	-- Reset timing points in parser for sliders
	fileTimingPoints = nil
end
	
function objectParser.parseHitCircle(str)
	assert(hitcircleGraphic, "No image loaded!")
	local hitCircleL = {}
	-- Copies common object parameters to vars
	local params = string.split(str, ",")
	local x = tonumber(params[1])
	local y = tonumber(params[2])
	local objTime = tonumber(params[3])
	
	-- Create the hitCircle based on parameters splitted
	hitCircle = HitObject(x, y, objTime, 0.5, hitcircleGraphic)
	table.insert(hitCircleL, hitCircle)
	return hitCircleL
end

function objectParser.parseSlider(str)
	-- Checks if textures have been loaded
	assert(hitcircleGraphic, "No image loaded!")
	assert(slidertickGraphic, "No image loaded!(slider)")
	
	local slider = {}
	-- Copies common object parameters to vars
	local params = string.split(str, ",")
	local x = tonumber(params[1])
	local y = tonumber(params[2])
	local objTime = tonumber(params[3])
	
	-- Gets the other curve parameters
	local curveParams = string.split(params[6], "|") 
	local pixelLength = tonumber(params[8])
	local sliderControlPoints = {}
	local sliderRepeatCount = tonumber(params[7])
	local sliderMultiplier = parser.getSliderMultiplier()
	
	-- Checks if curve is of a given type. Catmull is currently unsupported, so we ignore it.
	if curveParams[1] == "L" or curveParams[1] == "B" or curveParams[1] == "P" then
		-- Gets current slider velocity
		local sliderVelocity = objectParser.getSliderVelocity(objTime)
		-- Gets current slider beat length
		local beatLength = objectParser.getSliderBeatLength(objTime)
		
		-- Generates points to feed them to the bezier curve calculator
		local pointList = objectParser.generateTableForBezier(x, y, curveParams)
		local curve = love.math.newBezierCurve(pointList)
		
		-- Calculates slider properties
		local pxPerBeat = sliderMultiplier * 100 * sliderVelocity
		local sliderLengthBeats = pixelLength * sliderRepeatCount / pxPerBeat
		local sliderSingleSectionDuration = pixelLength / pxPerBeat
		--local sliderDuration = sliderLengthBeats * beatLength
		local sliderDuration = sliderSingleSectionDuration * beatLength
		local sliderEndTime = objTime + sliderDuration
		local repeatGeneration = 1
		
		-- Override
		--sliderRepeatCount = 1
		
		while sliderRepeatCount >= repeatGeneration do
			if repeatGeneration % 2 ~= 0 then --First section of a slider
				-- Put slider beginning point in table
				if repeatGeneration == 1 then
					table.insert(slider, HitObject(x, y, objTime+(sliderDuration*(repeatGeneration-1)), 0.5, hitcircleGraphic))
				end

				-- Put the connecting notes inside the table
				local ticks = sliderDuration/(beatLength/4)
				for i = 0.14, 0.87, 0.1 do
					bx, by = curve:evaluate(i)
					table.insert(slider, HitObject(bx, by, objTime+(i*sliderDuration)+(sliderDuration*(repeatGeneration-1)), 0.1, slidertickGraphic))
				end
			
				-- Put slider ending edge on the slider
				bx, by = curve:evaluate(1)
				table.insert(slider, HitObject(bx, by, objTime+(sliderDuration*repeatGeneration), 0.5, hitcircleGraphic))
			
			else --Second section of a slider
				
				-- Put slider beginning point in table
				bx, by = curve:evaluate(1)
				table.insert(slider, HitObject(bx, by, objTime+(sliderDuration*(repeatGeneration-1)), 0.5, hitcircleGraphic))
				
				-- Put the connecting notes reversed in the table
				local ticks = sliderDuration/(beatLength/4)
				
				for i = 0.87, 0.14, -0.1 do
					bx, by = curve:evaluate(i)
					table.insert(slider, HitObject(bx, by, (objTime+(math.abs(1-i)*sliderDuration))+(sliderDuration*(repeatGeneration-1)), 0.1, slidertickGraphic))
				end
			
				-- Put slider ending edge on the slider
				bx, by = curve:evaluate(0)
				table.insert(slider, HitObject(bx, by, (objTime+sliderDuration*(repeatGeneration)), 0.5, hitcircleGraphic))
			end
			repeatGeneration = repeatGeneration + 1
		end
	end
	assert(slider, "Slider has no value!")
	return slider
end

function objectParser.generateTableForBezier(x, y, parameters)
	-- Returns a table suitable for use with love2d bezier function
	local controlPoints = {}
	
	-- Add initial points
	table.insert(controlPoints, x)
	table.insert(controlPoints, y)
	
	-- Add the rest of the points based on the table parameters received
	for i = 2, #parameters do
		local ctrlPoint = string.split(parameters[i], ":")
		local ptX = tonumber(ctrlPoint[1])
		local ptY = tonumber(ctrlPoint[2])
		
		table.insert(controlPoints, ptX)
		table.insert(controlPoints, ptY)
	end
	-- Table format: (x1, y1, x2, y2..., xn, yn)
	return controlPoints
end

function objectParser.getSliderVelocity(objTime)
	print("-------------Start")
	if fileTimingPoints == nil then
		fileTimingPoints = parser.getTimingPoints()
	end
	
	local index = 1
	
	while objTime > fileTimingPoints[index+1].offset and fileTimingPoints[index+2] ~= nil do
		-- Finds which timing point will be active for the current slider
		index = index + 1
	end
	
	
	print("Object time is "..objTime)
	print("Index of timing point is "..index..", with offset "..fileTimingPoints[index].offset.." and beat length of "..fileTimingPoints[index].mpb)
	
	if index == 1 then
		sliderVelocity = 1
	elseif fileTimingPoints[index].inherited == 1 then
		-- Some beatmaps set BPM and velocity at the same offset time.
		if fileTimingPoints[index + 1].offset == fileTimingPoints[index].offset then
			-- If such thing happens, we get the velocity set imediately after the BPM setup
			index = index + 1
			print("Next timing point defines velocity")
			sliderVelocity = math.abs(100 / fileTimingPoints[index].mpb)
		else
			-- Otherwise we get the last velocity imposed
			if fileTimingPoints[index-1].inherited == 0 then
				index = index - 1
				sliderVelocity = math.abs(100 / fileTimingPoints[index].mpb)
				print("Picked last velocity")
			else
				-- Not sure if this will ever happen, so i'm warning and kickin back velocity to 1
				sliderVelocity = 1
				debugLog("Slider velocity failed to detect closest inherited setup, assuming 1", 3, moduleName)
			end
		end
		
	else
		-- Calculate slider velocity
		sliderVelocity = math.abs(100 / fileTimingPoints[index].mpb)
	end
	
	print("-------------End")
	assert(sliderVelocity, "Slider velocity was not parsed!")
	return sliderVelocity
end

function objectParser.getSliderBeatLength(objTime)
	-- By logic of things, we already have a timing point list loaded here.
	-- If not, call ghostbusters.
	
	local index = 1
	
	if index == 1 then
		detectedMPB = fileTimingPoints[1].mpb
	else
		while objTime > fileTimingPoints[index].offset do
			-- Finds which timing point will be active for the current slider
			if fileTimingPoints[index].mpb > 0 then
				detectedMPB = fileTimingPoints[index].mpb
			end
			index = index + 1
		end
	end
	
	-- print("Object time is "..objTime)
	-- print("Index of timing point is "..index..", with offset "..fileTimingPoints[index].offset.." and beat length of "..fileTimingPoints[index].mpb)
	assert(detectedMPB, "Unable to parse beat length!")
	return detectedMPB
end