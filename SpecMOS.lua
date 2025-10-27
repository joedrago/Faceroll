-----------------------------------------------------------------------------------------
-- Ascension WoW Master of Shadows

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MOS", "777799", "HERO-Master of Shadows")

-----------------------------------------------------------------------------------------
-- States

spec.states = {
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

    if Faceroll.isDotActive("Gloomblade") > 0.25 then
        state.gloomblade = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        -- local targethp = UnitHealth("target")
        -- local targethpmax = UnitHealthMax("target")
        -- local targethpnorm = targethp / targethpmax
        -- if targethpnorm <= 0.40 then
        --     state.target40 = true
        -- end
    end
    if UnitAffectingCombat("player") then
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
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

        if state.targetingenemy then

            -- if not state.combat and state.shadowstep then
            --     return "shadowstep"

            if state.shadowtrance then
                return "shadowbolt"

            -- state.combat and
            elseif not state.autoattack then
                return "attack"

            elseif state.melee then
                -- stuff that doesn't make sense if you're not in melee range

                -- if not state.windfury then
                --     return "windfury"

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

    end

    return nil
end
