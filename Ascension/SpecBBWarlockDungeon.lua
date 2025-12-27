-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock (Dungeon)

if Faceroll == nil then
    _, Faceroll = ...
end

-- Heretic of Gul'dan
-- Glyph of Immolate or Incinerate

local spec = Faceroll.createSpec("WD", "aaaaff", "WARLOCK-Hand of Gul'dan")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")
Faceroll.enemyGridTrack(spec, "Curse of Agony", "COA", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Spells -",
    "firestorm",
    "handofguldan",

    "-- Dots --",
    "corruption",
    "agony",
    "immolate",

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

spec.calcState = function(state)
    -- Spells
    if Faceroll.isSpellAvailable("Fire Storm") then
        state.firestorm = true
    end
    if Faceroll.isSpellAvailable("Hand of Gul'dan") then
        state.handofguldan = true
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
    "handofguldan",
    "tap",
    "rof",
    "firestorm",
    "immolate",
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
            elseif not state.immolate then
                return "immolate"

            elseif state.handofguldan then
                return "handofguldan"

            -- filler
            else
                return "incinerate"

            end
        end

    elseif aoe then
        if state.firestorm then
            return "firestorm"
        elseif state.handofguldan then
            return "handofguldan"
        else
            return "rof"
        end
    end

    return nil
end
