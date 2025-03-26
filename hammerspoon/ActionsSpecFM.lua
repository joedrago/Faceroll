-----------------------------------------------------------------------------------------
-- Frost Mage

local function nextAction(action, bits)
    local winterschill = bitand(bits, 0x1)
    local fingersoffrost = bitand(bits, 0x2)
    local excessfire = bitand(bits, 0x4)
    local excessfrost = bitand(bits, 0x8)
    local glacialspike = bitand(bits, 0x10)
    local frozenorb = bitand(bits, 0x20)
    local cometstorm = bitand(bits, 0x40)
    local flurry = bitand(bits, 0x80)
    local shiftingpower = bitand(bits, 0x100)

    if action == ACTION_Q then
        -- Single Target

        if glacialspike > 0 and cometstorm == 0 then
            --  Glacial Spike if Comet Storm is not ready
            return "pad7" -- flurry

        elseif flurry > 0 and winterschill == 0 then
            -- Flurry if Excess Fire and Excess Frost are both active
            return "=" -- flurry

        elseif flurry > 0 and excessfire > 0 and excessfrost > 0 then
            -- Flurry if Excess Fire and Excess Frost are both active
            return "=" -- flurry

        elseif cometstorm > 0 then
            -- Comet Storm
            return "-" -- comet storm

        elseif frozenorb > 0 then
            -- Frozen Orb
            return "0" -- frozen orb

        elseif shiftingpower > 0 and cometstorm == 0 then
            -- Shifting Power if cooldowns are not ready
            return "9" -- shifting power

        elseif winterschill > 0 or fingersoffrost > 0 then
            -- Ice Lance if Winter's Chill is or Fingers of Frost is active
            return "8" -- ice lance

        else
            -- Frostfire Bolt
            return "7" -- frostfire bolt
        end

    elseif action == ACTION_E then
        -- AOE

        -- Frostfire Bolt
        return "7" -- frostfire bolt
    end

    return nil
end

return nextAction
