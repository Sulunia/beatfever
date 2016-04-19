--gameObjects module for BeatFever
--This is where we create object classes, so we can use then around the game.
--Powered by "30log", an OO Lib for lua

moduleName = "[GameObjects]"

MenuObject = class("MenuObject")
Song = class("Song")
HitObject = class("HitObject")


function MenuObject:init(imageIdle, imageSelected, song) --Constructor
	self.imageIdle = imageIdle
	self.name = song.songTitle
	self.imageSelected = imageSelected
	self.size = {}
	self.position = {}
	self.boundaries = {}
	self.hovered = false
	self.scale = 1
	self.audioFile = song.audioFile
	self.previewTime = song.previewTime
	self.size, self.position, self.boundaries = getCurrentSize(self.imageIdle, self.name, 1, xMod, yMod, false)
	self.artist = song.songArtist
	self.difficulty = song.version
	self.BGFile = song.BGFilePath
	self.clicked = false
	self.filePath = song.fullPath
	self.beatmapCreator = song.beatmapCreator
end

function MenuObject:draw(xMod, yMod, alpha)
	if self.clicked then
		love.graphics.setColor(124, 255, 124, alpha)
		self.size, self.position, self.boundaries = getCurrentSize(self.imageSelected, self.name, self.scale, xMod, yMod, true)
	else
		love.graphics.setColor(255, 255, 255, alpha)
		self.size, self.position, self.boundaries = getCurrentSize(self.imageIdle, self.name, self.scale, xMod, yMod, true)
	end
	if self.hovered then
		self.scale = lerp(self.scale, 0.86, 0.09)
	else
		self.scale = lerp(self.scale, 0.80, 0.09)
	end
	love.graphics.setColor(255, 255, 255, alpha)
	love.graphics.setFont(fontSelectionSongTitle)
	love.graphics.printf(self.name.." ["..self.difficulty.."]", self.boundaries.X1+ScreenSizeW*0.02, self.boundaries.Y1+ScreenSizeH*0.034, (self.boundaries.X2 - self.boundaries.X1), "left")
	love.graphics.setFont(fontSelectionArtistName)
	love.graphics.printf(self.artist.." // "..self.beatmapCreator, self.boundaries.X1+ScreenSizeW*0.02, self.boundaries.Y2-(ScreenSizeH*0.07), (self.boundaries.X2 - self.boundaries.X1), "left")
end

function MenuObject:click(boundaries)
	gameTransition = false
	if self.clicked == false then
		self.clicked = true
		if getCurrentMusic() ~= self.audioFile then
			musicPause()
			loadSong(self.audioFile, false)
			musicPlay()
			musicSeek(self.previewTime/1000)
			return gameTransition
		end
	else
		gameTransition = true --Gotta get rid of this var soon
		return gameTransition
	end
	
end

---------------------------------------------------------

function Song:init(path, file)
	self.path = path
	self.file = file
	self.fullPath = self.path.."/"..self.file
	fileLoaded = parser.loadOsuFile(self.fullPath)
	if fileLoaded then
		
		if parser.getBGFile() ~= "error" then --Unable to parse BG file? Fallback to blue background
			if love.filesystem.isFile(self.path.."/"..parser.getBGFile()) == true then
				self.BGFilePath = self.path.."/"..parser.getBGFile()
			else
				debugLog("Parser returned a BG file, but it doesn't exist!")
				self.BGFilePath = "img/background.png"
			end
		else
			debugLog("Unable to parse BG file! Falling back to blue BG", 3, moduleName)
			self.BGFilePath = "img/background.png"
		end
		
		self.songTitle = parser.getSongTitle()
		self.songArtist = parser.getArtist()
		self.beatmapCreator = parser.getBMCreator()
		self.audioFile = self.path.."/"..parser.getAudioFileName()
		self.previewTime = parser.getPreviewTime()
		self.version = parser.getSongVersion()
		--debugLog("Carregou " .. self.songTitle .. ", por " .. self.songArtist .. " com sucesso.", 1, moduleName)
	else
		debugLog("Falha ao carregar " .. self.fullPath .. ", saindo", 2, moduleName)
	end
end

--------------------------------------------------------

function HitObject:init(posX, posY, nTime, vol, image) --Partial Implementation!
	self.x = posX
	self.y = posY
	self.objTime = nTime
	self.vol = vol
	self.image = image
	self.size = {}
	self.position = {}
	self.boundaries = {}
	self.hasBeenHit = false
	self.hasMissed = false
end
---------------------------------------------------------