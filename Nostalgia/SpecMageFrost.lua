-----------------------------------------------------------------------------------------
-- Classic Mage

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

local spec = Faceroll.createSpec("CM", "00c7ee", "MAGE-3")

spec.overlay = Faceroll.createOverlay({
    "Mage Armor",
    "Arcane Intellect",
    "Arcane Brilliance",
    "Drink",
    "Ice Barrier",
})

local CONJURED_FOOD_NAME  = "Conjured Sourdough"
local CONJURED_WATER_NAME = "Conjured Mineral Water"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Combat -",
    "moving",
    "group",
    "channeling",

    "- Consume -",
    "drink",
    "drinkending",

    "- Buffs -",
    { "b_magearmor", "Mage Armor" },
    "arcaneintellect",
    { "b_icebarrier", "Ice Barrier" },

    "- Spells -",
    { "s_icebarrierready", "Ice Barrier" },
    { "s_coneofcold", "Cone of Cold" },
    "frostbolt",
    "blizzard",
}

spec.calcState = function(state)
    -- Combat --

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

    -- Buffs --

    if Faceroll.isBuffActive("Arcane Intellect") or Faceroll.isBuffActive("Arcane Brilliance") then
        state.arcaneintellect = true
    end
    if Faceroll.isBuffActive("Drink") then
        state.drink = true
    end
    if Faceroll.getBuffRemaining("Drink") < 4 then
        state.drinkending = true
    end
    -- Spells --

    if Faceroll.hasManaForSpell("Frostbolt") then
        state.frostbolt = true
    end

    if Faceroll.hasManaForSpell("Blizzard") then
        state.blizzard = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "magearmor",
    "arcaneintellect",
    "frostbolt",
    "coneofcold",
    "blizzard",
    "icebarrier",
}

spec.calcAction = function(mode, state)
    if not state.combat and not state.b_magearmor then
        return "magearmor"

    elseif not state.combat and not state.arcaneintellect then
        return "arcaneintellect"

    elseif mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then
            if state.s_coneofcold and state.melee then
                return "coneofcold"

            elseif not state.group and not state.b_icebarrier and state.s_icebarrierready then
                return "icebarrier"

            else
                return "frostbolt"
            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        -- if state.coneofcold and state.melee then
        --     return "coneofcold"
        if not state.channeling and (state.combat or state.targetingenemy) then
            -- if state.blizzard then
                return "blizzard"

            -- elseif state.targetingenemy then
                -- return "shoot"
            -- end
        end
    end
end
