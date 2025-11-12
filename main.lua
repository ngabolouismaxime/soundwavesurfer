-- Sound Wave Surfer
-- A rhythm game prototype for Game Off 2025

local Player = require("player")
local Wave = require("wave")
local Beat = require("beat")

-- Audio assets
local jumpSound
local landingSound
local beatHitSound

-- Game state
local player
local wave
local beat
local debugMode = false

local function tryLoadSound(path)
    local ok, source = pcall(love.audio.newSource, path, "static")
    if ok and source then
        source:setVolume(0.7)  -- Reduce volume to prevent distortion
        return source
    end

    print("Warning: Could not load sound effect: " .. path)
    return nil
end

local function playSound(sound)
    if sound then
        -- Clone the sound to avoid popping from stop/play
        local instance = sound:clone()
        instance:play()
    end
end

function love.load()
    -- Set up graphics
    love.graphics.setBackgroundColor(0.1, 0.05, 0.15)  -- Dark purple background
    
    -- Initialize game objects
    wave = Wave.new()
    player = Player.new(150, 300)
    beat = Beat.new()
    
    -- Try to load music if available (optional for prototype)
    beat:loadMusic("assets/music.mp3")
    if beat.music then
        beat.music:setVolume(0.75)
    end
    
    -- Try to load wave amplitude data (e.g., "music.wave.dat")
    local waveDataFile = "assets/music.wave.dat"
    if wave:loadAmplitudeData(waveDataFile) then
        print("Wave is now audio-reactive!")
    else
        print("Using static wave (no amplitude data found)")
    end
    
    -- Start the beat system
    beat:playMusic()

    -- Load optional sound effects
    jumpSound = tryLoadSound("assets/jump.mp3")
    landingSound = tryLoadSound("assets/land.mp3")
    beatHitSound = tryLoadSound("assets/beat-hit.mp3")
    
    print("Sound Wave Surfer loaded!")
    print("Controls:")
    print("  SPACE or LEFT CLICK - Jump")
    print("  F1 - Toggle debug mode")
    print("  ESC - Quit")
end

function love.update(dt)
    -- Update game objects
    beat:update(dt)
    
    -- Sync wave amplitude with current music time
    wave:setCurrentTime(beat:getCurrentTime())
    wave:update(dt)
    
    local landed = player:update(dt, wave)
    
    -- Check if player hit the beat while on wave
    local playerOnWave = player:isOnWave(wave)
    local hitBeat = beat:checkBeatHit(playerOnWave)
    
    if hitBeat then
        -- Visual feedback for hitting a beat
        playSound(beatHitSound)
    end

    if landed then
        playSound(landingSound)
    end
end

function love.draw()
    -- Draw wave
    wave:draw()
    
    -- Draw player
    player:draw()
    
    -- Draw beat indicator and score
    beat:draw()
    
    -- Debug information
    if debugMode then
        love.graphics.setColor(1, 1, 1, 0.8)
        local waveY = wave:getYAtX(player.x)
        love.graphics.print("Player Y: " .. math.floor(player.y), 10, 70)
        love.graphics.print("Wave Y at Player: " .. math.floor(waveY), 10, 90)
        love.graphics.print("Distance: " .. math.floor(math.abs(player.y - waveY)), 10, 110)
        love.graphics.print("On Wave: " .. tostring(player:isOnWave(wave)), 10, 130)
        love.graphics.print("Grounded: " .. tostring(player.isGrounded), 10, 150)
        love.graphics.print("Velocity Y: " .. math.floor(player.velocityY), 10, 170)
        
        -- Draw a line showing the wave Y at player X
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle("line", player.x, waveY, 5)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Instructions
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("SPACE/CLICK to Jump | F1 for Debug", 10, love.graphics.getHeight() - 25)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.keypressed(key)
    if key == "space" then
        local jumped = player:jump()
        if jumped then
            playSound(jumpSound)
        end
    elseif key == "f1" then
        debugMode = not debugMode
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then  -- Left click
        local jumped = player:jump()
        if jumped then
            playSound(jumpSound)
        end
    end
end

