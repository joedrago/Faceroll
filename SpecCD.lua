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
    "Tiger's Fury",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Stances -",
    "bear",
    "cat",

    "- Combat -",
    "targetingenemy",
    "melee",
    "combat",
    "aoe",
    "hold",

    "- Resources -",
    "hpL80",
    "hpL90",
    "manaL70",
    "manaL80",
    "energyG30",
    "energyG35",
    "energyG40",
    "cpG3",

    "- Buffs -",
    "thorns",
    "rejuvenation",
    "tigersfury",

    "- Debuffs -",
    "moonfire",
    "roar",
    "rake",

    "- Spells -",
    "enrage",
}

spec.calcState = function(state)
    -- Stances --

    if GetShapeshiftForm() == 1 then
        state.bear = true
    end
    if GetShapeshiftForm() == 3 then
        state.cat = true
    end

    -- Combat --

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if IsSpellInRange("Growl", "target") == 1 then
        state.melee = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
    end

    local mobCount = 0
    for i = 0, 5, 1 do
        if _G["NamePlate"..i] ~= nil and _G["NamePlate"..i]:IsVisible() then
            mobCount = mobCount + 1
        end
    end
    if mobCount > 1 then
        state.aoe = true
    end

    if Faceroll.hold then
        state.hold = true
    end

    -- Resources --

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.8 then
        state.hpL80 = true
    end
    if norHP < 0.9 then
        state.hpL90 = true
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
    if curEnergy >= 35 then
        state.energyG35 = true
    end
    if curEnergy >= 40 then
        state.energyG40 = true
    end

    local cp = GetComboPoints("player", "target")
    if cp >= 3 then
        state.cpG3 = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Thorns") then
        state.thorns = true
    end

    if Faceroll.isBuffActive("Rejuvenation") then
        state.rejuvenation = true
    end

    if Faceroll.isBuffActive("Tiger's Fury") then
        state.tigersfury = true
    end

    -- Debuffs --

    if Faceroll.isDotActive("Moonfire") > 0.1 then
        state.moonfire = true
    end

    if Faceroll.isDotActive("Demoralizing Roar") > 0.1 then
        state.roar = true
    end

    if Faceroll.isDotActive("Rake") > 0.1 then
        state.rake = true
    end

    -- Spells --

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
    "rake",
    "maul",
    "tigersfury",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Cat Form

        if not state.targetingenemy and state.hpL80 and not state.manaL70 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif not state.targetingenemy and not state.combat and not state.thorns then
            return "thorns"

        elseif not state.cat then
            return "cat"

        elseif state.targetingenemy then

            -- state.hold means "I am fighting bleed immune targets"

            if not state.tigersfury and state.energyG30 then
                return "tigersfury"

            elseif not state.hold and state.cpG3 and state.energyG30 then
                return "rip"

            elseif not state.hold and not state.rake and state.energyG35 then
                return "rake"

            elseif state.energyG40 then
                return "claw"
            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- Bear Form

        if not state.targetingenemy and state.hpL90 and not state.manaL80 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif not state.targetingenemy and not state.combat and not state.thorns then
                return "thorns"

        elseif state.targetingenemy then
            if not state.combat and not state.manaL70 and not state.bear and not state.moonfire then
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

            elseif state.aoe then
                return "swipe"
            else
                return "maul"
            end
        end

    end

    return nil
end
