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

spec.abilities = {
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

local bits = Faceroll.createBits({
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
    "holding",
})

spec.calcBits = function()
    bits:reset()

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holypower >= 3 then
        bits:enable("holypower3")
    end
    if holypower >= 5 then
        bits:enable("holypower5")
    end

    if Faceroll.isBuffActive("All In!") then
        bits:enable("allinbuff")
    end
    if Faceroll.isBuffActive("Empyrean Power") then
        bits:enable("empyreanpowerbuff")
    end
    if Faceroll.isBuffActive("Light's Deliverance") then
        bits:enable("lightsdeliverancebuff")
    end

    if Faceroll.isDotActive("Expurgation") then
        bits:enable("expurgationdot")
    end

    if Faceroll.isSpellAvailable("Divine Hammer") then
        bits:enable("divinehammeravailable")
    end
    if Faceroll.isSpellAvailable("Execution Sentence") then
        bits:enable("executionsentenceavailable")
    end
    if Faceroll.isSpellAvailable("Wake of Ashes") then
        bits:enable("wakeofashesavailable")
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits:enable("divinetollavailable")
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits:enable("judgmentavailable")
    end
    if Faceroll.isSpellAvailable("Blade of Justice") then
        bits:enable("bladeofjusticeavailable")
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits:enable("hammerofwrathavailable")
    end

    if holAvailable then
        bits:enable("hammeroflightavailable")
    end

    if Faceroll.hold then
        bits:enable("holding")
    end

    if Faceroll.debug then
        local o = ""
        local hol = "N"
        if holAvailable then
            hol = "Y"
        end
        o = o .. "Hammer of Light: " .. hol .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
        -- Single Target

        if not state.holding and state.divinehammeravailable and state.holypower3 then
            return "divinehammer"

        elseif not state.holding and state.executionsentenceavailable then
            return "executionsentence"

        elseif not state.holding and state.hammeroflightavailable and state.holypower5 then
            return "wakeofashes"

        elseif not state.holding and state.allinbuff and state.holypower3 then
            return "finalverdict"

        -- elseif state.hammeroflightavailable and state.holypower5 and state.lightsdeliverancebuff then
        --     return "wakeofashes"

        elseif not state.holding and state.holypower5 then
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

    elseif action == Faceroll.ACTION_AOE then
        -- AOE

        if not state.holding and state.divinehammeravailable and state.holypower3 then
            return "divinehammer"

        elseif not state.holding and state.executionsentenceavailable then
            return "executionsentence"

        elseif not state.holding and state.hammeroflightavailable and state.holypower5 then
            return "wakeofashes"

        elseif not state.holding and ((state.holypower3 and state.allinbuff) or state.empyreanpowerbuff) then
            return "divinestorm"

        -- elseif state.hammeroflightavailable and state.lightsdeliverancebuff then
        --     return "wakeofashes"

        elseif not state.holding and state.holypower5 then
            return "divinestorm"

        elseif state.wakeofashesavailable then
            return "wakeofashes"

        elseif state.divinetollavailable then
            return "divinetoll"

        elseif not state.holding and not state.hammeroflightavailable and state.holypower3 then
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

Faceroll.registerSpec(spec)
