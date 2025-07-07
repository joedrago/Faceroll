-----------------------------------------------------------------------------------------
-- Classic Priest

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CP", "ccccaa", "PRIEST-CLASSIC")

spec.buffs = {
    "Inner Fire",
    "Renew",
    "Weakened Soul",
    "Power Word: Shield",
}

spec.states = {
    "combat",

    "innerfire",
    "renewbuff",
    "weakenedsoulbuff",
    "shieldbuff",

    "shieldavailable",
    "mindblast",

    "targetingenemy",
    "pain",

    "hp80",
}

spec.calcState = function(state)
    if UnitAffectingCombat("player") then
        state.combat = true
    end

    if Faceroll.isBuffActive("Inner Fire") then
        state.innerfire = true
    end
    if Faceroll.isBuffActive("Renew") then
        state.renewbuff = true
    end
    if Faceroll.isBuffActive("Weakened Soul") then
        state.weakenedsoulbuff = true
    end
    if Faceroll.isBuffActive("Power Word: Shield") then
        state.shieldbuff = true
    end

    if Faceroll.isSpellAvailable("Power Word: Shield") then
        state.shieldavailable = true
    end

    if Faceroll.isSpellAvailable("Mind Blast") then
        state.mindblast = true
    end

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if Faceroll.isDotActive("Shadow Word: Pain") > 0.1 then
        state.pain = true
    end

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.8 then
        state.hp80 = true
    end

    return state
end

spec.actions = {
    "shield",
    "renew",
    "mindblast",
    "pain",
    "shoot",
    "innerfire",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then
            if not state.combat and not state.innerfire then
                return "innerfire"

            elseif state.hp80 and not state.renewbuff then
                return "renew"

            elseif not state.shieldbuff and not state.weakenedsoulbuff and state.shieldavailable then
                return "shield"

            elseif not state.combat and state.mindblast then
                return "mindblast"

            elseif not state.pain then
                return "pain"

            else
                return "shoot"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.targetingenemy then
            return "shoot"
        end
    end

    return nil
end
