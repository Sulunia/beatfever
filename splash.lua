local moduleName = "[SplashScreen]"
abs = math.abs
new = complex.new -- required for using the FFT function.
local ignoreBGLoad = false

-- Arrays for FFT
local UpdateSpectrum = false
local GeneratedFFTList = false
local mediaFFT = 0
local spectrum = {}
local spectrumOld = {}

-- Timer for interpolation
local Stime = love.timer.getTime()
local openTimeStart = 0
local openTimeEnd = 0
local menuTime = 0

-- Background music
local Song = "Songs/song.mp3" 	-- You have to put your songs somewhere along the main.lua file, so love2d can access it. Then, just point this string to the song you wish to use.
local hasBeenLoaded = false

-- Logo rotation angle
local angle = 0

-- Logo scale values
local sizeMultLogo = 9
local sizeNoiseLogo = 1
local splashDT = 0.17

-- Logo click event handlers
local logoClicked = false
local clickedUp = 1
local alphaClick = 255
local clickedSize = 1
local intervalLogoClick = 60
local canClickMenu = true

-- Parallax effect intensity
local mouseSens = 0.03

-- Number of background trails
local amountTrails = 30

-- Menu buttons
local button1SizeHover = 1
local button2SizeHover = 1
local buttonYHidden = love.graphics.getHeight()

-- Menu Opened
local menuOpened = false

local menuAlpha = 255
local screenTransitioning = false

function splashLoad()
	-- Reset vars
	screenTransitioning = false
	menuAlpha = 255
	clickedUp = 1
	logoClicked = false
	intervalLogoClick = 60
	canClickMenu = true
	menuOpened = false
	
	-- Loads menu background song
	if not hasBeenLoaded then
		loadSong(Song, true)
		musicPlay()
		hasBeenLoaded = true
	end
	-- Menu click sound
	debugLog("Loading splash screen sound effects", 1, moduleName)
	logoClickSound = love.audio.newSource("uisounds/selectLogo.ogg")
	
	-- The amount of frequencies to obtain as result of the FFT process.
	Size = 1024 
	
	Frequency = musicSamplingRate()
	-- The size of each frequency range of the final generated FFT values.
	length = Size / Frequency 
	
	love.graphics.setBackgroundColor(255, 255, 255, 255)
	
	-- Image Loading routine
	debugLog("Loading Splashscreen graphics", 1, moduleName)
	
	-- Particle textures
	particleStarTexture = love.graphics.newImage("img/star.png")
	
	-- Particle systems
	particleStar = love.graphics.newParticleSystem(particleStarTexture, 128)
	particleStarDireita = love.graphics.newParticleSystem(particleStarTexture, 128)
	
	-- Logo image
	logo = love.graphics.newImage("img/logoz.png")
	logoSize, logoPos, logoBoundaries = getCurrentSize(logo, "GameLogo", 1, 0, 0, clickedUp, false)
	
	-- Background image
	if not ignoreBGLoad then
		background = love.graphics.newImage("img/background.png")
	end
	ignoreBGLoad = true
	-- Trails
	trailred = love.graphics.newImage("img/trailred.png")
	trailgreen = love.graphics.newImage("img/trailgreen.png")
	trailblue = love.graphics.newImage("img/trailblue.png")
	trailyellow = love.graphics.newImage("img/trailyellow.png")
	
	-- Buttons
	button1 = love.graphics.newImage("img/play_btn.png")
	button1Size, button1Pos, button1Boundaries = getCurrentSize(button1, "Play", 1, 0, 0, false)
	button2 = love.graphics.newImage("img/options_btn.png")
	button2Size, button2Pos, button2Boundaries = getCurrentSize(button2, "Options", 1, 0, 0, false)
	
	debugLog("Done!", 1, moduleName)
	
	-- List initialization
	trailsx = {}
	trailsy = {}
	trailsx, trailsy = generateMainMenuTrails(amountTrails, amountTrails) --generates the colorful lines on the splashscreen.
	
	-- Particles Setup
	particleStar:setParticleLifetime(1.3, 4)
	particleStar:setEmissionRate(86)
	particleStar:setSizeVariation(1)
	particleStar:setLinearAcceleration(0, ScreenSizeH/2, 120, ScreenSizeH)
	particleStar:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
	particleStar:setDirection(math.rad(290))
	particleStar:setSizes(0.1, 0.16, 0.2)
	particleStar:setSpin(1)
	particleStar:setSpeed(ScreenSizeH, ScreenSizeH*1.2)
	
	-- particleStartDireita = particleStar:clone() Oddly, this line doesnt effin' work, cuz NIL NIL NIL NIL EVERYWHERE. So, below we paste a lot of ugly code.
	particleStarDireita:setParticleLifetime(1.3, 4)
	particleStarDireita:setEmissionRate(86)
	particleStarDireita:setSizeVariation(1)
	particleStarDireita:setLinearAcceleration(0, ScreenSizeH/2, -120, ScreenSizeH)
	particleStarDireita:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
	particleStarDireita:setDirection(math.rad(250))
	particleStarDireita:setSizes(0.1, 0.16, 0.2)
	particleStarDireita:setSpin(1)
	particleStarDireita:setSpeed(ScreenSizeH, ScreenSizeH*1.2)

end

function splashUpdate(dt)
	-- Delta time
	local Etime = love.timer.getTime()
	splashDT = dt
	-- Returns the current sample being played by the audio manager.
	local MusicPos = musicRetrieveCurSample() 
	-- Obtain the size of the song in samples, so you can keep track of when it's gonna end.
	local MusicSize = musicRetrieveSize() 
	
	
	-- Loop music 
	-- Rewinds the song when the music is almost over. Should shuffle musics in folder songs in the future.
	if MusicPos >= MusicSize - 512 then musicRewind() end 
	
	if GeneratedFFTList == false then
		--First iteraction generates two exact same lists.
		spectrumOld = generateFFTTable(Size) 
		spectrum = spectrumOld
		GeneratedFFTList = true
	end
	
	if Etime - Stime > 0.05 then
		spectrumOld = spectrum
		--keeps one spectrum info before and updates another list with fresh FFT info..
		spectrum = generateFFTTable(Size) 
		UpdateSpectrum = true
	end
	for i = 1, #spectrumOld do
		--..so we can lerp the old list into the new one, smoothing the bar rendering
		spectrumOld[i] = lerp(spectrumOld[i], spectrum[i], 0.03-dt) 
	end

	-- Rotates main logo
	angle = angle + dt * math.pi / 3
	angle = angle % (2 * math.pi)

	-- Parallax effect calculations
	mx = mx - ScreenSizeW / 2
	my = my - ScreenSizeH / 2
	
	updateMainMenuTrails(dt)
		
	-- update das trails
	if Etime-Stime > 0.05 then
		Stime = Etime
	end
		
	-- update do valor médio dos graves FFT
	if UpdateSpectrum then
		for i = 1, 7 do
		mediaFFT = mediaFFT + spectrumOld[i]:abs()
		end
		mediaFFT = mediaFFT / 6
	end
	
	--Menu Interaction	
	-- Open Menu
	if (oldMouseClicked == false and newMouseClicked == true and isHovered(logoBoundaries) and not logoClicked and canClickMenu) then
		logoClicked = true
		sizeMultLogo = sizeMultLogo - 0.09
		openTimeStart = love.timer.getTime()
		logoClickSound:setVolume(0.87)
		logoClickSound:play()
		debugLog("GameLogo has been clicked! Opening options..", 1, moduleName)
		canClickMenu = false
	-- Close Menu
	elseif (oldMouseClicked == false and newMouseClicked == true and isHovered(logoBoundaries) and logoClicked and canClickMenu) then
		logoClicked = false
		sizeMultLogo = sizeMultLogo - 0.09
		debugLog("GameLogo has been clicked! Closing options", 1, moduleName)
		canClickMenu = false
	end
	
	if clickedUp >= 0.9 * ScreenSizeH/4 then
		menuOpened = true
	else
		menuOpened = false
	end
	
	-- Update menu positions
	if (logoClicked) then
		openTimeEnd = love.timer.getTime()
		if (openTimeEnd - openTimeStart > 0.2) then
			openTimeEnd = love.timer.getTime()
			clickedUp = lerp(clickedUp, ScreenSizeH/4, 0.03*dt*100)
			alphaClick = lerp(alphaClick, 0, 0.09*dt*100)
			clickedSize = lerp(clickedSize, 0.8, 0.04*dt*100)
			buttonYHidden = lerp(buttonYHidden, 0, 0.05*dt*100)
		end
	else
		clickedUp = lerp(clickedUp, 0, 0.01*dt*100)
		alphaClick = lerp(alphaClick, 255, 0.09*dt*100)
		clickedSize = lerp(clickedSize, 1, 0.02*dt*100)
		buttonYHidden = lerp(buttonYHidden, love.graphics.getHeight(), 0.05*dt*100)
	end
	
	-- Play button
	if(isHovered(button1Boundaries)) then
		button1SizeHover = lerp(button1SizeHover, 1.2, 0.14*dt*100)
		if(oldMouseClicked == false and newMouseClicked == true and menuOpened == true) then 
			screenTransitioning = true 
			debugLog("Screen transitioning", 1, moduleName)
		end		
	else
		button1SizeHover = lerp(button1SizeHover, 1, 0.04*dt*100)
	end
	
	-- Options button
	if(isHovered(button2Boundaries)) then
		button2SizeHover = lerp(button2SizeHover, 1.2, 0.14*dt*100)
	else
		button2SizeHover = lerp(button2SizeHover, 1, 0.04*dt*100)
	end
	
	if (Count % intervalLogoClick == 0 and not canClickMenu) then
		canClickMenu = true
	end
	
	-- Fade Out/In
	if screenTransitioning then
		menuAlpha = lerp(menuAlpha, 0, 0.05*dt*100)
	end
	
	-- Change screen
	if menuAlpha <= 10 then
		debugLog("Screen changed!", 1, moduleName)
		splashDispose()
		selectionLoad()
		Screen = 1
	else
		particleStar:update(dt*1.3)
		particleStarDireita:update(dt*1.3)
	end
	
end

function splashDraw()
	-- Draw background image
	love.graphics.setColor(255, 255, 255, 255)

	-- Get bar widths
	numBars = #spectrum / 4
	barSize = (ScreenSizeW / numBars) * 3
	
	-- Updates logo size
	sizeNoiseLogo = lerp(sizeNoiseLogo, clamp(1 - (mediaFFT/(numBars*90)), 1, 0.95), 0.18*splashDT*100)

	-- Draw bars
	love.graphics.push()
		-- Center everything
		love.graphics.translate(mx * mouseSens, my * mouseSens)
		love.graphics.setBackgroundColor(0, 0, 0)
		love.graphics.setColor(255, 255, 255, 159)
		love.graphics.draw(background, 0, 0, 0, ScreenSizeW/(background:getWidth()-(background:getWidth()*0.2)), ScreenSizeH/(background:getHeight()-(background:getHeight()*0.2)), background:getWidth()*0.1, background:getHeight()*0.1)
		--Shear effect to align with logo
		love.graphics.shear(-0.2, 0)
		
		-- Reset colors
		love.graphics.setColor(255, 255, 255, 255)

		--Draws glowing trails in main menu
		drawMainMenuTrails(trailsx, trailsy)
	
		-- Semitransparent bars
		love.graphics.setColor(255, 255, 255, menuAlpha/2)
	
		if UpdateSpectrum then
			for i = 1, numBars do -- In case you want to show only a part of the list, you can use #spec/(amount of bars). Setting this to 1 will render all bars processed.
			love.graphics.rectangle("fill", 30 + i * barSize, ScreenSizeH+30, barSize, -1 * (spectrumOld[i]:abs() * 0.8)) -- iterate over the list, and draws a rectangle for each band value.
			end
		end

	love.graphics.pop()
	
	-- Draw particle systems
	love.graphics.draw(particleStar, 0, ScreenSizeH)
	love.graphics.draw(particleStarDireita, ScreenSizeW, ScreenSizeH)
	
	-- Draw logo
	love.graphics.push()
		love.graphics.translate(ScreenSizeW / 2, ScreenSizeH / 2)
		love.graphics.rotate(math.sin(angle) * 0.12)
		love.graphics.translate(-mx * mouseSens + - ScreenSizeW / 2, -my * mouseSens + - ScreenSizeH / 2)
		
		if (isHovered(logoBoundaries)) then
			sizeMultLogo = lerp(sizeMultLogo, 1.50, 0.1*splashDT*100)
		else
			sizeMultLogo = lerp(sizeMultLogo, 1.27, 0.06*splashDT*100)
		end		
		
		-- Reset color
		love.graphics.setColor(255, 255, 255, menuAlpha)
		logoSize, logoPos, logoBoundaries = getCurrentSize(logo, "GameLogo", sizeMultLogo*sizeNoiseLogo*clickedSize, 0, clickedUp, true)
		
		-- Alpha fade-in
		love.graphics.setColor(255, 255, 255, alphaClick)
		love.graphics.setFont(font)
		love.graphics.print("CLICK TO PLAY", logoBoundaries.X2-ScreenSizeW/8, logoBoundaries.Y2)
		love.graphics.setColor(255, 255, 255, menuAlpha)
		
		-- Draws debug stuff
		if logoClicked then
			love.graphics.setColor(255, 255, 255, menuAlpha)
			button1Size, button1Pos, button1Boundaries = getCurrentSize(button1, "Play", button1SizeHover/1.6, ScreenSizeW/4, -ScreenSizeH/4-buttonYHidden, true)
			love.graphics.setColor(255, 255, 255, menuAlpha)
			button2Size, button2Pos, button2Boundaries = getCurrentSize(button2, "Options", button2SizeHover/1.8, -ScreenSizeW/4, -ScreenSizeH/4-buttonYHidden, true)
		end
		
	love.graphics.pop()
	-- Mouse pos debug info
	debugDrawMousePos(mouseScreenX, mouseScreenY)
	
	drawFades(false, true)
end

function splashDispose()
	local oldmem = collectgarbage("count")
	particleStar = nil
	particleStarDireita = nil
	logoClickSound = nil
	logo = nil
	button1 = nil
	button2 = nil
	collectgarbage("collect")
	local newmem = collectgarbage("count")
	debugLog("Disposed of resources! "..round(oldmem-newmem, 3).."kB memory freed.", 1, moduleName)
	
end
