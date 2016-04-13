--BeatFever fileparser module
--Contains ".osu" file parsing functions
local moduleName = "[FileParser]"

local fileLines =  {} --Where we'll hold the current osu file data.
parser = {}
local fileLoaded = nil

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
		--offset, mili per beat, meter, sampleType, sampleSet, vol, inherited, kiaitime
		--thankfully this is static! which means it never changes... I hope.
		parameters = string.split(point, ",")
		newpoint = {parameters[1], tonumber(parameters[2]), tonumber(parameters[3]), tonumber(parameters[4]),
		tonumber(parameters[5]), tonumber(parameters[6]), tonumber(parameters[7]), tonumber(parameters[8])}
		table.insert(timingpoint, newpoint)
	end
	
	debugLog("Parsed timing points for osu file!", 1, moduleName)
	return timingpoints
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
			params = string.split(line, ",")
			objPosX = tonumber(params[1])
			objPosY = tonumber(params[2])				--Copies common object parameters to vars
			objTime = tonumber(params[3]) 
			objType = tonumber(params[4]) 
			
			--if (objType == 1) or (objType == 5) then
				note = HitObject(params[1], params[2], params[3], params[4])	--normal hitObject or normal hitobject + newCombo
				table.insert(noteList, note)
			--elseif (objType == 2) or (objType == 6) then
			--	CurveLine = params[5]					--slider hitObject or slider hitObject + newCombo
			--	objRepeat = tonumber(params[6])
			--	pixelLenght = tonumber(params[7]) 		--pixelLenght deve ser calculado de acordo com o tamanho da tela?..
				
				--sliderEndTime = ((1000*60/mPerBeat) * (pixelLenght/1.4) / 100)
			--	debugLog("Partial note type implementation! Object is slider, has been ignored!", 3, moduleName)
			--else
			--	debugLog("Unknown note type! HitObject is type "..objType..", has been ignored!", 3, moduleName)
			--end
		end
	end
	return noteList
end
