-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Mage

-- An explanation of the "brita" option: it provides a means to create lots of
-- conjured food and water. If you enable "brita" (/fro brita), ST will attempt
-- to create 100 food and 100 water, then self-buff, drink to full, and wait. If
-- using AOE, it behaves the same, but will just make food and water forever
-- (instead of stopping at 100 each).

-- For combat, everything is decided based on:
-- * am I already in combat
-- * am I targeting an enemy
-- * do I have enough mana
--
-- Typically targeting an enemy is a signal that I want to *enter* combat.

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("M", "995599", "MAGE-ASCENSION")

local CONJURED_FOOD_NAME  = "Conjured Rye"
local CONJURED_WATER_NAME = "Conjured Purified Water"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Combat -",
    "moving",
    "group",
    "channeling",

    "- Resources -",
    "hpL50",
    "manaL25",
    "manaL50",
    "manaL80",
    "manafull",

    "- Consume -",
    "drink",
    "drinkending",

    "- Conjure -",
    "waterL1",
    "waterL100",
    "foodL1",
    "foodL100",
    "foodLwater",

    "- Buffs -",
    "frostarmor",
    "arcaneintellect",
    "icebarrier",

    "- Dot -",
    "arcanecharge",
    "abdeadzone",

    "- Spells -",
    "icebarrierready",
    "coneofcold",
    "frostbolt",
    "blizzard",

    "- Options -",
    "brita",
})

spec.options = {
    "brita", -- I am a brita water filter, and my existence is to fill up glasses of water
}

local abDeadzone = Faceroll.deadzoneCreate("Arcane Blast", 0.3, 3)

spec.calcState = function(state)
    -- Combat --

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if Faceroll.inCombat() then
        state.combat = true
    end

    if CheckInteractDistance("target", 3) then
        state.melee = true
    end

    -- local movingStoppedSince = GetTime() - Faceroll.movingStopped
    if Faceroll.moving then --or (movingStoppedSince < 0.5) then
        state.moving = true
    end

    if IsInGroup() then
        state.group = true
    end

    local channelingSpell, _, _, _, channelEndMS = UnitChannelInfo("player")
    if channelingSpell then
        -- local channelFinish = channelEndMS/1000 - GetTime()
        state.channeling = true
    end

    -- Resources --

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.5 then
        state.hpL50 = true
    end

    local curMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local norMana = curMana / maxMana
    if norMana < 0.25 then
        state.manaL25 = true
    end
    if norMana < 0.5 then
        state.manaL50 = true
    end
    if norMana < 0.8 then
        state.manaL80 = true
    end
    if norMana > 0.95 then
        state.manafull = true
    end

    local waterCount = GetItemCount(CONJURED_WATER_NAME)
    local foodCount  = GetItemCount(CONJURED_FOOD_NAME)

    if waterCount < 1 then
        state.waterL1 = true
    end
    if waterCount < 100 then
        state.waterL100 = true
    end
    if foodCount < 1 then
        state.foodL1 = true
    end
    if foodCount < 100 then
        state.foodL100 = true
    end
    if foodCount < waterCount then
        state.foodLwater = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Frost Armor") then
        state.frostarmor = true
    end

    if Faceroll.isBuffActive("Arcane Intellect") or Faceroll.isBuffActive("Arcane Brilliance") then
        state.arcaneintellect = true
    end
    if Faceroll.isBuffActive("Drink") then
        state.drink = true
    end
    if Faceroll.getBuffRemaining("Drink") < 4 then
        state.drinkending = true
    end
    if Faceroll.isBuffActive("Ice Barrier") then
        state.icebarrier = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Ice Barrier") then
        state.icebarrierready = true
    end

    if Faceroll.isSpellAvailable("Cone of Cold") then
        state.coneofcold = true
    end

    if Faceroll.hasManaForSpell("Frostbolt") then
        state.frostbolt = true
    end

    if Faceroll.hasManaForSpell("Blizzard") then
        state.blizzard = true
    end

    -- state.arcanestacks =

    if Faceroll.getDotRemainingNorm("Arcane Charge") > 0.1 then
        state.arcanecharge = true
    end
    if Faceroll.deadzoneUpdate(abDeadzone) then
        -- for AOE
        state.abdeadzone = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "frostarmor",
    "arcaneintellect",
    "arcaneblast",
    "arcaneexplosion",
    "targetaoe",
    "consume",
    "makefood",
    "makewater",
    "arcanemissiles",
    "blizzard",
    "icebarrier",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        local makeForever = state.brita and (mode == Faceroll.MODE_AOE)

        if not state.combat and state.drink and state.drinkending and state.manaL80 then
            -- we're going to need to drink more to finish drinking
            return "consume"

        elseif not state.combat and state.drink and not state.manafull then
            -- wait for full mana
            return nil

        -- TODO: make this conditional significantly less ugly
        elseif not state.combat
           and (((state.brita and state.manaL25) or (not state.brita and (state.manaL50 or state.hpL50))) or (not state.brita and state.group and not state.manafull))
           and not state.waterL1
           and not state.drink
           and not state.moving
           and not state.targetingenemy
           then
            -- low on mana or hp, and we've given a second or two to loot
            return "consume"

        elseif not state.combat and not state.targetingenemy and not state.foodLwater and (makeForever or state.waterL1 or (state.brita and state.waterL100)) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makewater"

        elseif not state.combat and (makeForever or state.foodL1 or (state.brita and state.foodL100)) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makefood"

        elseif not state.combat and not state.frostarmor then
            return "frostarmor"

        elseif not state.combat and not state.arcaneintellect then
            return "arcaneintellect"

        elseif not state.combat and state.brita and not state.waterL100 and not state.manafull then
            -- we just finished preparing a big pile of water and buffs, top off
            return "consume"

        elseif not state.brita then
            -- combat

            if mode == Faceroll.MODE_ST then
                -- Single Target

                if state.targetingenemy then
                    -- if state.coneofcold and state.melee and not state.manaL25 and state.hpL50 then
                    --     -- hpL50 here is to take a hit or two while wanding for FSR
                    --     return "coneofcold"

                    if not state.group and not state.icebarrier and state.icebarrierready and not state.manaL25 then
                        return "icebarrier"

                    -- elseif (state.melee and not state.group and not state.icebarrier) or not state.arcaneblast then
                    --     return "shoot"

                    else
                        return "arcaneblast"
                    end
                end

            elseif mode == Faceroll.MODE_AOE then
                -- AOE

                if not state.targetingenemy then
                    return "targetaoe"

                elseif not state.channeling and (state.combat or state.targetingenemy) then
                    if not state.arcanecharge and not state.abdeadzone and not state.moving then
                        return "arcaneblast"
                    else
                        return "arcaneexplosion"
                    end
                end
            end
        end
    end
    return nil
end
