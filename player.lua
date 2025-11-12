local utils = require("utils")

local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    
    -- Position
    self.x = x or 150              -- Fixed X position (left side of screen)
    self.y = y or 300              -- Y position (starts at center)
    
    -- Physics
    self.velocityY = 0
    self.gravity = 800             -- Pixels per second squared
    self.jumpForce = -400          -- Negative = upward
    self.isGrounded = false
    
    -- Appearance
    self.radius = 15               -- Circle radius
    self.color = {r = 1, g = 0.3, b = 0.3}  -- Red player
    
    -- Collision
    self.collisionTolerance = 15   -- Pixels of tolerance for landing on wave
    
    return self
end

function Player:update(dt, wave)
    local wasGrounded = self.isGrounded
    local waveY = wave:getYAtX(self.x)
    
    -- If already grounded on the wave, stick to it (follow wave movement)
    if self.isGrounded then
        local waveMovement = waveY - self.y
        -- Allow player to follow wave up and down within reason
        if math.abs(waveMovement) < 150 then  -- Max 150 pixels of wave movement per frame
            self.y = waveY
            self.velocityY = 0
            -- Check if we're still close enough to stay grounded
            if not utils.withinTolerance(self.y, waveY, self.collisionTolerance * 4) then
                self.isGrounded = false
            end
        else
            -- Wave moved too far, player falls off
            self.isGrounded = false
        end
    end
    
    -- Apply gravity if not grounded
    if not self.isGrounded then
        self.velocityY = self.velocityY + self.gravity * dt
    end
    
    -- Update position
    self.y = self.y + self.velocityY * dt
    
    -- Check collision with wave (for landing)
    if not self.isGrounded and self.velocityY >= 0 then  -- Only when falling
        if utils.withinTolerance(self.y, waveY, self.collisionTolerance) then
            self.y = waveY
            self.velocityY = 0
            self.isGrounded = true
        end
    end
    
    -- Keep player on screen
    local screenHeight = love.graphics.getHeight()
    if self.y > screenHeight then
        self.y = screenHeight
        self.velocityY = 0
        self.isGrounded = true
    end
    
    if self.y < 0 then
        self.y = 0
        self.velocityY = 0
    end

    return not wasGrounded and self.isGrounded
end

function Player:jump()
    -- Can only jump if on ground or on wave
    if self.isGrounded then
        self.velocityY = self.jumpForce
        self.isGrounded = false
        return true
    end
    return false
end

function Player:isOnWave(wave)
    local waveY = wave:getYAtX(self.x)
    return utils.withinTolerance(self.y, waveY, self.collisionTolerance)
end

function Player:draw()
    -- Draw player as a circle
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, 1.0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Draw a small indicator if grounded
    if self.isGrounded then
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("line", self.x, self.y, self.radius + 3)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Player

