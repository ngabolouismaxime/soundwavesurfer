local Wave = {}
Wave.__index = Wave

function Wave.new()
    local self = setmetatable({}, Wave)
    
    -- Wave properties
    self.baseAmplitude = 100     -- Base height of the wave
    self.amplitude = 100         -- Current height (modulated by audio)
    self.frequency = 0.01        -- Wave frequency
    self.scrollSpeed = 150       -- Pixels per second
    self.offset = 0              -- Horizontal scroll offset
    self.baseY = 300             -- Center line of the wave (middle of screen)
    
    -- Store wave points for collision detection
    self.points = {}
    self.numPoints = 100         -- Number of points to sample across screen
    
    -- Audio-reactive data
    self.amplitudeData = nil     -- Array of {time, amplitude} pairs
    self.currentTime = 0         -- Current playback time
    self.audioReactive = false   -- Whether audio data is loaded
    self.targetAmplitude = 100   -- Target amplitude (for smoothing)
    self.amplitudeSmoothSpeed = 12  -- How fast amplitude changes (higher = more responsive)
    
    return self
end

function Wave:loadAmplitudeData(filepath)
    -- Try to load amplitude envelope from file
    local info = love.filesystem.getInfo(filepath)
    if not info then
        return false
    end
    
    local content = love.filesystem.read(filepath)
    if not content then
        return false
    end
    
    self.amplitudeData = {}
    for line in content:gmatch("[^\r\n]+") do
        -- Skip comments and empty lines
        line = line:match("^%s*(.-)%s*$")  -- trim whitespace
        if line ~= "" and not line:match("^#") then
            -- Parse time,amplitude pairs
            local time, amp = line:match("([%d%.]+),([%d%.]+)")
            if time and amp then
                table.insert(self.amplitudeData, {
                    time = tonumber(time),
                    amplitude = tonumber(amp)
                })
            end
        end
    end
    
    if #self.amplitudeData > 0 then
        self.audioReactive = true
        print("Loaded " .. #self.amplitudeData .. " amplitude samples from: " .. filepath)
        return true
    end
    
    return false
end

function Wave:setCurrentTime(time)
    self.currentTime = time
    
    -- Update target amplitude based on current time
    if self.audioReactive and self.amplitudeData then
        local amp = self:getAmplitudeAtTime(time)
        -- Blend between base wave and audio-reactive amplitude
        -- Use audio data to modulate the wave height (50-200% of base)
        self.targetAmplitude = self.baseAmplitude * (0.5 + amp * 1.5)
    end
end

function Wave:getAmplitudeAtTime(time)
    if not self.amplitudeData or #self.amplitudeData == 0 then
        return 1.0
    end
    
    -- Binary search to find the closest time point
    local left, right = 1, #self.amplitudeData
    
    -- Handle edge cases
    if time <= self.amplitudeData[1].time then
        return self.amplitudeData[1].amplitude
    end
    if time >= self.amplitudeData[right].time then
        return self.amplitudeData[right].amplitude
    end
    
    -- Binary search
    while left < right - 1 do
        local mid = math.floor((left + right) / 2)
        if self.amplitudeData[mid].time <= time then
            left = mid
        else
            right = mid
        end
    end
    
    -- Linear interpolation between two closest points
    local t1 = self.amplitudeData[left].time
    local t2 = self.amplitudeData[right].time
    local a1 = self.amplitudeData[left].amplitude
    local a2 = self.amplitudeData[right].amplitude
    
    local factor = (time - t1) / (t2 - t1)
    return a1 + (a2 - a1) * factor
end

function Wave:update(dt)
    -- Scroll the wave from right to left
    self.offset = self.offset + self.scrollSpeed * dt
    
    -- Smoothly interpolate amplitude towards target
    if self.audioReactive then
        local diff = self.targetAmplitude - self.amplitude
        self.amplitude = self.amplitude + diff * self.amplitudeSmoothSpeed * dt
    end
    
    -- Generate wave points for current frame
    self:generatePoints()
end

function Wave:generatePoints()
    self.points = {}
    local screenWidth = love.graphics.getWidth()
    local step = screenWidth / self.numPoints
    
    for i = 0, self.numPoints do
        local x = i * step
        local y = self:getWaveY(x)
        table.insert(self.points, {x = x, y = y})
    end
end

-- Calculate wave Y position at a given X coordinate
function Wave:getWaveY(x)
    local waveX = x + self.offset
    local y = self.baseY + math.sin(waveX * self.frequency) * self.amplitude
    return y
end

-- Get wave Y at a specific X position (used for collision)
function Wave:getYAtX(x)
    return self:getWaveY(x)
end

function Wave:draw()
    love.graphics.setColor(0.2, 0.6, 1.0, 1.0)  -- Blue wave
    love.graphics.setLineWidth(3)
    
    -- Draw the wave using the points
    if #self.points > 1 then
        for i = 1, #self.points - 1 do
            love.graphics.line(
                self.points[i].x, self.points[i].y,
                self.points[i + 1].x, self.points[i + 1].y
            )
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Wave

