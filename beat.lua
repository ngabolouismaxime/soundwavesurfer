local Beat = {}
Beat.__index = Beat

function Beat.new()
    local self = setmetatable({}, Beat)
    
    -- Audio
    self.music = nil
    self.musicPlaying = false
    
    -- Beat timing (in seconds) - manually defined
    -- For prototype: simple beats every 0.6 seconds
    self.beatInterval = 0.6
    self.beats = {}
    self:generateBeats(60)  -- Generate 60 seconds worth of beats
    
    -- Current beat tracking
    self.currentTime = 0
    self.nextBeatIndex = 1
    self.beatActive = false
    self.beatActiveDuration = 0.15  -- How long beat indicator stays visible
    self.beatTimer = 0
    
    -- Scoring
    self.score = 0
    self.lastBeatHit = false
    
    return self
end

function Beat:generateBeats(duration)
    -- Generate simple beat array at regular intervals
    self.beats = {}
    local time = self.beatInterval
    while time <= duration do
        table.insert(self.beats, time)
        time = time + self.beatInterval
    end
end

function Beat:loadMusic(filepath)
    -- Try to load music file if provided
    local success = pcall(function()
        self.music = love.audio.newSource(filepath, "stream")
        self.music:setLooping(true)
    end)
    
    if success and self.music then
        local duration = self.music:getDuration()
        print("Loaded music: " .. filepath .. " (" .. math.floor(duration) .. " seconds)")
        
        -- Try to load beat file first (e.g., "music.beats.txt")
        local beatFile = filepath:gsub("(%.[^%.]+)$", ".beats.txt")
        if self:loadBeatsFromFile(beatFile) then
            print("Loaded beat markers from: " .. beatFile)
        else
            -- Fall back to generated beats
            self:generateBeats(duration)
            print("Using auto-generated beats at " .. math.floor(60 / self.beatInterval) .. " BPM")
        end
    else
        print("Warning: Could not load music file: " .. filepath)
        print("Game will continue without music.")
    end
end

function Beat:loadBeatsFromFile(filepath)
    -- Try to load beat timestamps from a text file
    local info = love.filesystem.getInfo(filepath)
    if not info then
        return false
    end
    
    local content = love.filesystem.read(filepath)
    if not content then
        return false
    end
    
    self.beats = {}
    for line in content:gmatch("[^\r\n]+") do
        -- Skip comments and empty lines
        line = line:match("^%s*(.-)%s*$")  -- trim whitespace
        if line ~= "" and not line:match("^#") then
            local time = tonumber(line)
            if time then
                table.insert(self.beats, time)
            end
        end
    end
    
    if #self.beats > 0 then
        table.sort(self.beats)  -- Ensure beats are in order
        return true
    end
    
    return false
end

function Beat:getCurrentTime()
    return self.currentTime
end

function Beat:playMusic()
    if self.music and not self.musicPlaying then
        love.audio.play(self.music)
        self.musicPlaying = true
    end
end

function Beat:stopMusic()
    if self.music and self.musicPlaying then
        love.audio.stop(self.music)
        self.musicPlaying = false
    end
end

function Beat:update(dt)
    -- Sync with music playback position if available
    if self.music and self.musicPlaying then
        self.currentTime = self.music:tell()
    else
        self.currentTime = self.currentTime + dt
    end
    
    -- Check if we've reached the next beat
    if self.nextBeatIndex <= #self.beats then
        local nextBeatTime = self.beats[self.nextBeatIndex]
        if self.currentTime >= nextBeatTime then
            self:triggerBeat()
            self.nextBeatIndex = self.nextBeatIndex + 1
        end
    else
        -- Loop beats if we've gone through all of them
        self.nextBeatIndex = 1
    end
    
    -- Update beat indicator timer
    if self.beatActive then
        self.beatTimer = self.beatTimer + dt
        if self.beatTimer >= self.beatActiveDuration then
            self.beatActive = false
            self.beatTimer = 0
        end
    end
end

function Beat:triggerBeat()
    self.beatActive = true
    self.beatTimer = 0
    self.lastBeatHit = false
end

function Beat:checkBeatHit(playerOnWave)
    -- Check if player is on wave during active beat window
    if self.beatActive and playerOnWave and not self.lastBeatHit then
        self.score = self.score + 1
        self.lastBeatHit = true
        return true
    end
    return false
end

function Beat:draw()
    local screenWidth = love.graphics.getWidth()
    
    -- Draw beat indicator at top of screen
    if self.beatActive then
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow when active
        love.graphics.circle("fill", screenWidth / 2, 30, 20)
        
        -- Flash effect
        local alpha = 1 - (self.beatTimer / self.beatActiveDuration)
        love.graphics.setColor(1, 1, 0, alpha * 0.5)
        love.graphics.circle("fill", screenWidth / 2, 30, 30)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)  -- Gray when inactive
        love.graphics.circle("line", screenWidth / 2, 30, 20)
    end
    
    -- Draw score
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Score: " .. self.score, screenWidth / 2 - 30, 60)
    
    -- Debug: show current time and next beat
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(string.format("Time: %.2f", self.currentTime), 10, 10)
    if self.nextBeatIndex <= #self.beats then
        love.graphics.print(string.format("Next Beat: %.2f", self.beats[self.nextBeatIndex]), 10, 30)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Beat

