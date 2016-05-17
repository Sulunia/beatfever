--fftHelper library
--Wraps around functions for visualization eyecandy
local moduleName = "[Audio manager]"

local songData = nil
local songPlay = nil
local songSize = nil
local songCurrent = nil
local loadedSong = nil
local loadedSongData = false

local lastReportedPlaytime = 0
local previousFrameTime = 0
local songTime = 0

function loadSong(songLoad, loadData)
	debugLog("Loading song at filepath "..songLoad, 1, moduleName)
	loadedSong = songLoad
	loadedSongData = false
	if loadData then 
		songData = love.sound.newSoundData(songLoad)
		debugLog("Information: Sampling rate is "..songData:getSampleRate(), 1, moduleName)
		debugLog("Information: Size is "..songData:getSampleCount().." samples", 1, moduleName)
		loadedSongData = true
	else
		debugLog("No song data loaded.", 1, moduleName)
		songData = nil
	end
	songPlay = love.audio.newSource(songLoad, "stream")
	debugLog("Done!", 1, moduleName)
	songPlay:setVolume(0.75)
end

function loadSongData()
	if not loadedSongData then
		debugLog("Loading song data for currently loaded music")
		songData = love.sound.newSoundData(loadedSong)
		debugLog("Information: Sampling rate is "..songData:getSampleRate(), 1, moduleName)
		debugLog("Information: Size is "..songData:getSampleCount().." samples", 1, moduleName)
		loadedSongData = true
	end
end

function musicVolume(volume)
	songPlay:setVolume(volume)
end

function getCurrentMusic()
	return loadedSong
end

function musicRewind()
	love.audio.rewind(songPlay)
	debugLog("Music has been rewound!", 2, moduleName)
end

function musicPlay()
	debugLog("Song has started playback!", 1, moduleName)
	songPlay:play()
end

function musicSamplingRate()
	if songData ~= nil then
		return songData:getSampleRate()
	else
		return -1
	end
end

function musicRetrieveCurSample()
	return songPlay:tell("samples")
end

function musicRetrieveSize()
	if songData ~= nil then
		return songData:getSampleCount()
	else
		return -1
	end
end

function musicPause()
	debugLog("Pausing current song", 1, moduleName)
	songPlay:pause()
end

function musicSeek(pos)
	if pos > 1 then
		songPlay:seek(pos, "seconds")
	end
end

function generateFFTTable(sizeOfList)
	if songData ~= nil then
		songCurrent = songPlay:tell("samples")
		songSize = songData:getSampleCount()
		local List = {} -- We'll fill this with sample information.
		
			for i = songCurrent, songCurrent + (sizeOfList - 1) do
				if i + 2048 > songSize then i = songSize / 2 end -- Make sure you stop trying to copy stuff when the song is *almost* over, or you'll wind up getting access errors!
				List[#List + 1] = new(songData:getSample(i * 2), 0) -- Copies every sample to the list, which will be fed for the FFT calculation engine. We'll only use the Right channel!
			end
		
		local spectrum = fft(List, false) -- runs your list through the FFT analyzer. Returns a table of complex values, all properly processed for your usage.
		-- An FFT converts audio from a time space to a frequency space, so you can analyze the volume level in each one of it's frequency bands.
		
		devideFFTList(spectrum, 10) -- Multiply all obtained FFT freq infos by 10.
		return spectrum
	else
		return -1
	end
end

function devideFFTList(list, factor)
	for i, v in ipairs(list) do list[i] = list[i] * factor end
	return list
end

function playInterpolated(dt) --Runs the music, but enables interpolated timer reporting. Used ingame as an interpolated timer.
	previousFrameTimer = dt
	lastReportedPlaytime = 0
	songTime = 0
	songPlay:play()
	songPlay:setVolume(0.86)
	songPlay:setPitch(1)
	debugLog("Started interpolated timer playback.", 1, moduleName)
end

function getInterpolatedTimer(dt)
	songTime = songTime + dt - previousFrameTime
	previousFrameTime = dt
	if songPlay:tell("seconds")*1000 ~= lastReportedPlaytime then --Updates music time, but with easing
		songTime = (songTime + (songPlay:tell("seconds")*1000))/2
		lastReportedPlaytime = songPlay:tell("seconds")*1000
	end
	--for more info about this, take a look
	--https://www.reddit.com/r/gamedev/comments/13y26t/how_do_rhythm_games_stay_in_sync_with_the_music/
	return songTime
end