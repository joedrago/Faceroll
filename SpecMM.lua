-----------------------------------------------------------------------------------------
-- Marksmanship Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MM", "88aa00", "HUNTER-2")

spec.buffs = {
    "Trick Shots",
    "Streamline",
    "Precise Shots",
    "Spotter's Mark",
    "Moving Target",
}

spec.abilities = {
    "multishot",
    "rapidfire",
    "aimedshot",
    "explosiveshot",
    "steadyshot",
    "killshot",
    "arcaneshot",
}

local bits = Faceroll.createBits({
    "trickshots",
    "streamline",
    "preciseshots",
    "spottersmark",
    "movingtarget",
    "aimedshot",
    "rapidfire",
    "explosiveshot",
    "killshot",
    "lowfocus",
    "streamlinedeadzone",
})

local streamlineDeadzone = Faceroll.deadzoneCreate("Aimed Shot", 0.3, 0.5)

spec.calcBits = function()
    bits:reset()

    if Faceroll.isBuffActive("Trick Shots") then
        bits:enable("trickshots")
    end
    if Faceroll.isBuffActive("Streamline") then
        bits:enable("streamline")
        Faceroll.deadzoneUpdate(streamlineDeadzone)
    end
    if Faceroll.isBuffActive("Precise Shots") then
        bits:enable("preciseshots")
    end
    if Faceroll.isBuffActive("Spotter's Mark") then
        bits:enable("spottersmark")
    end
    if Faceroll.isBuffActive("Moving Target") then
        bits:enable("movingtarget")
    end
    if Faceroll.isSpellAvailable("Aimed Shot") then
        bits:enable("aimedshot")
    end
    if Faceroll.isSpellAvailable("Rapid Fire") then
        bits:enable("rapidfire")
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        bits:enable("explosiveshot")
    end
    if Faceroll.isSpellAvailable("Kill Shot") then
        bits:enable("killshot")
    end
    if UnitPower("player") < 30 then
        bits:enable("lowfocus")
    end

    if Faceroll.deadzoneActive(streamlineDeadzone) then
        bits:enable("streamlinedeadzone")
    end

    if Faceroll.debug then
        local o = ""
        local dztext = "F"
        if Faceroll.deadzoneActive(streamlineDeadzone) then
            dztext = "T"
        end
        o = o .. "Aimed Deadzone   :\n"
        o = o .. "active           : " .. dztext .. "\n"
        o = o .. "spellName        : " .. streamlineDeadzone.spellName .. "\n"
        o = o .. "castTimeRemaining: " .. streamlineDeadzone.castTimeRemaining .. "\n"
        o = o .. "duration         : " .. streamlineDeadzone.duration .. "\n"
        o = o .. "endTime          : " .. streamlineDeadzone.endTime .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
        -- Single Target

        if state.preciseshots and state.killshot then
            -- Use Kill Shot when you have a Precise Shots stack.
            return "killshot"

        elseif state.lowfocus and state.rapidfire then
            -- prioritize rapid fire a bit higher here for some quick focus
            return "rapidfire"

        elseif state.lowfocus then
            -- We're super low on focus and don't have rapid fire, just steady shot once
            return "steadyshot"

        elseif state.preciseshots and not state.spottersmark and not state.movingtarget then
            -- Spend Precise Shots stacks with Arcane Shot, which generates
            -- Streamline to reduce Aimed Shot’s cast time and Focus cost. You
            -- should skip this line if you either have a Spotter's Mark proc,
            -- or you already have Moving Target from having spent Precise Shots
            -- previously.
            return "arcaneshot"

        elseif state.rapidfire then
            -- Cast Rapid Fire on cooldown to generate Streamline, Deathblow,
            -- Precise Shots (if No Scope is specced), and In the Rhythm. It
            -- also activates Lunar Storm. Delay it for up to 7 seconds if Lunar
            -- Storm is coming off cooldown soon, in order to activate the Lunar
            -- Storm the moment it becomes available.
            return "rapidfire"

        elseif state.aimedshot and state.streamline and not state.streamlinedeadzone then
            -- Use Aimed Shot as often as you can. Most of the time, we want to
            -- get rid of our Precise Shots stacks first, but if you have both a
            -- Spotter's Mark proc and  Moving Target up, you should just cast
            -- Aimed Shot regardless.
            return "aimedshot"

        elseif state.explosiveshot then
            -- Use Explosive Shot whenever possible.
            return "explosiveshot"

        else
            -- Use Steady Shot as a Focus generator when no other abilities are
            -- available. Each cast gives 20 Focus, so avoid casting multiple
            -- times in a row if you risk Focus capping.
            return "steadyshot"
        end

    elseif action == Faceroll.ACTION_AOE then
        -- AOE

        if state.lowfocus then
            -- We're super low on focus and don't want to spend rapid fire without trickshots, just steady shot once
            return "steadyshot"

        elseif not state.trickshots or (state.preciseshots and not state.spottersmark and not state.movingtarget) then
            -- You should use Multi-Shot to activate Trick Shots if it is down.
            -- You should also use it to spend Precise Shots stacks, but only if
            -- you do not have both Spotter's Mark and Moving Target active. If
            -- we have either of these buffs, we can just cast Aimed Shot,
            -- provided we have a Trick Shots.
            return "multishot"

        elseif state.rapidfire then
            -- Cast Rapid Fire on cooldown to generate Streamline, Deathblow,
            -- Precise Shots (if No Scope is specced), and In the Rhythm. It
            -- also activates Lunar Storm. Delay it for up to 7 seconds if Lunar
            -- Storm is coming off cooldown soon, in order to activate the Lunar
            -- Storm the moment it becomes available. You should ensure that
            -- Trick Shots is active before you cast it, and ideally with more
            -- uptime remaining than the channel time (2s).
            return "rapidfire"

        elseif state.explosiveshot then
            -- Use Explosive Shot whenever possible.
            return "explosiveshot"

        elseif state.aimedshot and state.streamline and not state.streamlinedeadzone then
            -- Use Aimed Shot as often as you can. Most of the time, we want to
            -- get rid of our Precise Shots stacks first, but if you have both a
            -- Spotter's Mark proc and  Moving Target up, you should just cast
            -- Aimed Shot regardless. Of course, we should always make sure to
            -- apply Trick Shots first.
            return "aimedshot"

        else
            -- Cast Steady Shot as a filler and Focus generator, when nothing
            -- higher in the priority list is available.
            return "steadyshot"
        end
    end

    return nil
end

Faceroll.registerSpec(spec)
