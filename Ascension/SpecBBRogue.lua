-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("R", "975774", "ROGUE-ASCENSION")

spec.melee = "Sinister Strike"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "selfheal",

    "- Buffs -",
    "seal",
    "blessing",

    "- Spells -",
    "crusaderstrike",
    "judgement",
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
    if Faceroll.isBuffActive("Blessing of Might") then
        state.blessing = true
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
    if Faceroll.isSpellAvailable("Judgement of Light") then
        state.judgement = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "sinisterstrike",
    "eviscerate",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    -- local aoe = (mode == Faceroll.MODE_AOE)

    -- if state.selfheal then
    --     return "heal"

    -- elseif not state.seal then
    --     return "seal"

    -- elseif not state.blessing then
    --     return "blessing"

    -- elseif state.targetingenemy then
    --     -- if state.combat then
    --         -- if not state.melee and state.charge then
    --         --     return "charge"

    --         if not state.autoattack then
    --             return "attack"

    --         elseif state.combat and state.judgement then
    --             return "judgement"

    --         elseif state.combat and state.crusaderstrike then
    --             return "crusaderstrike"
    --         end
    --     -- end
    -- end

    if state.combopoints >= 3 then
        return "eviscerate"
    else
        return "sinisterstrike"
    end

    return nil
end
