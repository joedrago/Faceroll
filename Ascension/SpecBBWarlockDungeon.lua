-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock (Dungeon)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WD", "aaaaff", "WARLOCK-Demonic Reoccurence")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")
-- Faceroll.enemyGridTrack(spec, "Curse of Agony", "COA", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Spells -",
    "firestorm",
    "meta",
    "soulfire",

    "-- Buffs --",
    "shadowtrance",
    "moltencore",

    "-- Dots --",
    "corruption",
    "agony",
    "immolate",
    "immodeadzone",
    "incineratedeadzone",

    "- State -",
    "needtap",

    "-- Mode --",
    "hold",
    "pump",
})

spec.options = {
    "hold|mode",
    "pump|mode",
}

spec.radioColors = {
    "ffffaa",
    "ffaaaa",
}

local immoDeadzone = Faceroll.deadzoneCreate("Immolate", 0.3, 2)
local soulfireDeadzone = Faceroll.deadzoneCreate("Soul Fire", 0.3, 2)
local incinerateDeadzone = Faceroll.deadzoneCreate("Incinerate", 0.3, 2)

spec.calcState = function(state)
    -- Spells
    if Faceroll.isSpellAvailable("Fire Storm") then
        state.firestorm = true
    end
    if Faceroll.isSpellAvailable("Metamorphosis") then
        state.meta = true
    end

    Faceroll.deadzoneUpdate(soulfireDeadzone)
    if Faceroll.isBuffActive("Decimation") and Faceroll.isSpellAvailable("Soul Fire") and not Faceroll.deadzoneActive(soulfireDeadzone) then
        state.soulfire = true
    end

    if Faceroll.getBuffStacks("Molten Core") == 1 then
        Faceroll.deadzoneUpdate(incinerateDeadzone)
    end
    if Faceroll.deadzoneActive(incinerateDeadzone) then
        state.incineratedeadzone = true
    end

    -- Buffs
    if Faceroll.isBuffActive("Shadow Trance") then
        state.shadowtrance = true
    end
    if Faceroll.isBuffActive("Molten Core") then
        state.moltencore = true
    end

    -- -- Debuffs
    if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
        state.corruption = true
    end
    if Faceroll.getDotRemainingNorm("Curse of Agony") > 0.1 then
        state.agony = true
    end
    if Faceroll.getDotRemainingNorm("Immolate") > 0.1 then
        state.immolate = true
    end

    -- Never cast Immolate twice in a row
    Faceroll.deadzoneUpdate(immoDeadzone)
    if Faceroll.deadzoneActive(immoDeadzone) then
        state.immodeadzone = true
    end

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    local mana = UnitPower("player", Enum.PowerType.Mana)
    local manamax = UnitPowerMax("player", Enum.PowerType.Mana)
    local mananorm = mana / manamax
    if (hpnorm >= 0.25) and (mananorm < hpnorm) then
        state.needtap = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "tap",
    "corruption",
    "agony",
    "immolate",
    "meta",
    "soulfire",
    "shadowbolt",
    "firestorm",
    "seed",
    "incinerate",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- get some mana back
    if state.needtap and (not state.combat or not state.targetingenemy) then
        return "tap"

    elseif st then
        if state.targetingenemy then
            if state.pump and state.meta then
                return "meta"

            elseif state.shadowtrance then
                return "shadowbolt"

            -- maintain dots
            elseif not state.corruption then
                return "corruption"
            -- elseif state.pump and not state.agony then
            --     return "agony"
            elseif not state.immolate and not state.immodeadzone then
                return "immolate"

            -- filler
            elseif state.soulfire then
                return "soulfire"
            elseif state.moltencore and not state.incineratedeadzone then
                return "incinerate"
            else
                return "shadowbolt"

            end
        end

    elseif aoe then
        if state.pump and state.meta then
            return "meta"

        elseif state.firestorm then
            return "firestorm"

        else
            return "seed"

        end
    end

    return nil
end
