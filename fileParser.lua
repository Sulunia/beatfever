--BeatFever fileparser module
--Contains ".osu" file parsing functions
local moduleName = "[FileParser]"
noteCount = 1
local fileLines =  {} --Where we'll hold the current osu file data.
parser = {}
local fileLoaded = nil
local ObjectTypes = {HitCircle = 1, Slider = 2, NewCombo = 4, Spinner = 8}

function parser.loadOsuFile(file)
	fileLoaded = file
	fileLines = {}
	debugLog("Processando arquivo '" .. file .. "'...", 1, moduleName)
	if love.filesystem.isFile(file) then 
		for line in love.filesystem.lines(file) do
			table.insert(fileLines, line)		--Needs to check if the file really exists or not, otherwise, wild crashes may occur.
		end
		--debugLog("Arquivo " .. file .. " carregado", 1, moduleName)
		return true
	else
		debugLog("Falha ao carregar arquivo, saindo", 2, moduleName)
		return false
	end
end


-- Commence insane string splitting funcs

function parser.getAudioFileName()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "AudioFilename:") ~= nil then
				audioFile = string.split(line, ': ')
			end
		end
	end
	--debugLog("AudioFile is: "..audioFile[2], 1, moduleName)
	return audioFile[2]
end

function parser.getPreviewTime()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "PreviewTime:") ~= nil then
				previewTime = string.split(line, ': ');
			end
		end
	end
	--debugLog("Preview time is "..previewTime[2], 1, moduleName)
	return tonumber(previewTime[2]);
end

function parser.getTimingPoints()
	local timingpointstring = {}
	local timingpoint = {}
	local save = false
	
	for key1, line in ipairs(fileLines) do
		if #line > 2 then
			if save then
				table.insert(timingpointstring, line) --inserts a value in a given table
			end
		else
			save = false
		end
		
		if string.find(line, '%[TimingPoints%]') ~= nil then
			save = true
		end
	end -- closes "for" loop
		
	for key2, point in ipairs(timingpointstring) do
		--thankfully this is static! which means it never changes... I hope.
		parameters = string.split(point, ",")
		newpoint = {offset = tonumber(parameters[1]), mpb = tonumber(parameters[2]), meter = tonumber(parameters[3]), sampleType = tonumber(parameters[4]),
		sampleSet = tonumber(parameters[5]), volume = tonumber(parameters[6]), inherited = tonumber(parameters[7]), kiai = tonumber(parameters[8])}
		--Offset, Milliseconds per Beat, Meter, Sample Type, Sample Set, Volume, Inherited, Kiai Mode
		table.insert(timingpoint, newpoint)
	end
	
	debugLog("Parsed timing points for osu file!", 1, moduleName)
	return timingpoint
end

function parser.getSongTitle()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "Title:") ~= nil then
				songName = string.split(line, ':')
			end
		end
	end
	--debugLog("Song name: "..songName[2], 1, moduleName)
	return songName[2]
end

function parser.getSongVersion()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "Version:") ~= nil then
				songVer = string.split(line, ':')
			end
		end
	end
	--debugLog("Song difficulty: "..songName[2], 1, moduleName)
	return songVer[2]
end

function parser.getArtist()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "Artist:") ~= nil then
				artist = string.split(line, ':')
			end
		end
	end
	--debugLog("Artist name: "..artist[2], 1, moduleName)
	return artist[2]
end

function parser.getBMCreator()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "Creator:") ~= nil then
				creator = string.split(line, ':')
			end
		end
	end
	--debugLog("Creator: "..creator[2], 1, moduleName)
	return creator[2]
end

function parser.getSliderMultiplier()
	for key, line in ipairs(fileLines) do
		if #line>0 then
			if string.find(line, "SliderMultiplier:") ~= nil then
				multiplier = string.split(line, ':')
			end
		end
	end
	debugLog("Slider multiplier: "..multiplier[2], 1, moduleName)
	return multiplier[2]
end

function parser.getCurrentLoadedFile()
	debugLog("Currently, the file "..fileLoaded.." is loaded on the parser.", 1, moduleName)
	return fileLoaded
end

function parser.getBreakPeriods()
	debugLog("In function parser.getBreakPeriods()", 3, moduleName)
	debugLog("This function is not working correctly yet! Refer to implementation notes in source.", 3, moduleName)
	--Simples, vou explicar:
	--Você não possui o endTime de um break period na verdade. Você só possui startTimes.
	--O tempo final de um break é determinado pelo proximo hitObject apos o tempo do breakStart.
	--Ou seja, precisamos mexer nessa função!
	
	
	local breakpstring = {}
	local breakpoints = {}
	local save = false
	
	for key1, line in ipairs(fileLines) do
		if string.find(line, "%/%/") == nil then
			if save then
				table.insert(breakpstring, line)
			end
		else
			save = false
		end
		
		if string.find(line, "%/%/Break Periods") ~= nil then
			save = true
		end
	end
	
	for key2, value in ipairs(breakpstring) do
		params = string.split(value, ",")
		breakpoint = {tonumber(params[1]), tonumber(params[2])} --startTime and endTime
		table.insert(breakpoints, breakpoint)
	end
	--debugLog("Loaded song breakpoints!", 1, moduleName)
	return breakpoints
end

function parser.getBGFile()
	local breakpstring = {}
	local breakpoints = {}
	local save = false
	
	for key1, line in ipairs(fileLines) do
		if string.find(line, "%/%/") == nil then
			if save then
				table.insert(breakpstring, line)
			end
		else
			save = false
		end
		
		if string.find(line, "%/%/Background and Video events") ~= nil then
			save = true
		end
	end
	
	for key2, value in ipairs(breakpstring) do
		params = string.split(value, ",")
		for key, value in ipairs(params) do
			if (string.find(value, ".jpg") or string.find(value, ".png") or string.find(value, ".bmp")) ~= nil then
				BG = params[key]
			end
		end
	end
	
	if BG ~= nil then
		BG = BG:gsub('"', "") --GODAMNIT TOOK ME SO LONG TO MAKE THIS WORK I CAN FINALLY SLEEP
		return BG
	else
		debugLog("FAILED TO PARSE BG! Falling back to standard background", 3, moduleName)
		return "error"
	end
end

function parser.getHitObjects()
	local noteList = {}
	local splitLines = {}
	local foundSection = false
	debugLog("In function parser.getHitObjects()", 2, moduleName)
	debugLog("Not all notes are being currently parsed!", 2, moduleName)
	
	for key1, line in ipairs(fileLines) do
		if #line > 0 then
		
			if foundSection then				--Splits file in many lines, read each one	
				table.insert(splitLines, line)	--looking for section, copy everything after section marker.
			end
		
			if string.find(line, "%[HitObjects%]") ~= nil then
				foundSection = true
			end
		end
	end
	
	for key2, line in ipairs(splitLines) do
		if #line > 3 then
			note = parser.parseHitObject(line)
			for i, v in ipairs(note) do
				table.insert(noteList, v)
			end
		end
	end
	return noteList
end

function parser.parseHitObject(str)
	--Local vars for type
	local HitCircle = false
	local Spinner = false
	local Slider = false
	local NewCombo = false
	local note = {}
	local sliderMultiplier = parser.getSliderMultiplier()
	
	local params = string.split(str, ",")
	local x = tonumber(params[1])
	local y = tonumber(params[2])	--Copies common object parameters to vars
	local objTime = tonumber(params[3]) 
	local objType = tonumber(params[4]) 
	
	if (bit.band(objType, 1) > 0) then
		HitCircle = true
	end
	
	if (bit.band(objType, 2) > 0) then
		Slider = true
	end
	
	if (bit.band(objType, 4) > 0) then
		NewCombo = true
	end
	
	if (bit.band(objType, 8) > 0) then 
		Spinner = true
	end
	--At this point, we just effin hope we have no sliding spinners or something
	--Parse notes correctly
	
	if HitCircle then
		--print("Parse hitCircle")
		note[1] = HitObjectCircle(x, y, objTime, objType, 0.5)
	end
	
	if Spinner then		
		--print("Spinner detected. Skipping..")
		note[1] = HitObjectCircle(x, y, objTime, objType, 0.5)
	end
	
	if Slider then
		local curveParams = params[6]
		local curvePoints = string.split(curveParams, "|")
		local pixelLength = params[8]
		local sliderPoints = {}
		objTypeId = "Slider"
		
		print(curvePoints[1])
		
		if curvePoints[1] == "L" or curvePoints[1] == "B" then
			table.insert(sliderPoints, x)
			table.insert(sliderPoints, y)
			
			for i=2, #curvePoints do
				local point = string.split(curvePoints[i], ":")
				local x = tonumber(point[1])
				local y = tonumber(point[2])
				
				table.insert(sliderPoints, x)
				table.insert(sliderPoints, y)
			end
			
			local curve = love.math.newBezierCurve(sliderPoints)
			local pxPerBeat = sliderMultiplier * 100 * 1 --Fixed one for now, should be section current velocity
			--sliderLengthInBeats = (pixelLength * repeatCount) / pxPerBeat
			--local sliderLengthInBeats = pixelLength*1/pxPerBeat
			--sliderEndTime = sliderLengthInBeats * MPB (of current section)
			local mpb = 476.19
			local sliderEndTime = mpb *(pixelLength/sliderMultiplier) / 100
			
			table.insert(note, HitObjectCircle(x, y, objTime, objType, 0.7))
			
			
			--Problema: o for deve ser executado em ticks, que nada mais são do que o valor da MPB dividido por alguma constante, determinei 8
			variavel2 = sliderEndTime/(mpb/6)
			--print(variavel2)
			--Descobrir o valor do passo do for para que ele execute o mesmo arredondado pra baixo o numero de vezes calculado na variavel2
			
			for i = (1/variavel2), 1, (1/variavel2) do
				bx,by = curve:evaluate(i)
				--time + (float(k)/float(numSteps)) * float(sliderEndTime)
				if i + (1/variavel2) > 1 then
					table.insert(note, HitObjectCircle(bx, y, objTime + i*sliderEndTime, objType, 0.8))
				else
					table.insert(note, HitObjectCircle(bx, y, objTime + i*sliderEndTime, objTypeId, 0))
				end
			end
		
		else
			table.insert(note, HitObjectCircle(x, y, objTime, objType, 0.8))
		end
	
	end
	
	return note
end
