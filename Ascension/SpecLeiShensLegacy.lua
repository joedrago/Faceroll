-----------------------------------------------------------------------------------------
-- Ascension WoW Carnage Incarnate

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LSL", "3333bb", "HERO-Lei Shen's Legacy")

spec.melee = "Stormstrike"
spec.options = {
    "solo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- State -",
    "bear",
    "maulqueued",
    "solo",

    "- Buffs -",
    "thunderhide",

    "- Abilities -",
    "charge",
    "enrage",
    "regen",
    "voltaicbite",
    "stormsmash",

    "potion",
})

spec.calcState = function(state)
    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and (name == "Bear Form" or name == "Dire Bear Form") then
            state.bear = true
        end
    end

    if IsCurrentSpell("Maul") then
        state.maulqueued = true
    end

    if Faceroll.isBuffActive("Thunder Hide") then
        state.thunderhide = true
    end

    if Faceroll.isSpellAvailable("Feral Charge - Bear") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Enrage") then
        state.enrage = true
    end
    if Faceroll.isSpellAvailable("Frenzied Regeneration") then
        state.regen = true
    end
    if Faceroll.isSpellAvailable("Voltaic Bite") then
        state.voltaicbite = true
    end
    if Faceroll.isSpellAvailable("Storm Smash") then
        state.stormsmash = true
    end

    local potionStart = GetActionCooldown(1)
    if potionStart > 0 then
        local potionRemaining = GetTime() - potionStart
        if potionRemaining < 1.6 then -- mana potion in slot 1
            state.potion = true
        end
    else
        state.potion = true
    end
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm >= 0.8 then
        state.potion = false
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "attack",
    "charge",
    "swipe",
    "thunderhide",
    "voltaicbite",
    "potion",
    "enrage",
    "maul",
    "stormsmash",
    "regen",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.potion then
        return "potion"
    end

    if state.targetingenemy then

        if not state.bear then
            return "bear"

        elseif not state.thunderhide then
            return "thunderhide"

        elseif not state.melee and state.charge then
            return "charge"

        elseif not state.autoattack and not state.maulqueued then
            return "attack"

        elseif state.regen then
            return "regen"

        elseif state.enrage then
            return "enrage"

        elseif state.stormsmash and state.melee then
            return "stormsmash"

        elseif st and state.voltaicbite then
            return "voltaicbite"

        elseif st and not state.maulqueued then
            return "maul"

        else
            return "swipe"

        end
    end

    return nil
end
