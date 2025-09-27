-----------------------------------------------------------------------------------------
-- Ret Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("RET", "999933", "PALADIN-3")

spec.buffs = {
    "All In!",
    "Empyrean Power",
    "Light's Deliverance",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "holypower3",
    "holypower5",
    "allinbuff",
    "empyreanpowerbuff",
    "lightsdeliverancebuff",
    "expurgationdot",
    "divinehammeravailable",
    "executionsentenceavailable",
    "wakeofashesavailable",
    "divinetollavailable",
    "judgmentavailable",
    "bladeofjusticeavailable",
    "hammerofwrathavailable",
    "hammeroflightavailable",
    "hold",
}

spec.options = {
    "hold",
}

spec.calcState = function(state)
    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holypower >= 3 then
        state.holypower3 = true
    end
    if holypower >= 5 then
        state.holypower5 = true
    end

    if Faceroll.isBuffActive("All In!") then
        state.allinbuff = true
    end
    if Faceroll.isBuffActive("Empyrean Power") then
        state.empyreanpowerbuff = true
    end
    if Faceroll.isBuffActive("Light's Deliverance") then
        state.lightsdeliverancebuff = true
    end

    if Faceroll.isDotActive("Expurgation") then
        state.expurgationdot = true
    end

    if Faceroll.isSpellAvailable("Divine Hammer") then
        state.divinehammeravailable = true
    end
    if Faceroll.isSpellAvailable("Execution Sentence") then
        state.executionsentenceavailable = true
    end
    if Faceroll.isSpellAvailable("Wake of Ashes") then
        state.wakeofashesavailable = true
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        state.divinetollavailable = true
    end
    if Faceroll.isSpellAvailable("Judgment") then
        state.judgmentavailable = true
    end
    if Faceroll.isSpellAvailable("Blade of Justice") then
        state.bladeofjusticeavailable = true
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        state.hammerofwrathavailable = true
    end

    if holAvailable then
        state.hammeroflightavailable = true
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = ""
        local hol = "N"
        if holAvailable then
            hol = "Y"
        end
        o = o .. "Hammer of Light: " .. hol .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "divinehammer",
    "executionsentence",
    "wakeofashes",
    "finalverdict",
    "divinestorm",
    "bladeofjustice",
    "divinetoll",
    "judgment",
    "hammerofwrath",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.hold and state.divinehammeravailable and state.holypower3 then
            return "divinehammer"

        elseif not state.hold and state.executionsentenceavailable then
            return "executionsentence"

        elseif not state.hold and state.hammeroflightavailable and state.holypower5 then
            return "wakeofashes"

        elseif not state.hold and state.allinbuff and state.holypower3 then
            return "finalverdict"

        -- elseif state.hammeroflightavailable and state.holypower5 and state.lightsdeliverancebuff then
        --     return "wakeofashes"

        elseif not state.hold and state.holypower5 then
            return "finalverdict"

        elseif state.bladeofjusticeavailable and not state.expurgationdot then
            return "bladeofjustice"

        elseif state.wakeofashesavailable then
            return "wakeofashes"

        elseif state.divinetollavailable then
            return "divinetoll"

        elseif state.empyreanpowerbuff then
            return "divinestorm"

        elseif not state.hammeroflightavailable and state.holypower3 then
            return "finalverdict"

        elseif state.judgmentavailable then
            return "judgment"

        elseif state.bladeofjusticeavailable then
            return "bladeofjustice"

        elseif state.hammerofwrathavailable then
            return "hammerofwrath"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if not state.hold and state.divinehammeravailable and state.holypower3 then
            return "divinehammer"

        elseif not state.hold and state.executionsentenceavailable then
            return "executionsentence"

        elseif not state.hold and state.hammeroflightavailable and state.holypower5 then
            return "wakeofashes"

        elseif not state.hold and ((state.holypower3 and state.allinbuff) or state.empyreanpowerbuff) then
            return "divinestorm"

        -- elseif state.hammeroflightavailable and state.lightsdeliverancebuff then
        --     return "wakeofashes"

        elseif not state.hold and state.holypower5 then
            return "divinestorm"

        elseif state.wakeofashesavailable then
            return "wakeofashes"

        elseif state.divinetollavailable then
            return "divinetoll"

        elseif not state.hold and not state.hammeroflightavailable and state.holypower3 then
            return "divinestorm"

        elseif state.judgmentavailable then
            return "judgment"

        elseif state.bladeofjusticeavailable then
            return "bladeofjustice"

        elseif state.hammerofwrathavailable then
            return "hammerofwrath"

        end
    end

    return nil
end
