local utils = {}

-- Clamp a value between min and max
function utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation between a and b by t (0 to 1)
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Check if two values are within tolerance of each other
function utils.withinTolerance(a, b, tolerance)
    return math.abs(a - b) <= tolerance
end

-- Check collision between player (circle) and wave point
function utils.checkPlayerWaveCollision(playerX, playerY, playerRadius, waveY, tolerance)
    local distance = math.abs(playerY - waveY)
    return distance <= (playerRadius + tolerance)
end

return utils

