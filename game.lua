local moduleName = "[Ingame]"

--General background vars/Core
local mouseSens = 0.01
local PlayerX = 0
local alphaEffect = 1
local playerPaddleSize = 0.86
local noteList = {}
local currentSongTime = 0
local songSkippedIntro = false
local songVol = 0.87
local playerAlpha = 255
gameOver = false

--Game resolution specifics
local screenRatio = 1
local ingameBoundaryX1 = 0
local ingameBoundaryX2 = 0
local ingameCalculatedScreenResX = 512*1

--Should the game play itself?
autoPlay = true

--Positional vars/Control Vars
local nextNote = 1
local songTimeOld = 0
local noteDrawOffset = 0
local combo = 1
local run = false
local kiaiEnabled = 0
local kiaiAlpha = 0
local score = 0
local scoreAdd = 0
local scorePosY = 0
local comboPosY = 0
local newsSpeed = 0.4
local leadIn = 0

--Gameplay UI related vars
local precision = 0
local noteHits = 1
local noteMisses = 1
local block = 1
local redAlert = 255

--Global audio offset. This *will* be configurable in the options menu. Feel free to mess with it, optimal value is around 24~32ms
globalOffset = 29

function gameLoad(selectedSong)
	love.graphics.setBackgroundColor(0, 0, 0, 255)
	
	--Fades screen if set to 0
	screenAlpha = 60
	
	--Graphic loading routine
	debugLog("Loading player sprites and glow FX", 1, moduleName)
	
	playerImageFX = love.graphics.newImage("img/garsom_hitech.png")
	playerImageNormal = love.graphics.newImage("img/garsom_semswag.png")
	
	pelletHitCircle = love.graphics.newImage("img/hexa.png")
	pelletSlidertick = love.graphics.newImage("img/fruteenha.png")
	
	fx = love.audio.newSource("uisounds/normal-hitclap.wav", "static")
	fx:setVolume(0.5)
	fxMiss = love.audio.newSource("uisounds/miss.ogg", "static")
	fxMiss:setVolume(1.0)
	
	kiaiGlow = love.graphics.newImage("img/grad.png")
	
	--Particle System setup
	particleClickTexture = love.graphics.newImage("img/crashParticle.png")
	particleClick = love.graphics.newParticleSystem(particleClickTexture, 60)
		particleClick:setParticleLifetime(1, 1.6)
		particleClick:setSizeVariation(1)
		particleClick:setLinearAcceleration(-120, 26, 120, 40)
		particleClick:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
		particleClick:setDirection(math.rad(90))
		particleClick:setSpin(1)
		particleClick:setSpeed(0, -170)
	--End of particle system setup
	
	--End of graphics loading	
	
	
	--Parse stuff and load music
	debugLog("Parsing selected file", 1, moduleName)
	parser.loadOsuFile(selectedSong.filePath)
	loadSong(selectedSong.audioFile)
	leadIn = parser.getAudioLeadIn()
	
	--Generate a list suitable for messing around with it's values and a static list for original value referencing
	noteListStatic = parser.getHitObjects(pelletHitCircle, pelletSlidertick)
	noteListDinamic = parser.getHitObjects(pelletHitCircle, pelletSlidertick)
	
	--Begin BPM calculation
	timingPoints = parser.getTimingPoints()
	curTimingPoint = 1
	initialTime = {Time = timingPoints[1].offset, kiai = 0}
	BPMList = {}
	curMPB = timingPoints[1].mpb
	
	while (initialTime.Time < tonumber(noteListStatic[#noteListStatic].objTime)) do
		initialTime = {Time = initialTime.Time + curMPB, kiai = timingPoints[curTimingPoint].kiai }
		if timingPoints[curTimingPoint + 1] ~= nil then
			if (initialTime.Time > timingPoints[curTimingPoint + 1].offset) then
				if tonumber(timingPoints[curTimingPoint + 1].inherited) == 1 then
					curMPB = timingPoints[curTimingPoint + 1].mpb
				end
				curTimingPoint = curTimingPoint + 1
			end
		end
		table.insert(BPMList, initialTime)
	end
	curTimingPoint = 1
	
	--Begins game
	debugLog("Playing the song using interpolated timer", 1, moduleName)
	playInterpolated(dt, leadIn)
	playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, false)
	
	--Tells the player how to skip song intro
	if tonumber(noteListDinamic[1].objTime) > 8000 then
		print("You can skip the song intro by pressing the [P] Key")
	end
	debugLog("Done loading!", 1, moduleName)
	
	debugLog("Game begins!", 1, moduleName)
end

function gameUpdate(dt)
	--Var updates
	particleClick:setSizes(ScreenSizeH/700, ScreenSizeH/650, ScreenSizeH/600)
	currentSongTime = getInterpolatedTimer() - globalOffset
	noteDrawOffset = ScreenSizeH - (ScreenSizeH - playerImageBoundaries.Y1)
	screenRatio = ScreenSizeH/384
	speed = (ScreenSizeH/ScreenSizeHOld)*screenRatio --Speed at which notes fall
	particleClick:setSpeed(0, clamp(-170-combo, -170, -500))
	
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
	
	--BPMs on the score
	if currentSongTime > BPMList[curTimingPoint].Time then
		scorePosY = ScreenSizeH*0.06
		if BPMList[curTimingPoint+1] ~= nil then
			curTimingPoint = curTimingPoint + 1
			if BPMList[curTimingPoint+1]~= nil then
				if tonumber(BPMList[curTimingPoint].kiai) == 1 then
					kiaiAlpha = 160
				end
			end
		end
	end
	
	--Gets player input. This should later be actually done in the keyboard callback to avoid delays
	if love.keyboard.isDown("right") and playerImageBoundaries.X2 < ingameBoundaryX2 + ScreenSizeW*0.017 then
		if love.keyboard.isDown("lshift") then
			PlayerX = PlayerX - (ScreenSizeW*(0.63*2)*dt)
			run = true
		else
			PlayerX = PlayerX - (ScreenSizeW*0.63)*dt
			run = false
		end
	end
	if love.keyboard.isDown("left") and playerImageBoundaries.X1 > ingameBoundaryX1 - ScreenSizeW*0.017 then 
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
	--Updates only 170 notes every frame, optimization
	--Makes sure the game doesn't lag beyond belief in marathon maps
	for i = block, block+170 do
		if noteListDinamic[i] ~= nil then
			noteListDinamic[i].objTime = noteListStatic[i].objTime
			noteListDinamic[i].objTime = noteListDinamic[i].objTime*(speed*round(newsSpeed, 4)) - currentSongTime*(speed*round(newsSpeed, 4))
			
			--Collision with notes
			if noteListDinamic[i].objTime + noteDrawOffset <= playerImageBoundaries.Y1 + ScreenSizeH*0.01 then	
				
				if ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) > playerImageBoundaries.X1-(playerImageBoundaries.X1*0.013)
				and ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) < playerImageBoundaries.X2*1.013 then
					
					--User hit the note!
					if noteListDinamic[i].hasBeenHit == false then
						if autoPlay then
							if noteListDinamic[nextNote+1] ~= nil then
								nextNote = nextNote + 1
							end
						end
						--Updates rendering block pos
						block = block + 1
						--Adds score accordingly
						if noteListDinamic[i].objType == 1 then
							scoreAdd = scoreAdd + (300 * combo)
							comboPosY = ScreenSizeH*0.03
							combo = combo + 1
							alphaEffect = 255
							fx:stop()
							fx:rewind()
							fx:setVolume(0.5)
							fx:play()
							particleClick:setPosition((ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio)), playerImageBoundaries.Y1)
							particleClick:setColors(noteListDinamic[i].r, noteListDinamic[i].g, noteListDinamic[i].b, 170, noteListDinamic[i].r, noteListDinamic[i].g, noteListDinamic[i].b, 0)
							particleClick:emit(15)
							newsSpeed = newsSpeed + 0.0005
						elseif noteListDinamic[i].objType == 2 then
							scoreAdd = scoreAdd + 100
						end
						--Updates precisions
						noteHits = noteHits + 1
						noteMisses = noteMisses + 1
						noteListDinamic[i].hasBeenHit = true
					end
				
				elseif noteListDinamic[i].hasBeenHit == false then
					--User missed the note!	
					if noteListDinamic[nextNote+1] ~= nil then
						nextNote = nextNote + 1
					end
					block = block + 1
					noteListDinamic[i].hasBeenHit = true
					noteMisses = noteMisses + 1
					redAlert = 0
					--Changes game pace a bit
					newsSpeed = newsSpeed - 0.0028
					--Plays error SFX
					if noteListDinamic[i].objType == 1 then
						if combo > 35 then
							fxMiss:play()
						end
						--Resets combo
						combo = 1
					end
				end
				
			end
		end
	end																			
	
	
	--Checks to see if the last note has been hit
	if noteListDinamic[#noteListDinamic].hasBeenHit == true then
		gameOver = true
	end
	
	
	
	--Updates vars that control ingame graphics
	newsSpeed = clamp(newsSpeed, 0.66, 0.423)
	alphaEffect = lerp(alphaEffect, 1, 0.08*dt*100)
	songVol = lerp(songVol, 0.87, 0.08*dt*100)
	score = lerp(score, scoreAdd, 0.2*dt*100)
	scorePosY = lerp(scorePosY, 0, 0.2*dt*100)
	comboPosY = lerp(comboPosY, 0, 0.2*dt*100)
	precision = noteHits/noteMisses
	redAlert = lerp(redAlert, 255, 0.03*dt*100)
	kiaiAlpha = lerp(kiaiAlpha, 0, 0.06*dt*100)
	
	if not gameOver then
		screenAlpha = lerp(screenAlpha, 60, 0.06*dt*100)
	else
		screenAlpha = lerp(screenAlpha, 120, 0.04*dt*100)
		playerAlpha = lerp(playerAlpha, 0, 0.05*dt*100)
	end
	
	
	--Updates particle systems
	particleClick:update(dt*4.5)
	
	--Autoplay scripting
	if autoPlay then
		if PlayerX ~= (noteListDinamic[nextNote].x-256)*screenRatio then
			if PlayerX > (noteListDinamic[nextNote].x-256)*screenRatio then
				PlayerX = PlayerX - (((ScreenSizeW*0.6)*dt)*2)
			elseif PlayerX < (noteListDinamic[nextNote].x-256)*screenRatio then
				PlayerX = PlayerX + (((ScreenSizeW*0.6)*dt)*2)
			end
			
			if (PlayerX +(((ScreenSizeW*0.6)*dt)*2) > (noteListDinamic[nextNote].x-256)*screenRatio)
			and (PlayerX -(((ScreenSizeW*0.6)*dt)*2) < (noteListDinamic[nextNote].x-256)*screenRatio) then
				PlayerX = (noteListDinamic[nextNote].x-256)*screenRatio
			end
			
		end
	end
	
	
	
end

function gameDraw()
	
	drawBGParallax(PlayerX*0.02, my * mouseSens, false)
	
	if kiaiAlpha > 5 then
		love.graphics.setColor(255, 255, 255, kiaiAlpha)
		love.graphics.draw(kiaiGlow, 0, 0, 0, 0.8, ScreenSizeW/(kiaiGlow:getWidth()/0.14))
		love.graphics.draw(kiaiGlow, ScreenSizeW, ScreenSizeH, 3.14159, 0.8, ScreenSizeW/(kiaiGlow:getWidth()/0.14))
	end
	
	--Note crash effect
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(particleClick,0,0)
	
	love.graphics.setColor(255, 255, 255, 255)
	for i = block, block + 170 do
	--Draws only 170 notes after the next note that should be hit. Makes sure FPS doesn't abysmally on marathon songs (not goood having over 1000 draw calls here)
		if noteListDinamic[i] ~= nil then
			if noteListDinamic[i].hasBeenHit == false then
				if tonumber(noteListDinamic[i].objTime) < ScreenSizeH then
					love.graphics.setColor(noteListDinamic[i].r, noteListDinamic[i].g, noteListDinamic[i].b, 255)
					getCurrentSize(noteListDinamic[i].image, "HO", 0.6, (noteListDinamic[i].x-256)*screenRatio, ScreenSizeH/2+noteListDinamic[i].objTime - noteDrawOffset, true)
				end
			end
		end
	end
	
	--If player is running...
	if run then 
		love.graphics.setColor(20, 255, 20, playerAlpha)
		playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	else
		love.graphics.setColor(255, 255, 255, playerAlpha)
		playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	end
	
	--Combo count
	love.graphics.setFont(ingameFont)
	love.graphics.setColor(255, 255, 255, playerAlpha)
	love.graphics.printf(combo,playerImageBoundaries.X1, (ScreenSizeH/1.8)+(comboPosY/2), playerImageBoundaries.X2 - playerImageBoundaries.X1, "center" )
	
	--Glow effect
	love.graphics.setColor(80, 255, 40, alphaEffect)
	getCurrentSize(playerImageFX, "playerEffect", 1.75*playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	
	
	--Score text
	love.graphics.setColor(255, 255, 255, playerAlpha)
	love.graphics.printf(round(score, 0), 0, scorePosY, 400, "left")
	
	--Precision text
	love.graphics.setFont(font)
	love.graphics.setColor(255, redAlert, redAlert, playerAlpha)
	love.graphics.printf((round(precision, 4)*100).."%", ScreenSizeW-(ScreenSizeW*0.1), 0, ScreenSizeW*0.1, "right")
	
	--FPS debug
	love.graphics.setFont(debugFont)
	love.graphics.setColor(255, 255, 255, 255)
end

--THOUGHTS
--after a bit of looking around, finally got to find the line that calculates the AR based on it's .osu value
--Taken from opsu source code:
--// approachRate (hit object approach time)
--if (approachRate < 5)
--	approachTime = (int) (1800 - (approachRate * 120));
--else
--	approachTime = (int) (1200 - ((approachRate - 5) * 150));

--I should implement this soon. 