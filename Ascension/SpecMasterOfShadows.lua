-----------------------------------------------------------------------------------------
-- Ascension WoW Master of Shadows

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MOS", "777799", "HERO-Master of Shadows")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "energy35",
    "energy45",
    "cp3",
    "cp5",

    "- Abilities -",
    "shadowflame",

    "- Buffs -",
    "shadowtrance",
    "windfury",

    "- Dots -",
    "gloomblade",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    local energy = UnitPower("PLAYER", 3)
    local cp = GetComboPoints("PLAYER", "TARGET")

    if energy >= 35 then
        state.energy35 = true
    end
    if energy >= 45 then
        state.energy45 = true
    end

    if cp >= 3 then
        state.cp3 = true
    end
    if cp >= 5 then
        state.cp5 = true
    end

    if Faceroll.isSpellAvailable("Shadowflame") then
        state.shadowflame = true
    end

    if Faceroll.isBuffActive("Shadow Trance") then
        state.shadowtrance = true
    end
    if Faceroll.isBuffActive("Windfury Totem") then
        state.windfury = true
    end

    if Faceroll.getDotRemainingNorm("Gloomblade") > 0.25 then
        state.gloomblade = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end

    if IsSpellInRange("Gloomblade", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "attack",
    "sinisterstrike",
    "eviscerate",
    "shadowstep",
    "crimsontempest",
    "gloomblade",
    "shadowbolt",
    "windfury",
    "shadowflame",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if state.shadowtrance then
            return "shadowbolt"

        -- state.combat and
        elseif not state.autoattack then
            return "attack"

        elseif state.melee then
            -- stuff that doesn't make sense if you're not in melee range

            if state.cp5 then
                if mode == Faceroll.MODE_AOE then
                    return "crimsontempest"
                else
                    return "eviscerate"
                end

            elseif (mode == Faceroll.MODE_AOE) and state.shadowflame then
                return "shadowflame"

            elseif not state.gloomblade then
                return "gloomblade"

            else --if state.energy45 then
                return "sinisterstrike"
            end

        end
    end

    return nil
end
