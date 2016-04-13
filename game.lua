local moduleName = "[Ingame]"

local mouseSens = 0.01
local PlayerX = 0
local alphaEffect = 1
local playerPaddleSize = 0.7
local noteList = {}
local currentSongTime = 0
local songSkippedIntro = false
local songVol = 0.87
local screenRatio = 1
local ingameBoundaryX1 = 0
local ingameBoundaryX2 = 0
local ingameCalculatedScreenResX = 512*1

autoPlay = false
local nextNote = 1
local songTimeOld = 0
local noteDrawOffset = 0
local combo = 1
local run = false
local score = 0
local scoreAdd = 0
local scorePosY = 0

function gameLoad(selectedSong)
	love.graphics.setBackgroundColor(0, 0, 0, 255)
	screenAlpha = 60
	
	--Graphic loading routine
	debugLog("loading player sprites and glow FX", 1, moduleName)
	playerImageFX = love.graphics.newImage("img/garsom_hitech.png")
	playerImageNormal = love.graphics.newImage("img/garsom_semswag.png")
	
	pellet1 = love.graphics.newImage("img/fruit_3.png")
	
	fx = love.audio.newSource("uisounds/normal-hitclap.wav", "static")
	fx:setVolume(0.5)
	fxMiss = love.audio.newSource("uisounds/miss.ogg", "static")
	fxMiss:setVolume(1.0)
	--End of graphics loading
	
	--Start game logic
	debugLog("Parsing selected file", 1, moduleName)
	parser.loadOsuFile(selectedSong.filePath)
	loadSong(selectedSong.audioFile)
	noteListStatic = parser.getHitObjects()
	noteListDinamic = parser.getHitObjects()
	debugLog("Playing the song using interpolated timer", 1, moduleName)
	playInterpolated(dt)
	playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, false)
	
	--Tells the player how to skip song intro
	if tonumber(noteListDinamic[1].objTime) > 8000 then
		print("You can skip the song intro by pressing the [P] Key")
	end
	debugLog("Done loading!", 1, moduleName)
	
end

function gameUpdate(dt)
	currentSongTime = getInterpolatedTimer(dt)
	noteDrawOffset = ScreenSizeH - (ScreenSizeH - playerImageBoundaries.Y1)
	screenRatio = ScreenSizeH/384
	speed = (ScreenSizeH/ScreenSizeHOld)*screenRatio --Speed at which notes fall
	
	ingameCalculatedScreenResX = 512*screenRatio
	ingameBoundaryX1 = (ScreenSizeW - ingameCalculatedScreenResX)/2
	ingameBoundaryX2 = (ScreenSizeW - ingameCalculatedScreenResX)/2 + ingameCalculatedScreenResX
	
	--Skips song if user told to do so
	if songSkippedIntro ~= true and noteListDinamic[1].objTime - currentSongTime > 6000 then
		if love.keyboard.isDown("p") then
			songSkippedIntro = true
			musicSeek((noteListStatic[1].objTime/1000 - 3))
			screenAlpha = 0
			songVol = 0
			print("Skipped!")
		end
	end
	
	--Gets player input. This should later be actually done in the keyboard callback to avoid delays
	if love.keyboard.isDown("right") and playerImageBoundaries.X2 < ingameBoundaryX2 then
		if love.keyboard.isDown("lshift") then
			PlayerX = PlayerX - (ScreenSizeW*(0.63*2)*dt)
			run = true
		else
			PlayerX = PlayerX - (ScreenSizeW*0.63)*dt
			run = false
		end
	end
	if love.keyboard.isDown("left") and playerImageBoundaries.X1 > ingameBoundaryX1 then 
		if love.keyboard.isDown("lshift") then
			PlayerX = PlayerX + (ScreenSizeW*(0.63*2)*dt)
			run = true
		else
			PlayerX = PlayerX + (ScreenSizeW*0.63)*dt
			run = false
		end
	end
	
	if love.keyboard.isDown("lshift") then
		run = true
	else
		run = false
	end
	
	--Notelist update
	for i = 1, #noteListDinamic do
		noteListDinamic[i].objTime = noteListStatic[i].objTime
		noteListDinamic[i].objTime = noteListDinamic[i].objTime*(speed*0.5) - currentSongTime*(speed*0.5)
		
		--Collision with notes
		if noteListDinamic[i].objTime + noteDrawOffset <= playerImageBoundaries.Y1 then
				if ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) > playerImageBoundaries.X1-(playerImageBoundaries.X1*0.013)
				and ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) < playerImageBoundaries.X2*1.013 then
					if noteListDinamic[i].hasBeenHit == false then
						if autoPlay then
							if noteListDinamic[nextNote+1] ~= nil then
								nextNote = nextNote + 1
							end
						end
						scoreAdd = scoreAdd + (300 * combo)
						scorePosY = ScreenSizeH*0.02
						combo = combo + 1
						fx:stop()
						fx:play()
						alphaEffect = 255
						noteListDinamic[i].hasBeenHit = true
					end
				elseif noteListDinamic[i].hasBeenHit == false then
					if noteListDinamic[nextNote+1] ~= nil then
						nextNote = nextNote + 1
					end
					noteListDinamic[i].hasBeenHit = true
					if combo > 35 then
						fxMiss:play()
					end
					combo = 1
				end
			end
	end																			
	
	screenAlpha = lerp(screenAlpha, 60, 0.06)
	alphaEffect = lerp(alphaEffect, 1, 0.08)
	songVol = lerp(songVol, 0.87, 0.08)
	score = lerp(score, scoreAdd, 0.2)
	scorePosY = lerp(scorePosY, 0, 0.2)
	
	if autoPlay then
		if PlayerX ~= (noteListDinamic[nextNote].x-256)*screenRatio then
			if PlayerX >= (noteListDinamic[nextNote].x-256)*screenRatio then
				PlayerX = PlayerX - ((ScreenSizeW*0.6)*dt)
			else
				PlayerX = PlayerX + ((ScreenSizeW*0.6)*dt)
			end
		end
	end
	
end

function gameDraw()
	
	drawBGParallax(PlayerX*0.02, my * mouseSens, false)
	
	love.graphics.setColor(255, 255, 255, 255)
	for i = 1, #noteListDinamic do
		if noteListDinamic[i].hasBeenHit == false then
			if tonumber(noteListDinamic[i].objTime) < ScreenSizeH then
				getCurrentSize(pellet1, noteListDinamic[i].x, 1, (noteListDinamic[i].x-256)*screenRatio, ScreenSizeH/2+noteListDinamic[i].objTime - noteDrawOffset, true)
			end
		end
	end
	
	if run then
		love.graphics.setColor(20, 255, 20, 255)
		playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	else
		love.graphics.setColor(255, 255, 255, 255)
		playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	end
	
	--Combo count
	love.graphics.setFont(ingameFont)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf(combo,playerImageBoundaries.X1, (ScreenSizeH/1.8)+(scorePosY/2), playerImageBoundaries.X2 - playerImageBoundaries.X1, "center" )
	
	--Glow effect
	love.graphics.setColor(80, 255, 40, alphaEffect)
	getCurrentSize(playerImageFX, "playerEffect", 1.75*playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	
	--Score
	love.graphics.setFont(font)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf(round(score, 0), 0, scorePosY, 400, "left")
end

--THOUGHTS
--after a bit of looking around, finally got to find the line that calculates the AR based on it's .osu value
--Taken from opsu source code:
--// approachRate (hit object approach time)
--if (approachRate < 5)
--	approachTime = (int) (1800 - (approachRate * 120));
--else
--	approachTime = (int) (1200 - ((approachRate - 5) * 150));

--I should implement this soon. Gotta figure out how to make the player move framerate independently.