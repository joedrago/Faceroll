-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Shaman

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ES", "577497", "SHAMAN-ASCENSION")

spec.melee = "Primal Strike"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "selfheal",

    "- Buffs -",
    "stoneskin",
    "lightningshield",
    "earthenguardian",

    "- Dots -",
    "flameshockdot",

    "- Spells -",
    "flameshock",
    "earthshock",
    "primalstrike",
    "firenova",

    "- Totems -",
    "firetotem",
})

local healDeadzone = Faceroll.deadzoneCreate("Healing Wave", 1.5, 0.5)

spec.calcState = function(state)
    -- Resources --
    Faceroll.deadzoneUpdate(healDeadzone)
    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if (norHP <= 0.5) and Faceroll.hasManaForSpell("Healing Wave") and not Faceroll.deadzoneActive(healDeadzone) then
        state.selfheal = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Stoneskin") then
        state.stoneskin = true
    end
    if Faceroll.isBuffActive("Lightning Shield") then
        state.lightningshield = true
    end
    if Faceroll.isBuffActive("Earthen Guardian") then
        state.earthenguardian = true
    end

    -- Dots --

    if Faceroll.getDotRemainingNorm("Flame Shock") >= 0.1 then
        state.flameshockdot = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Flame Shock") then
        state.flameshock = true
    end
    if Faceroll.isSpellAvailable("Earth Shock") then
        state.earthshock = true
    end
    if Faceroll.isSpellAvailable("Primal Strike") then
        state.primalstrike = true
    end
    if Faceroll.isSpellAvailable("Fire Nova") then
        state.firenova = true
    end

    -- Totems --

    for i=1,4 do
        local haveTotem, totemName, startTime, duration = GetTotemInfo(i)
        if type(totemName) == "string" then
            if string.find(totemName, "Searing Totem") == 1 then
                -- state.searingtotem = true
                state.firetotem = true
            elseif string.find(totemName, "Magma Totem") == 1 then
                -- state.magmatotem = true
                state.firetotem = true
            end
        end
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "heal",
    "attack",
    "primalstrike",
    "earthshock",
    "stoneskin",
    "lightningshield",
    "flameshock",
    "searingtotem",
    "firenova",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.selfheal then
        return "heal"

    elseif not state.lightningshield then
        return "lightningshield"

    elseif state.targetingenemy then
        -- if state.combat then
            -- if not state.melee and state.charge then
            --     return "charge"

            -- if not state.stoneskin then
            --     return "stoneskin"

            if aoe and not state.firetotem then
                return "searingtotem"

            elseif aoe and state.firenova then
                return "firenova"

            elseif not state.autoattack then
                return "attack"

            elseif not aoe and not state.earthenguardian and not state.flameshockdot and state.flameshock then
                return "flameshock"

            elseif not aoe and state.flameshockdot and state.earthshock then
                return "earthshock"

            elseif state.primalstrike then
                return "primalstrike"
            end
        -- end
    end

    return nil
end
