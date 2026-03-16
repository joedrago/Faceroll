-----------------------------------------------------------------------------------------
-- Nostalgia Ret Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "ffffaa", "PALADIN-3")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- State -",
    "combat",
    "targetingenemy",
    "hpL75",
    "healdeadzone",
    "hold",

    "- Buffs -",
    "needsblessing",
    "needsseal",

    "- Spells -",
    "judgement",
    "handofreckoning",
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.75 then
        state.hpL75 = true
    end

    Faceroll.deadzoneUpdate(healDeadzone)
    if Faceroll.deadzoneActive(healDeadzone) then
        state.healdeadzone = true
    end

    if Faceroll.isSpellAvailable("Judgement of Light") then
        state.judgement = true
    end
    if Faceroll.isSpellAvailable("Hand of Reckoning") then
        state.handofreckoning = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "judgement",
    "attack",
    "healself",
    "consecration",
    "handofreckoning",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.combat and state.hpL75 and not state.healdeadzone then
        return "healself"

    elseif state.targetingenemy then

        if not state.combat and not state.group and state.handofreckoning then
            return "handofreckoning"

        elseif state.judgement then
            return "judgement"

        -- elseif state.justjudged and mode == Faceroll.MODE_AOE then
        --     return "consecration"

        else
            return "attack"

        end
    end
end
