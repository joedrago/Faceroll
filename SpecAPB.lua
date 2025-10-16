-----------------------------------------------------------------------------------------
-- Ascension WoW Plague Bearer

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("APB", "997799", "HERO-Plague Bearer")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Resources -",
    "rage20",
    "rage40",

    "- State -",
    "bear",
    "fsqueued",

    "- Debuffs -",
    "infectedblood",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
}

spec.calcState = function(state)
    local rage = UnitPower("PLAYER", Enum.PowerType.Rage)
    local cp = GetComboPoints("PLAYER", "TARGET")

    if rage >= 20 then
        state.rage20 = true
    end
    if rage >= 40 then
        state.rage40 = true
    end

    local s = nil
    for i = 1, GetNumShapeshiftForms() do
        if select(3, GetShapeshiftFormInfo(i)) then
            s = i
        end
    end
    if s ~= nil then
        state.bear = true
    end

    if IsCurrentSpell("Festering Strike") then
        state.fsqueued = true
    end

    if Faceroll.isDotActive("Infected Blood") > 0 then
        state.infectedblood = true
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

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "attack",
    "swipe",
    "festeringstrike",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then

            if not state.bear then
                return "bear"

            elseif not state.autoattack and not state.fsqueued then
                return "attack"

            elseif not state.infectedblood and not state.fsqueued then
                return "festeringstrike"

            elseif (state.fsqueued and state.rage40) or (not state.fsqueued and state.rage20) then
                return "swipe"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

    end

    return nil
end
