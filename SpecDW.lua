-----------------------------------------------------------------------------------------
-- Destruction Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DW", "FF81FF", "WARLOCK-3")

spec.buffs = {
    "Decimation",
    "Ritual of Ruin",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Buffs -",
    "decimation",
    "ritualofruin",

    "- Dots -",
    "witherdot",
    "conflagratedot",

    "- Spells -",
    "conflagrateready",
    "cdfready",
    "malevolenceready",
    "cataclysmready",
    "cataclysmsoon",
    "cataclysmjustcast",

    "- Resources -",
    "shardsG37",

    "- State -",
    "chaosboltdeadzone",
}

local chaosboltDeadzone = Faceroll.deadzoneCreate("Chaos Bolt", 0.5, 1)

spec.calcState = function(state)
    if Faceroll.isBuffActive("Decimation") then
        state.decimation = true
    end
    if Faceroll.isBuffActive("Ritual of Ruin") then
        state.ritualofruin = true
    end

    if not state.ritualofruin then
        -- the only time we DONT want to chaos bolt multiple times in a row is
        -- if the next one is free!
        Faceroll.deadzoneUpdate(chaosboltDeadzone)
    end
    if Faceroll.deadzoneActive(chaosboltDeadzone) then
        state.chaosboltdeadzone = true
    end

    if Faceroll.isDotActive("Wither") > 0.3 then
        state.witherdot = true
    end
    if Faceroll.isDotActive("Conflagrate") > 0.2 then
        state.conflagratedot = true
    end

    if Faceroll.isSpellAvailable("Conflagrate") then
        state.conflagrateready = true
    end

    if Faceroll.isSpellAvailable("Channel Demonfire") then
        state.cdfready = true
    end

    if Faceroll.isSpellAvailable("Malevolence") then
        state.malevolenceready = true
    end

    if Faceroll.isSpellAvailable("Cataclysm") then
        state.cataclysmready = true
    end

    if Faceroll.spellCooldown("Cataclysm") < 3 then
        state.cataclysmsoon = true
    end

    if Faceroll.spellCooldown("Cataclysm") > 25 then
        state.cataclysmjustcast = true
    end

    -- divide by 10 to get the number of actual shards
    local soulShardFragments = UnitPower("player", Enum.PowerType.SoulShards, true)
    if soulShardFragments > 37 then
        state.shardsG37 = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "wither",
    "chaosbolt",
    "incinerate",
    "conflagrate",
    "soulfire",
    "cdf",
    "cataclysm",
    "rainoffire",
    "malevolence",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.witherdot then
            return "wither"

        elseif state.malevolenceready then
            return "malevolence"

        elseif state.shardsG37 and not state.chaosboltdeadzone then
            return "chaosbolt"

        elseif state.decimation and state.conflagratedot then
            return "soulfire"

        elseif state.cdfready and state.conflagratedot then
            return "cdf"

        elseif not state.conflagratedot and state.conflagrateready then
            return "conflagrate"

        else
            return "incinerate"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.cataclysmready then
            return "cataclysm"

        elseif state.malevolenceready and state.cataclysmjustcast then
            return "malevolence"

        elseif state.decimation and state.conflagratedot then
            return "soulfire"

        elseif state.shardsG37 then
            return "rainoffire"

        elseif state.cdfready and state.conflagratedot and not state.cataclysmsoon then
            return "cdf"

        elseif not state.conflagratedot and state.conflagrateready then
            return "conflagrate"

        else
            return "incinerate"

        end

    end

    return nil
end
