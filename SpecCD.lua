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
    "cat",
    "targetingenemy",
    "melee",
    "combat",
    "manaL70",
    "manaL80",
    "energyG30",
    "energyG40",
    "cpG3",
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
    if GetShapeshiftForm() == 3 then
        state.cat = true
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
    if norMana < 0.7 then
        state.manaL70 = true
    end
    if norMana < 0.8 then
        state.manaL80 = true
    end

    local curEnergy = UnitPower("player", 3)
    if curEnergy >= 30 then
        state.energyG30 = true
    end
    if curEnergy >= 40 then
        state.energyG40 = true
    end

    local cp = GetComboPoints("player", "target")
    if cp >= 3 then
        state.cpG3 = true
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
    "swipe",
    "moonfire",
    "rejuvenation",
    "enrage",
    "cat",
    "rip",
    "claw",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Cat Form

        if state.hpL90 and not state.manaL80 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif state.targetingenemy then
            if not state.combat and not state.thorns then
                return "thorns"

            elseif not state.combat and not state.manaL70 and not state.cat and not state.moonfire then
                return "moonfire"

            elseif not state.cat then
                return "cat"

            elseif state.cpG3 and state.energyG30 then
                return "rip"

            elseif state.energyG40 then
                return "claw"
            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- Bear Form

        if state.hpL90 and not state.manaL80 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif state.targetingenemy then
            if not state.combat and not state.thorns then
                return "thorns"

            elseif not state.combat and not state.manaL70 and not state.bear and not state.moonfire then
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
                return "swipe"
            end
        end

    end

    return nil
end
