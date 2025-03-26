-----------------------------------------------------------------------------------------
-- Marksmanship Hunter

local function nextAction(action, bits)
    local trickShots = bitand(bits, 0x1)
    local streamline = bitand(bits, 0x2)
    local preciseshots = bitand(bits, 0x4)
    local spottersmark = bitand(bits, 0x8)
    local movingtarget = bitand(bits, 0x10)
    local aimedshot = bitand(bits, 0x20)
    local rapidfire = bitand(bits, 0x40)
    local explosiveshot = bitand(bits, 0x80)
    local killshot = bitand(bits, 0x100)
    local lowfocus = bitand(bits, 0x200)

    if action == ACTION_Q then
        -- Single Target

        if (preciseshots > 0) and (killshot > 0) then
            -- Use Kill Shot when you have a Precise Shots stack.
            return "=" -- kill shot

        elseif lowfocus > 0 and rapidfire > 0 then
            -- prioritize rapid fire a bit higher here for some quick focus
            return "8" -- rapid fire

        elseif lowfocus > 0 then
            -- We're super low on focus and don't have rapid fire, just steady shot once
            return "-" -- steady shot

        elseif (preciseshots > 0) and (spottersmark == 0) and (movingtarget == 0) then
            -- Spend Precise Shots stacks with Arcane Shot, which generates
            -- Streamline to reduce Aimed Shot’s cast time and Focus cost. You
            -- should skip this line if you either have a Spotter's Mark proc,
            -- or you already have Moving Target from having spent Precise Shots
            -- previously.
            return "pad7" -- arcane shot

        elseif rapidfire > 0 then
            -- Cast Rapid Fire on cooldown to generate Streamline, Deathblow,
            -- Precise Shots (if No Scope is specced), and In the Rhythm. It
            -- also activates Lunar Storm. Delay it for up to 7 seconds if Lunar
            -- Storm is coming off cooldown soon, in order to activate the Lunar
            -- Storm the moment it becomes available.
            return "8" -- rapid fire

        elseif aimedshot > 0 and streamline > 0 then
            -- Use Aimed Shot as often as you can. Most of the time, we want to
            -- get rid of our Precise Shots stacks first, but if you have both a
            -- Spotter's Mark proc and  Moving Target up, you should just cast
            -- Aimed Shot regardless.
            return "9" -- aimed shot

        elseif explosiveshot > 0 then
            -- Use Explosive Shot whenever possible.
            return "0" -- explosive shot

        else
            -- Use Steady Shot as a Focus generator when no other abilities are
            -- available. Each cast gives 20 Focus, so avoid casting multiple
            -- times in a row if you risk Focus capping.
            return "-" -- steady shot
        end

    elseif action == ACTION_E then
        -- AOE

        if lowfocus > 0 then
            -- We're super low on focus and don't want to spend rapid fire without trickshots, just steady shot once
            return "-" -- steady shot

        elseif (trickShots == 0) or ((preciseshots > 0) and (spottersmark == 0) and (movingtarget == 0)) then
            -- You should use Multi-Shot to activate Trick Shots if it is down.
            -- You should also use it to spend Precise Shots stacks, but only if
            -- you do not have both Spotter's Mark and Moving Target active. If
            -- we have either of these buffs, we can just cast Aimed Shot,
            -- provided we have a Trick Shots.
            return "7" -- multishot

        elseif rapidfire > 0 then
            -- Cast Rapid Fire on cooldown to generate Streamline, Deathblow,
            -- Precise Shots (if No Scope is specced), and In the Rhythm. It
            -- also activates Lunar Storm. Delay it for up to 7 seconds if Lunar
            -- Storm is coming off cooldown soon, in order to activate the Lunar
            -- Storm the moment it becomes available. You should ensure that
            -- Trick Shots is active before you cast it, and ideally with more
            -- uptime remaining than the channel time (2s).
            return "8" -- rapid fire

        elseif explosiveshot > 0 then
            -- Use Explosive Shot whenever possible.
            return "0" -- explosive shot

        elseif aimedshot > 0 and streamline > 0 then
            -- Use Aimed Shot as often as you can. Most of the time, we want to
            -- get rid of our Precise Shots stacks first, but if you have both a
            -- Spotter's Mark proc and  Moving Target up, you should just cast
            -- Aimed Shot regardless. Of course, we should always make sure to
            -- apply Trick Shots first.
            return "9" -- aimed shot

        else
            -- Cast Steady Shot as a filler and Focus generator, when nothing
            -- higher in the priority list is available.
            return "-" -- steady shot
        end
    end
    return nil
end

return nextAction
