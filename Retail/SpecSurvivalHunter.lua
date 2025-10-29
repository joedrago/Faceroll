-----------------------------------------------------------------------------------------
-- Survival Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SV", "337733", "HUNTER-3")

spec.buffs = {
    { ["name"]="Lunar Storm", ["harmful"]=true },
    "Strike it Rich",
    "Tip of the Spear",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "lunarstorm",
    "strikeitrich",
    "tipofthespear",
    "wildfirebomb2",
    "wildfirebomb1",
    "butchery",
    "killcommand",
    "explosiveshot",
    "killshot",
    "furyoftheeagle",
    "highfocus",
}

spec.calcState = function(state)
    if not Faceroll.isBuffActive("Lunar Storm") then
        state.lunarstorm = true
    end
    if Faceroll.isBuffActive("Strike it Rich") then
        state.strikeitrich = true
    end
    if Faceroll.isBuffActive("Tip of the Spear") then
        state.tipofthespear = true
    end
    if Faceroll.getSpellCharges("Wildfire Bomb") >= 2 then
        state.wildfirebomb2 = true
    end
    if Faceroll.getSpellCharges("Wildfire Bomb") >= 1 then
        state.wildfirebomb1 = true
    end
    if Faceroll.isSpellAvailable("Butchery") then
        state.butchery = true
    end
    if Faceroll.isSpellAvailable("Kill Command") then
        state.killcommand = true
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        state.explosiveshot = true
    end
    if Faceroll.isSpellAvailable("Kill Shot") then
        state.killshot = true
    end
    if Faceroll.isSpellAvailable("Fury of the Eagle") then
        state.furyoftheeagle = true
    end
    if UnitPower("player") > 85 then
        state.highfocus = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "wildfirebomb",
    "killcommand",
    "raptorstrike",
    "butchery",
    "furyoftheeagle",
    "killshot",
    "explosiveshot",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.lunarstorm and state.wildfirebomb1 then
            -- Cast Wildfire Bomb to trigger Lunar Storm whenever it is not on
            -- cooldown, regardless of Tip of the Spear.
            return "wildfirebomb"

        elseif state.strikeitrich and not state.tipofthespear and state.killcommand then
            -- Cast Raptor Strike (or Mongoose Bite) with Tip of the Spear to
            -- consume Strike it Rich. If you do not have Tip of the Spear, you
            -- can use Kill Command without regard for focus to bruteforce
            -- getting one quick. This is virtually equal DPS but can be useful
            -- when bursting down a priority target.
            return "killcommand"

        elseif state.strikeitrich and tipofthespear == 1 then
            -- Cast Raptor Strike (or Mongoose Bite) with Tip of the Spear to
            -- consume Strike it Rich.
            return "raptorstrike"

        elseif state.wildfirebomb2 then
            -- Cast Wildfire Bomb with or without Tip of the Spear if you have 2
            -- charges of Wildfire Bomb, or if you are about to use Coordinated
            -- Assault.
            return "wildfirebomb"

        elseif state.wildfirebomb1 and state.tipofthespear then
            -- Cast Wildfire Bomb with Tip of the Spear if you have ~1.7+
            -- charges of Wildfire Bomb.
            return "wildfirebomb"

        elseif state.butchery then
            -- Cast Butchery to apply Merciless Blow.
            return "butchery"

        elseif state.furyoftheeagle and state.tipofthespear then
            -- Cast Fury of the Eagle if you have a Tip of the Spear stack to
            -- spend, and you won't need Fury of the Eagle for AoE in the near
            -- future.
            return "furyoftheeagle"

        elseif state.killcommand and not state.highfocus then
            -- Cast Kill Command if you will not over-cap the Focus it
            -- generates.
            return "killcommand"

        elseif state.wildfirebomb1 and state.tipofthespear then
            -- Cast Wildfire Bomb if you have a Tip of the Spear stack to spend,
            -- and if you will have at least 1 charge left by the time the
            -- cooldown of Lunar Storm ends.
            return "wildfirebomb"

        elseif state.killshot then
            -- Cast Kill Shot.
            return "killshot"

        elseif state.explosiveshot then
            -- Cast Explosive Shot.
            return "explosiveshot"

        else
            -- Cast Raptor Strike(or Mongoose Bite).
            return "raptorstrike"
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if (state.lunarstorm and state.wildfirebomb1) or state.wildfirebomb2 then
            -- Cast Wildfire Bomb Under any of the following cirumstances:
            -- - To trigger Lunar Storm whenever it is not on cooldown.
            -- - If you have 2 charges of Wildfire Bomb.
            return "wildfirebomb"

        elseif state.strikeitrich then
            -- Cast Raptor Strike to consume Strike it Rich.
            return "raptorstrike"

        elseif state.butchery then
            -- Cast Butchery.
            return "butchery"

        elseif state.furyoftheeagle and state.tipofthespear then
            -- Cast Fury of the Eagle if you have a Tip of the Spear stack to
            -- spend.
            return "furyoftheeagle"

        elseif state.killcommand and not state.highfocus then
            -- Cast Kill Command if you will not over-cap the Focus it
            -- generates.
            return "killcommand"

        elseif state.explosiveshot then
            -- Cast Explosive Shot.
            return "explosiveshot"

        elseif state.wildfirebomb1 and state.tipofthespear then
            -- Cast Wildfire Bomb if you have a Tip of the Spear stack to spend.
            return "wildfirebomb"

        else
            -- Cast Raptor Strike(or Mongoose Bite).
            return "raptorstrike"
        end
    end
    return nil
end
