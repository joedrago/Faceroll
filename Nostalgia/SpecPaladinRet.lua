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
    "healdeadzone",
    "hold",

    "- Buffs -",
    "needsblessing",
    "needsseal",

    "- Spells -",
    { "s_judgement", "Judgement of Light" },
    { "s_handofreckoning", "Hand of Reckoning" },
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    Faceroll.deadzoneUpdate(healDeadzone)
    if Faceroll.deadzoneActive(healDeadzone) then
        state.healdeadzone = true
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

    if not state.combat and state.hp < 0.75 and not state.healdeadzone then
        return "healself"

    elseif state.targetingenemy then

        if not state.combat and not state.group and state.s_handofreckoning then
            return "handofreckoning"

        elseif state.s_judgement then
            return "judgement"

        -- elseif state.justjudged and mode == Faceroll.MODE_AOE then
        --     return "consecration"

        else
            return "attack"

        end
    end
end
