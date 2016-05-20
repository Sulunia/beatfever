local moduleName = "[Ingame]"

local mouseSens = 0.01
local PlayerX = 0
local debugCounter = 0
local alphaEffect = 1
local playerPaddleSize = 0.86
local noteList = {}
local currentSongTime = 0
local songSkippedIntro = false
local songVol = 0.87
local screenRatio = 1
local ingameBoundaryX1 = 0
local ingameBoundaryX2 = 0
local ingameCalculatedScreenResX = 512*1
local gameDt = 0

autoPlay = false
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

local precision = 0
local noteHits = 1
local noteMisses = 1
local block = 1
local redAlert = 255

var = 1

function gameLoad(selectedSong)
	love.graphics.setBackgroundColor(0, 0, 0, 255)
	screenAlpha = 60
	
	--Graphic loading routine
	debugLog("loading player sprites and glow FX", 1, moduleName)
	playerImageFX = love.graphics.newImage("img/garsom_hitech.png")
	playerImageNormal = love.graphics.newImage("img/garsom_semswag.png")
	
	pelletHitCircle = love.graphics.newImage("img/hexa.png")
	pelletSlidertick = love.graphics.newImage("img/fruteenha.png")
	
	fx = love.audio.newSource("uisounds/normal-hitclap.wav", "static")
	fx:setVolume(0.5)
	fxMiss = love.audio.newSource("uisounds/miss.ogg", "static")
	fxMiss:setVolume(1.0)
	
	kiaiGlow = love.graphics.newImage("img/grad.png")
	--End of graphics loading	
	
	--Parse stuff and load music
	debugLog("Parsing selected file", 1, moduleName)
	parser.loadOsuFile(selectedSong.filePath)
	loadSong(selectedSong.audioFile)
	
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
	playInterpolated(dt)
	playerImageSize, playerImagePos, playerImageBoundaries = getCurrentSize(playerImageNormal, "player", playerPaddleSize, PlayerX, -ScreenSizeH/2.17, false)
	
	--Tells the player how to skip song intro
	if tonumber(noteListDinamic[1].objTime) > 8000 then
		print("You can skip the song intro by pressing the [P] Key")
	end
	debugLog("Done loading!", 1, moduleName)
	
	parser.getFilteredTimingPoints()
end

function gameUpdate(dt)
	--Var updates
	currentSongTime = getInterpolatedTimer() - var
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
	for i = block, block+170 do
		if noteListDinamic[i] ~= nil then
			noteListDinamic[i].objTime = noteListStatic[i].objTime
			noteListDinamic[i].objTime = noteListDinamic[i].objTime*(speed*round(newsSpeed, 4)) - currentSongTime*(speed*round(newsSpeed, 4))
			
			--Collision with notes
			if noteListDinamic[i].objTime + noteDrawOffset <= playerImageBoundaries.Y1 + ScreenSizeH*0.01 then	
				
				if ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) > playerImageBoundaries.X1-(playerImageBoundaries.X1*0.013)
				and ScreenSizeW/2-((noteListDinamic[i].x-256)*screenRatio) < playerImageBoundaries.X2*1.013 then
					
					if noteListDinamic[i].hasBeenHit == false then
						if autoPlay then
							if noteListDinamic[nextNote+1] ~= nil then
								nextNote = nextNote + 1
							end
						end
						block = block + 1
						if noteListDinamic[i].objType == 1 then
							scoreAdd = scoreAdd + (300 * combo)
							comboPosY = ScreenSizeH*0.02
							combo = combo + 1
							alphaEffect = 255
							fx:stop()
							fx:rewind()
							fx:setVolume(0.5)
							fx:play()
							newsSpeed = newsSpeed + 0.0005
						elseif noteListDinamic[i].objType == 2 then
							scoreAdd = scoreAdd + 100
						end
						noteHits = noteHits + 1
						noteMisses = noteMisses + 1
						noteListDinamic[i].hasBeenHit = true
					end
					
				elseif noteListDinamic[i].hasBeenHit == false then
				
					if noteListDinamic[nextNote+1] ~= nil then
						nextNote = nextNote + 1
					end
					block = block + 1
					noteListDinamic[i].hasBeenHit = true
					noteMisses = noteMisses + 1
					redAlert = 0
					newsSpeed = newsSpeed - 0.0028
					if noteListDinamic[i].objType == 1 then
						if combo > 35 then
							fxMiss:play()
						end
						combo = 1
					end
				end
				
			end
		end
	end																			
	newsSpeed = clamp(newsSpeed, 0.66, 0.423)
	screenAlpha = lerp(screenAlpha, 60, 0.06*dt*100)
	alphaEffect = lerp(alphaEffect, 1, 0.08*dt*100)
	songVol = lerp(songVol, 0.87, 0.08*dt*100)
	score = lerp(score, scoreAdd, 0.2*dt*100)
	scorePosY = lerp(scorePosY, 0, 0.2*dt*100)
	comboPosY = lerp(comboPosY, 0, 0.2*dt*100)
	precision = noteHits/noteMisses
	redAlert = lerp(redAlert, 255, 0.03*dt*100)
	kiaiAlpha = lerp(kiaiAlpha, 0, 0.06*dt*100)
	debugCounter = debugCounter + 1
	
	if autoPlay then
		if PlayerX ~= (noteListDinamic[nextNote].x-256)*screenRatio then
			if PlayerX >= (noteListDinamic[nextNote].x-256)*screenRatio then
				PlayerX = PlayerX - ((ScreenSizeW*0.6)*dt)
			else
				PlayerX = PlayerX + ((ScreenSizeW*0.6)*dt)
			end
		end
	end
	
	--Debugging FPS and DT
	if debugCounter % 6 == 0 then
		gameDt = dt
	end
	
end

function gameDraw()
	
	drawBGParallax(PlayerX*0.02, my * mouseSens, false)
	
	if kiaiAlpha > 5 then
		love.graphics.setColor(255, 255, 255, kiaiAlpha)
		love.graphics.draw(kiaiGlow, 0, 0, 0, 0.8, ScreenSizeW/(kiaiGlow:getWidth()/0.14))
		love.graphics.draw(kiaiGlow, ScreenSizeW, ScreenSizeH, 3.14159, 0.8, ScreenSizeW/(kiaiGlow:getWidth()/0.14))
	end
	
	love.graphics.setColor(255, 255, 255, 255)
	for i = block, block + 170 do
		if noteListDinamic[i] ~= nil then
			if noteListDinamic[i].hasBeenHit == false then
				if tonumber(noteListDinamic[i].objTime) < ScreenSizeH then
					love.graphics.setColor(noteListDinamic[i].r, noteListDinamic[i].g, noteListDinamic[i].b, 255)
					getCurrentSize(noteListDinamic[i].image, "HO", 0.6, (noteListDinamic[i].x-256)*screenRatio, ScreenSizeH/2+noteListDinamic[i].objTime - noteDrawOffset, true)
				end
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
	love.graphics.printf(combo,playerImageBoundaries.X1, (ScreenSizeH/1.8)+(comboPosY/2), playerImageBoundaries.X2 - playerImageBoundaries.X1, "center" )
	
	--Glow effect
	love.graphics.setColor(80, 255, 40, alphaEffect)
	getCurrentSize(playerImageFX, "playerEffect", 1.75*playerPaddleSize, PlayerX, -ScreenSizeH/2.17, true)
	
	--Score text
	if noteListDinamic[#noteListDinamic].hasBeenHit == true then
		love.graphics.setFont(ingameFont)
	else
		love.graphics.setFont(font)
	end
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf(round(score, 0), 0, scorePosY, 400, "left")
	
	--Precision text
	love.graphics.setFont(font)
	love.graphics.setColor(255, redAlert, redAlert, 255)
	love.graphics.printf((round(precision, 4)*100).."%", ScreenSizeW-(ScreenSizeW*0.1), 0, ScreenSizeW*0.1, "right")
	
	--FPS debug
	love.graphics.setFont(debugFont)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf(round(gameDt*1000, 2), ScreenSizeW-(ScreenSizeW*0.1), 70, ScreenSizeW*0.1, "right")
	love.graphics.printf(round(1000/(gameDt*1000), 2), ScreenSizeW-(ScreenSizeW*0.1), 90, ScreenSizeW*0.1, "right")
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