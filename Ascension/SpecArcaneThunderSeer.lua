-----------------------------------------------------------------------------------------
-- Ascension WoW Arcane Thunder Seer

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ATS", "ffaaff", "HERO-Arcane Thunder Seer")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Combat -",
    "moonkinform",
    "targetingenemy",
    "combat",

    "- Abilities -",
    "chainlightning",
    "arcaneorb",

    "- Buffs -",
    "arcaneoverload",

    "- Dots -",
    "moonfiredot",
}

spec.calcState = function(state)
    -- Combat
    state.moonkinform = Faceroll.inShapeshiftForm("Moonkin Form")
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end

    -- Abilities
    if Faceroll.isSpellAvailable("Chain Lightning") then
        state.chainlightning = true
    end
    if Faceroll.isSpellAvailable("Arcane Orb") then
        state.arcaneorb = true
    end

    -- Buffs
    if Faceroll.isBuffActive("Arcane Overload") then
        state.arcaneoverload = true
    end

    -- Dots
    if Faceroll.isDotActive("Moonfire") >= 0.1 then
        state.moonfiredot = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "moonfire",
    "lightningbolt",
    "arcanemissiles",
    "chainlightning",
    "moonkinform",
    "arcaneorb",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        if not state.moonkinform then
            return "moonkinform"
        end

        if state.targetingenemy then
            if state.arcaneoverload then
                if state.chainlightning then
                    return "chainlightning"
                else
                    return "lightningbolt"
                end
            elseif state.arcaneorb then
                return "arcaneorb"
            elseif not state.moonfiredot then
                return "moonfire"
            else
                return "arcanemissiles"

            end
        end
    end
    return nil
end
