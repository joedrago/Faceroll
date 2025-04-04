-----------------------------------------------------------------------------------------
-- Discipline Priest

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local harmfultarget = bitand(bits, 0x1)
    local helpfultarget = bitand(bits, 0x2)
    local needsatonement = bitand(bits, 0x4)
    local penance = bitand(bits, 0x8)
    local pwshield = bitand(bits, 0x10)
    local mindblast = bitand(bits, 0x20)
    local mindbender = bitand(bits, 0x40)
    local needspain = bitand(bits, 0x80)

    if action == ACTION_Q then
        -- Single Target

        if helpfultarget > 0 then
            -- Healing

            if pwshield > 0 then
                return press("0", "pw shield")
            elseif penance > 0 then
                return press("9", "penance")
            else
                return press("-", "flash heal")
            end
        elseif harmfultarget > 0 then
            -- DPS

            if needsatonement > 0 then
                return press("7", "atonement")
            elseif needspain > 0 then
                return press("=", "sw pain")
            elseif mindbender > 0 then
                return press("pad8", "mindbender")
            elseif mindblast > 0 then
                return press("pad7", "mind blast")
            elseif penance > 0 then
                return press("9", "penance")
            else
                return press("8", "smite")
            end
        end

    elseif action == ACTION_E then
        -- AOE

        if helpfultarget > 0 then
            -- Healing

            if pwshield > 0 then
                return press("0", "pw shield")
            elseif penance > 0 then
                return press("9", "penance")
            else
                return press("-", "flash heal")
            end
        elseif harmfultarget > 0 then
            -- DPS

            if needsatonement > 0 then
                return press("7", "atonement")
            elseif needspain > 0 then
                return press("=", "sw pain")
            elseif mindbender > 0 then
                return press("pad8", "mindbender")
            elseif mindblast > 0 then
                return press("pad7", "mind blast")
            elseif penance > 0 then
                return press("9", "penance")
            else
                return press("8", "smite")
            end
        end

    end

    return nil
end

return nextAction
