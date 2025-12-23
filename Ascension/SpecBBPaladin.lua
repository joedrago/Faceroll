-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "975774", "PALADIN-ASCENSION")

spec.melee = "Crusader Strike"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "selfheal",

    "- Buffs -",
    "seal",

    "- Spells -",
    "crusaderstrike",
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    -- Resources --
    Faceroll.deadzoneUpdate(healDeadzone)
    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if (norHP <= 0.5) and Faceroll.hasManaForSpell("Holy Light") and not Faceroll.deadzoneActive(healDeadzone) then
        state.selfheal = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Seal of Righteousness") then
        state.seal = true
    end

    -- if Faceroll.isBuffActive("Arcane Intellect") or Faceroll.isBuffActive("Arcane Brilliance") then
    --     state.arcaneintellect = true
    -- end
    -- if Faceroll.isBuffActive("Drink") then
    --     state.drink = true
    -- end
    -- if Faceroll.getBuffRemaining("Drink") < 4 then
    --     state.drinkending = true
    -- end
    -- if Faceroll.isBuffActive("Ice Barrier") then
    --     state.icebarrier = true
    -- end

    -- Spells --

    if Faceroll.isSpellAvailable("Crusader Strike") then
        state.crusaderstrike = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "seal",
    "heal",
    "attack",
    "crusaderstrike",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    -- local aoe = (mode == Faceroll.MODE_AOE)

    if state.selfheal then
        return "heal"

    elseif not state.seal then
        return "seal"

    elseif state.targetingenemy then
        -- if state.combat then
            -- if not state.melee and state.charge then
            --     return "charge"

            if not state.autoattack then
                return "attack"

            elseif state.combat and state.crusaderstrike then
                return "crusaderstrike"
            end
        -- end
    end

    return nil
end
