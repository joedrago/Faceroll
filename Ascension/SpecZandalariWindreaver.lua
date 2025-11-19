-----------------------------------------------------------------------------------------
-- Ascension WoW Zandalari Windreaver

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ZW", "ffff66", "HERO-Zandalari Windreaver")

spec.melee = "Slam"
spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({

    "- Abilities -",
    "glaive",
    "loa",
})

spec.calcState = function(state)
    -- Buffs
    -- if Faceroll.getBuffRemaining("Slice and Dice") > 2 then
    --     state.sliceanddice = true
    -- end

    -- Abilities
    if Faceroll.isSpellAvailable("Zandalari Glaive") then
        state.glaive = true
    end
    if Faceroll.isSpellAvailable("Loa's Assault") then
        state.loa = true
    end
    -- if Faceroll.isSpellAvailable("Execute") and state.rage >= 13 then
    --     state.execute = true
    -- end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "toss",
    "deadlythrow",
    "glaive",
    "loa",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if state.loa then
            return "loa"

        elseif state.glaive then
            return "glaive"

        elseif state.combopoints >= 5 then
            return "deadlythrow"

        else
            return "toss"

        end
    end

    return nil
end
