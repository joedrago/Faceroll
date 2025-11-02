-----------------------------------------------------------------------------------------
-- Ascension WoW Dark Ranger

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DR", "aa66aa", "HERO-Dark Ranger")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Abilities -",
    "shadowarrow",
    "bloodarrow",
    "blackarrow",
    "explosiveshot",

    "- Buffs -",
    "shadowtrance",
    "artillery",

    "- Debuffs -",
    "pain",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoshot",
}

spec.calcState = function(state)
    if Faceroll.isSpellAvailable("Shadow Arrow") then
        state.shadowarrow = true
    end
    if Faceroll.isSpellAvailable("Blood Arrow") then
        state.bloodarrow = true
    end
    if Faceroll.isSpellAvailable("Black Arrow") then
        state.blackarrow = true
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        state.explosiveshot = true
    end

    if Faceroll.isBuffActive("Shadow Trance") then
        state.shadowtrance = true
    end
    if Faceroll.getBuffStacks("Shadow Shells") >= 3 then
        state.artillery = true
    end

    if Faceroll.isDotActive("Shadow Word: Pain") then
        state.pain = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    if IsCurrentSpell(75) then -- autoshot
        state.autoshot = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "shadowarrow",
    "bloodarrow",
    "shadowbolt",
    "artillery",
    "pain",
    "blackarrow",
    "explosiveshot",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if state.artillery then
            return "artillery"

        elseif state.shadowtrance then
            return "shadowbolt"

        elseif (mode == Faceroll.MODE_AOE) and state.explosiveshot then
            return "explosiveshot"

        elseif state.bloodarrow then
            return "bloodarrow"

        elseif state.blackarrow then
            return "blackarrow"

        elseif not state.pain then
            return "pain"

        elseif state.shadowarrow then
            return "shadowarrow"

        elseif state.explosiveshot then
            return "explosiveshot"

        end
    end

    return nil
end
