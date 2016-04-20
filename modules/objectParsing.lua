-- HitObject parsing for BeatfFever
-- This is where all note related calculations will be done
moduleName = "[ObjectParser]"
objectParser = {}

hitcircleGraphic = nil
slidertickGraphic = nil
local fileTimingPointsInherited = {}
local fileTimingPointsBPM = {}


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
	hitCircle = HitObject(x, y, objTime, 0.5, hitcircleGraphic, 1)
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
		
		while sliderRepeatCount >= repeatGeneration do
			if repeatGeneration % 2 ~= 0 then --First section of a slider
				-- Put slider beginning point in table
				if repeatGeneration == 1 then
					table.insert(slider, HitObject(x, y, objTime+(sliderDuration*(repeatGeneration-1)), 0.5, hitcircleGraphic, 1))
				end

				-- Put the connecting notes inside the table
				local ticks = sliderDuration/(beatLength/4)
				for i = 0.14, 0.87, 0.1 do
					bx, by = curve:evaluate(i)
					table.insert(slider, HitObject(bx, by, objTime+(i*sliderDuration)+(sliderDuration*(repeatGeneration-1)), 0.1, slidertickGraphic, 2))
				end
			
				-- Put slider ending edge on the slider
				bx, by = curve:evaluate(1)
				table.insert(slider, HitObject(bx, by, objTime+(sliderDuration*repeatGeneration), 0.5, hitcircleGraphic, 1))
			
			else --Second section of a slider
				
				-- Put slider beginning point in table
				bx, by = curve:evaluate(1)
				table.insert(slider, HitObject(bx, by, objTime+(sliderDuration*(repeatGeneration-1)), 0.5, hitcircleGraphic, 1))
				
				-- Put the connecting notes reversed in the table
				local ticks = sliderDuration/(beatLength/4)
				
				for i = 0.87, 0.14, -0.1 do
					bx, by = curve:evaluate(i)
					table.insert(slider, HitObject(bx, by, (objTime+(math.abs(1-i)*sliderDuration))+(sliderDuration*(repeatGeneration-1)), 0.1, slidertickGraphic, 2))
				end
			
				-- Put slider ending edge on the slider
				bx, by = curve:evaluate(0)
				table.insert(slider, HitObject(bx, by, (objTime+sliderDuration*(repeatGeneration)), 0.5, hitcircleGraphic, 1))
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
	if fileTimingPointsInherited[1] == nil then
		fileTimingPointsBPM, fileTimingPointsInherited = parser.getFilteredTimingPoints()
	end
	
	
	local index = 1
	if objTime < fileTimingPointsInherited[1].offset then
		sliderVelocity = 1
	else
		while (objTime >= fileTimingPointsInherited[index].offset) and (index < #fileTimingPointsInherited) do
			-- Finds which timing point will be active for the current slider
			if fileTimingPointsInherited[index+1] == nil then
				break 
			elseif objTime < fileTimingPointsInherited[index+1].offset then
				break
			else
				index = index + 1
			end
		end
		sliderVelocity = math.abs(100 / fileTimingPointsInherited[index].mpb)
	end
	--print("ObjTime is "..objTime.." and sliderVelocity is "..sliderVelocity.." calculated at offset "..fileTimingPointsInherited[index].offset.."["..index.."]")
	return sliderVelocity
end

function objectParser.getSliderBeatLength(objTime)
	-- By logic of things, we already have a timing point list loaded here.
	-- If not, call ghostbusters.
	
	local index = 1
	
	if objTime == fileTimingPointsBPM[1].offset then
		index = 1
	else
		while (objTime >= fileTimingPointsBPM[index].offset) and (index < #fileTimingPointsBPM) do
			-- Finds which timing point will be active for the current slider
			if fileTimingPointsBPM[index+1] == nil then
				break 
			elseif objTime < fileTimingPointsBPM[index+1].offset then
				break
			else
				index = index + 1
			end
		end
	end
	-- print("Object time is "..objTime)
	detectedMPB = fileTimingPointsBPM[index].mpb
	--print("Beat length of "..fileTimingPointsBPM[index].mpb)
	assert(detectedMPB, "Unable to parse beat length!")
	return detectedMPB
end