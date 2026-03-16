-----------------------------------------------------------------------------------------
-- Classic Prot Warrior

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WAR", "ff6666", "WARRIOR-3")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "battleshout",

    "- Debuffs -",
    "rend",
    "demoshout",

    "- Spells -",
    "charge",
    "clap",
    "revenge",
    "bloodrage",
})

spec.calcState = function(state)
    -- Buffs --

    if Faceroll.getDotRemainingNorm("Rend") > 0.1 then
        state.rend = true
    end
    if Faceroll.getDotRemainingNorm("Demoralizing Sout") > 0.1 then
        state.demoshout = true
    end

    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Thunder Clap") then
        state.clap = true
    end
    if Faceroll.isSpellAvailable("Revenge") then
        state.revenge = true
    end
    if Faceroll.isSpellAvailable("Bloodrage") then
        state.bloodrage = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "strike",
    "charge",
    "rend",
    "clap",
    "bloodrage",
    "demoshout",
    "revenge",
    "cleave",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        -- if state.bloodrage then
        --     return "bloodrage"

        if state.charge and not state.melee then
            return "charge"

        elseif state.rage >= 20 and state.melee and state.clap then
            return "clap"

        elseif state.rage >= 10 and state.melee and not state.demoshout then
            return "demoshout"

        elseif state.melee and state.revenge then
            return "revenge"

        -- elseif state.rage >= 10 and not state.rend then
        --     return "rend"

        elseif aoe then
            return "cleave"
        else
            return "strike"
        end
    end
end
