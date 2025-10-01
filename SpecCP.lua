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

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Buffs -",
    "innerfire",
    "renewbuff",
    "weakenedsoulbuff",
    "shieldbuff",

    "- Debuffs -",
    "pain",

    "- Spells -",
    "shieldavailable",
    "mindblast",

    "- Combat -",
    "combat",
    "hp80",

    "- Target -",
    "targetingenemy",
    "target30",
}

spec.calcState = function(state)
    -- Buffs
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

    -- Debuffs
    if Faceroll.isDotActive("Shadow Word: Pain") > 0.1 then
        state.pain = true
    end

    -- Spells
    if Faceroll.isSpellAvailable("Power Word: Shield") then
        state.shieldavailable = true
    end
    if Faceroll.isSpellAvailable("Mind Blast") then
        state.mindblast = true
    end

    -- Combat
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.8 then
        state.hp80 = true
    end

    -- Target
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        local targethp = UnitHealth("target")
        local targethpmax = UnitHealthMax("target")
        local targethpnorm = targethp / targethpmax
        if targethpnorm <= 0.30 then
            state.target30 = true
        end
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = ""
        local coast = "N"
        if Faceroll.coasting then
            coast = "Y"
        end
        o = o .. "Coasting: " .. coast .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

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

        if state.hp80 and not state.renewbuff then
            return "renew"

        elseif state.targetingenemy then
            -- if not state.innerfire then
            --     return "innerfire"

            if not state.shieldbuff and not state.weakenedsoulbuff and state.shieldavailable then
                return "shield"

            elseif not state.combat and state.mindblast then
                return "mindblast"

            elseif not state.pain then
                return "pain"

            --elseif state.target30 then
            --    -- coast until combat drops
            --    return Faceroll.ACTION_COAST

            else
                return "shoot"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if not state.innerfire then
            return "innerfire"

        elseif state.targetingenemy then
            return "shoot"

        end
    end

    return nil
end
