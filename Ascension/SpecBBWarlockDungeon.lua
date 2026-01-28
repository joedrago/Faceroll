-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock (Dungeon)

if Faceroll == nil then
    _, Faceroll = ...
end

-- Heretic of Gul'dan
-- Glyph of Immolate or Incinerate
-- Dusk Till Dawn (Shadowburn!)
-- Decisive Decimation (useless until 48)
-- Inner Flame (now) -> Unstable Void (50)

local spec = Faceroll.createSpec("WD", "aaaaff", "WARLOCK-Shadow Crash")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")
Faceroll.enemyGridTrack(spec, "Curse of Agony", "COA", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Spells -",
    "firestorm",
    "shadowcrash",
    "conflagrate",
    "soulfire",
    "shadowfury",
    "backdraft",

    "-- Dots --",
    "corruption",
    "agony",
    "immolate",
    "immodeadzone",

    "- State -",
    "needtap",

    "-- Mode --",
    "trash",
    "boss",
})

spec.options = {
    "trash|mode",
    "boss|mode",
}

spec.radioColors = {
    "ffffaa",
    "ffaaaa",
}

local immoDeadzone = Faceroll.deadzoneCreate("Immolate", 0.3, 1)
local soulfireDeadzone = Faceroll.deadzoneCreate("Soul Fire", 0.3, 1)

spec.calcState = function(state)
    -- Spells
    if Faceroll.isSpellAvailable("Fire Storm") then
        state.firestorm = true
    end
    if Faceroll.isSpellAvailable("Shadow Crash") then
        state.shadowcrash = true
    end
    if Faceroll.isSpellAvailable("Conflagrate") then
        state.conflagrate = true
    end
    if Faceroll.isSpellAvailable("Shadowfury") then
        state.shadowfury = true
    end
    if Faceroll.getBuffStacks("Backdraft") > 0 then
        state.backdraft = true
    end

    Faceroll.deadzoneUpdate(soulfireDeadzone)
    if Faceroll.isBuffActive("Decisive Decimation") and Faceroll.isSpellAvailable("Soul Fire") and not Faceroll.deadzoneActive(soulfireDeadzone) then
        state.soulfire = true
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
    "sic",
    "incinerate",
    "corruption",
    "agony",
    "shadowcrash",
    "tap",
    "rof",
    "firestorm",
    "immolate",
    "conflagrate",
    "soulfire",
    "shadowfury",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- get some mana back
    if state.needtap and (not state.combat or not state.targetingenemy) then
        return "tap"

    elseif st then
        if state.targetingenemy then
            -- maintain dots
            if state.boss and not state.corruption then
                return "corruption"
            elseif state.boss and not state.agony then
                return "agony"
            elseif state.conflagrate then
                return "conflagrate"
            elseif not state.immolate and not state.immodeadzone then
                return "immolate"

            -- elseif state.shadowcrash then
            --     return "shadowcrash"

            -- filler
            elseif state.soulfire then
                return "soulfire"
            else
                return "incinerate"

            end
        end

    elseif aoe then
        if state.targetingenemy and state.conflagrate then
            return "conflagrate"
        elseif state.shadowcrash then
            return "shadowcrash"
        elseif state.firestorm then
            return "firestorm"
        elseif state.shadowfury and not state.backdraft then
            return "shadowfury"
        else
            return "rof"
        end
    end

    return nil
end
