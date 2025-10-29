-----------------------------------------------------------------------------------------
-- Classic Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "ffffaa", "PALADIN-CLASSIC")

-- put this blessing in the first slot
local GO_BLESS_YOURSELF = "Blessing of Wisdom"

-- put this seal in the second slot
local GO_SEAL_YOURSELF = "Seal of Command"

spec.buffs = {
    GO_BLESS_YOURSELF,
    GO_SEAL_YOURSELF,
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
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
    "justjudged",
}

spec.options = {
    "hold",
}

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    if Faceroll.inCombat() then
        state.combat = true
    end

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

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

    if Faceroll.getBuffRemaining(GO_BLESS_YOURSELF) < 10 then
        state.needsblessing = true
    end

    if Faceroll.getBuffRemaining(GO_SEAL_YOURSELF) < 2 then
        state.needsseal = true
    end

    if Faceroll.isSpellAvailable("Judgement") then
        state.judgement = true
    end

    local judgeCD = Faceroll.getSpellCooldown("Judgement")
    if judgeCD > 7.5 then
        state.justjudged = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "blessing",
    "seal",
    "judgement",
    "attack",
    "healself",
    "consecration",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

        if not state.combat and state.hpL75 and not state.healdeadzone then
            return "healself"

        elseif state.needsblessing then
            return "blessing"

        elseif state.targetingenemy then

            if state.needsseal then
                return "seal"

            elseif state.judgement and not state.hold then
                return "judgement"

            -- elseif state.justjudged and mode == Faceroll.MODE_AOE then
            --     return "consecration"

            else
                return "attack"

            end
        end

    end

    return nil
end
