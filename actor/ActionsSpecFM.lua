-----------------------------------------------------------------------------------------
-- Frost Mage

local function press(button, name)
    print("Press: " .. name)
    return button
end

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
    local longcooldownsAE = bitand(bits, 0x200)
    local longcooldownsST = bitand(bits, 0x400)
    local frostfireempowerment = bitand(bits, 0x800)
    local blizzard = bitand(bits, 0x1000)
    local icyveins = bitand(bits, 0x2000)
    local coneofcoldnow = bitand(bits, 0x4000)
    local coneofcoldlong = bitand(bits, 0x8000)
    local justcastcometstorm = bitand(bits, 0x10000)

    if action == ACTION_Q then
        -- Single Target

        if icyveins > 0 then
            --  Glacial Spike if Comet Storm is not ready
            return "pad8" -- icy veins

        elseif flurry > 0 and (winterschill == 0 or (excessfire > 0 and excessfrost > 0)) then
            -- Cast Flurry if available and Winter's Chill is not on the target,
            -- or you have both Excess Fire and Excess Frost.
            return "=" -- flurry

        elseif cometstorm > 0 then
            -- Comet Storm
            return "-" -- comet storm

        elseif glacialspike > 0 then
            --  Glacial Spike.
            return "pad7" -- glacial spike

        elseif frozenorb > 0 then
            -- Frozen Orb
            return "0" -- frozen orb

        elseif shiftingpower > 0 and (longcooldownsAE > 0 or longcooldownsST > 0) then
            -- Cast Shifting Power if Icy Veins and Comet Storm have more than
            -- 10 seconds remaining on their cooldowns.
            return "9" -- shifting power

        elseif fingersoffrost > 0 or winterschill > 0 then
            -- Cast Ice Lance if you have Fingers of Frost available or there is
            -- Winter's Chill on the target.
            return "8" -- ice lance

        else
            -- Frostfire Bolt
            return "7" -- frostfire bolt
        end

    elseif action == ACTION_E then
        -- AOE

        if icyveins > 0 then
            --  Glacial Spike if Comet Storm is not ready
            return press("pad8", "icy veins")

        elseif coneofcoldnow > 0 and justcastcometstorm > 0 then
            -- Cast Cone of Cold directly after a Comet Storm.
            return press("f7", "cone of cold")

        elseif frozenorb > 0 then
            -- Frozen Orb
            return press("0", "frozen orb")

        elseif blizzard > 0 then
            --  Cast Blizzard.
            return press("f8", "blizzard")

        elseif cometstorm > 0 and (coneofcoldnow > 0 or coneofcoldlong > 0) then
            -- Cast Comet Storm if Cone of Cold has more than 10 seconds left on
            -- its cooldown, or Cone of Cold is ready to combo with.
            return press("-", "comet storm")

        elseif glacialspike > 0 then
            --  Glacial Spike.
            return press("pad7", "glacial spike")

        elseif flurry > 0 and (winterschill == 0 or (excessfire > 0 and excessfrost > 0)) then
            -- Cast Flurry if available and Winter's Chill is not on the target,
            -- or you have both Excess Fire and Excess Frost.
            return press("=", "flurry")

        elseif frostfireempowerment > 0 and excessfire == 0 then
            -- Cast Frostfire Bolt with Frostfire Empowerment if you do not have
            -- Excess Fire.
            return press("7", "frostfire bolt")

        elseif shiftingpower > 0 and longcooldownsAE > 0 then
            -- Cast Shifting Power if Icy Veins and Comet Storm have more than
            -- 10 seconds remaining on their cooldowns.
            return press("9", "shifting power")

        elseif fingersoffrost > 0 or winterschill > 0 then
            -- Cast Ice Lance if you have Fingers of Frost available or there is
            -- Winter's Chill on the target.
            return press("8", "ice lance")

        else
            -- Frostfire Bolt
            return press("7", "frostfire bolt")
        end
    end

    return nil
end

return nextAction
