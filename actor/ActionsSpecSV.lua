-----------------------------------------------------------------------------------------
-- Survival Hunter

local function nextAction(action, bits)
    local lunarstorm = bitand(bits, 0x1)
    local strikeitrich = bitand(bits, 0x2)
    local tipofthespear = bitand(bits, 0x4)
    local wildfirebomb2 = bitand(bits, 0x8)
    local wildfirebomb1 = bitand(bits, 0x10)
    local butchery = bitand(bits, 0x20)
    local killcommand = bitand(bits, 0x40)
    local explosiveshot = bitand(bits, 0x80)
    local killshot = bitand(bits, 0x100)
    local furyoftheeagle = bitand(bits, 0x200)
    local highfocus = bitand(bits, 0x400)

    if action == ACTION_Q then
        -- Single Target

        if lunarstorm > 0 and wildfirebomb1 > 0 then
            -- Cast Wildfire Bomb to trigger Lunar Storm whenever it is not on
            -- cooldown, regardless of Tip of the Spear.
            return "7" -- wildfire bomb

        elseif strikeitrich > 0 and tipofthespear == 0 and killcommand > 0 then
            -- Cast Raptor Strike (or Mongoose Bite) with Tip of the Spear to
            -- consume Strike it Rich. If you do not have Tip of the Spear, you
            -- can use Kill Command without regard for focus to bruteforce
            -- getting one quick. This is virtually equal DPS but can be useful
            -- when bursting down a priority target.
            return "8" -- kill command

        elseif strikeitrich > 0 and tipofthespear == 1 then
            -- Cast Raptor Strike (or Mongoose Bite) with Tip of the Spear to
            -- consume Strike it Rich.
            return "9" -- raptor strike

        elseif wildfirebomb2 > 0 then
            -- Cast Wildfire Bomb with or without Tip of the Spear if you have 2
            -- charges of Wildfire Bomb, or if you are about to use Coordinated
            -- Assault.
            return "7" -- wildfire bomb

        elseif wildfirebomb1 > 0 and tipofthespear > 0 then
            -- Cast Wildfire Bomb with Tip of the Spear if you have ~1.7+
            -- charges of Wildfire Bomb.
            return "7" -- wildfire bomb

        elseif butchery > 0 then
            -- Cast Butchery to apply Merciless Blow.
            return "0" -- butchery

        elseif furyoftheeagle > 0 and tipofthespear > 0 then
            -- Cast Fury of the Eagle if you have a Tip of the Spear stack to
            -- spend, and you won't need Fury of the Eagle for AoE in the near
            -- future.
            return "-" -- fury of the eagle

        elseif killcommand > 0 and highfocus == 0 then
            -- Cast Kill Command if you will not over-cap the Focus it
            -- generates.
            return "8" -- kill command

        elseif wildfirebomb1 > 0 and tipofthespear > 0 then
            -- Cast Wildfire Bomb if you have a Tip of the Spear stack to spend,
            -- and if you will have at least 1 charge left by the time the
            -- cooldown of Lunar Storm ends.
            return "7" -- wildfire bomb

        elseif killshot > 0 then
            -- Cast Kill Shot.
            return "=" -- kill shot

        elseif explosiveshot > 0 then
            -- Cast Explosive Shot.
            return "pad7" -- explosive shot

        else
            -- Cast Raptor Strike(or Mongoose Bite).
            return "9" -- raptor strike
        end

    elseif action == ACTION_E then
        -- AOE

        if (lunarstorm > 0 and wildfirebomb1 > 0) or wildfirebomb2 > 0 then
            -- Cast Wildfire Bomb Under any of the following cirumstances:
            -- - To trigger Lunar Storm whenever it is not on cooldown.
            -- - If you have 2 charges of Wildfire Bomb.
            return "7" -- wildfire bomb

        elseif strikeitrich > 0 then
            -- Cast Raptor Strike to consume Strike it Rich.
            return "9" -- raptor strike

        elseif butchery > 0 then
            -- Cast Butchery.
            return "0" -- butchery

        elseif furyoftheeagle > 0 and tipofthespear > 0 then
            -- Cast Fury of the Eagle if you have a Tip of the Spear stack to
            -- spend.
            return "-" -- fury of the eagle

        elseif killcommand > 0 and highfocus == 0 then
            -- Cast Kill Command if you will not over-cap the Focus it
            -- generates.
            return "8" -- kill command

        elseif explosiveshot > 0 then
            -- Cast Explosive Shot.
            return "pad7" -- explosive shot

        elseif wildfirebomb1 > 0 and tipofthespear > 0 then
            -- Cast Wildfire Bomb if you have a Tip of the Spear stack to spend.
            return "7" -- wildfire bomb

        else
            -- Cast Raptor Strike(or Mongoose Bite).
            return "9" -- raptor strike
        end
    end
    return nil
end

return nextAction
