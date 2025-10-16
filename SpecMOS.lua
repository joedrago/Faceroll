-----------------------------------------------------------------------------------------
-- Ascension WoW Master of Shadows

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MOS", "777799", "HERO-Master of Shadows")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Resources -",
    "energy35",
    "energy45",
    "cp3",
    "cp5",

    "- Abilities -",
    "shadowstep",

    "- Buffs -",
    "sliceanddice",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
}

spec.calcState = function(state)
    local energy = UnitPower("PLAYER", Enum.PowerType.Energy)
    local cp = GetComboPoints("PLAYER", "TARGET")

    if energy >= 35 then
        state.energy35 = true
    end
    if energy >= 45 then
        state.energy45 = true
    end

    if cp >= 3 then
        state.cp3 = true
    end
    if cp >= 5 then
        state.cp5 = true
    end

    if Faceroll.isSpellAvailable("Shadowstep") then
        state.shadowstep = true
    end

    local snd = Faceroll.getBuffRemaining("Slice and Dice")
    if snd > 5 then
        state.sliceanddice = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        -- local targethp = UnitHealth("target")
        -- local targethpmax = UnitHealthMax("target")
        -- local targethpnorm = targethp / targethpmax
        -- if targethpnorm <= 0.40 then
        --     state.target40 = true
        -- end
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = ""
        o = o .. "SND: " .. snd .. "\n"
        o = o .. "CP : " .. cp .. "\n"
        o = o .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "attack",
    "sinisterstrike",
    "eviscerate",
    "shadowstep",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then

            -- if not state.combat and state.shadowstep then
            --     return "shadowstep"

            if state.combat and not state.autoattack then
                return "attack"

            elseif state.cp5 then
                return "eviscerate"

            else --if state.energy45 then
                return "sinisterstrike"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

    end

    return nil
end
