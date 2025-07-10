-----------------------------------------------------------------------------------------
-- Classic Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CD", "006600", "DRUID-CLASSIC")

spec.buffs = {
    "Mark of the Wild",
    "Thorns",
    "Rejuvenation",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "bear",
    "targetingenemy",
    "melee",
    "combat",
    "manaL80",
    "hpL90",
    "roar",
    "moonfire",
    "thorns",
    "rejuvenation",
    "enrage",
}

spec.calcState = function(state)
    if GetShapeshiftForm() == 1 then
        state.bear = true
    end

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if IsSpellInRange("Growl", "target") == 1 then
        state.melee = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
    end

    local curMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local norMana = curMana / maxMana
    if norMana < 0.8 then
        state.manaL80 = true
    end

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.9 then
        state.hpL90 = true
    end

    if Faceroll.isDotActive("Demoralizing Roar") > 0.1 then
        state.roar = true
    end

    if Faceroll.isDotActive("Moonfire") > 0.1 then
        state.moonfire = true
    end

    if Faceroll.isBuffActive("Thorns") then
        state.thorns = true
    end

    if Faceroll.isBuffActive("Rejuvenation") then
        state.rejuvenation = true
    end

    if Faceroll.isSpellAvailable("Enrage") then
        state.enrage = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "thorns",
    "roar",
    "maul",
    "moonfire",
    "rejuvenation",
    "enrage",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then

        if state.hpL90 and not state.manaL80 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif state.targetingenemy then
            if not state.combat and not state.thorns then
                return "thorns"

            elseif not state.combat and not state.bear and not state.moonfire then
                return "moonfire"

            elseif not state.bear then
                return "bear"

            elseif state.enrage then
                return "enrage"

            elseif not state.roar then
                if state.melee then
                    return "roar"
                end
                -- we want to wait if we can't roar

            else
                return "maul"
            end
        end

    end

    return nil
end
