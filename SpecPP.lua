-----------------------------------------------------------------------------------------
-- Prot Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PP", "996600", "PALADIN-2")

spec.buffs = {
    "Shining Light",
    "Shake the Heavens",
    "Blessing of Dawn",
    "Consecration",
}

spec.abilities = {
    "blessedhammer",
    "judgment",
    "hammerofwrath",
    "eyeoftyr",
    "shieldoftherighteous",
    "avengersshield",
    "consecration",
    "divinetoll",
    "wordofglory",
}

local bits = Faceroll.createBits({
    "holavailable",
    "holypower1",
    "holypower3",
    "needsheal",
    "shaketheheavensbuff",
    "blessingofdawnbuff",
    "consecrationbuff",
    "blessedhammer",
    "eyeoftyr",
    "divinetoll",
    "judgment",
    "avengersshield",
    "hammerofwrath",
    "consecration",
    "holding",
    "incombat",
})

spec.calcBits = function()
    bits:reset()

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holAvailable then
        bits:enable("holavailable")
    end

    if holypower > 0 then
        bits:enable("holypower1")
    end
    if holypower >= 3 then
        bits:enable("holypower3")
    end

    -- some health threshold (60%?)
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Shining Light") > 0 then
        bits:enable("needsheal")
    end

    if Faceroll.isBuffActive("Shake the Heavens") then
        bits:enable("shaketheheavensbuff")
    end
    if Faceroll.isBuffActive("Blessing of Dawn") then
        bits:enable("blessingofdawnbuff")
    end
    if Faceroll.isBuffActive("Consecration") then
        bits:enable("consecrationbuff")
    end

    if Faceroll.isSpellAvailable("Blessed Hammer") then
        bits:enable("blessedhammer")
    end
    if Faceroll.isSpellAvailable("Eye of Tyr") then
        bits:enable("eyeoftyr")
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits:enable("divinetoll")
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits:enable("judgment")
    end
    if Faceroll.isSpellAvailable("Avenger's Shield") then
        bits:enable("avengersshield")
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits:enable("hammerofwrath")
    end
    if Faceroll.isSpellAvailable("Consecration") then
        bits:enable("consecration")
    end

    if Faceroll.hold then
        bits:enable("holding")
    end

    if UnitAffectingCombat("player") then
        bits:enable("incombat")
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
        -- Single Target

        if not state.incombat and not state.holypower3 and state.blessedhammer then
            return "blessedhammer"

        elseif state.needsheal then
            return "wordofglory"

        elseif not state.holypower3 and state.eyeoftyr then
            return "eyeoftyr"

        elseif state.holavailable and state.holypower3 and state.blessingofdawnbuff then
            return "eyeoftyr"

        elseif state.consecration and not state.consecrationbuff then
            return "consecration"

        elseif state.holypower3 then
            return "shieldoftherighteous"

        elseif not state.holypower3 and state.divinetoll then
            return "divinetoll"

        elseif state.hammerofwrath then
            return "hammerofwrath"

        elseif state.judgment then
            return "judgment"

        elseif not state.holding and state.avengersshield then
            return "avengersshield"

        elseif state.blessedhammer then
            return "blessedhammer"

        elseif state.consecration then
            return "consecration"

        end

    elseif action == Faceroll.ACTION_AOE then
        -- AOE

        if not state.incombat and not state.holypower3 and state.blessedhammer then
            return "blessedhammer"

        elseif state.needsheal then
            return "wordofglory"

        elseif not state.holypower3 and state.eyeoftyr then
            return "eyeoftyr"

        elseif state.holavailable and state.holypower3 and state.blessingofdawnbuff then
            return "eyeoftyr"

        elseif state.consecration and not state.consecrationbuff then
            return "consecration"

        elseif state.holypower3 then
            return "shieldoftherighteous"

        elseif not state.holding and state.avengersshield then
            return "avengersshield"

        elseif state.hammerofwrath then
            return "hammerofwrath"

        elseif state.judgment then
            return "judgment"

        elseif not state.holypower1 and state.divinetoll then
            return "divinetoll"

        elseif state.blessedhammer then
            return "blessedhammer"

        elseif state.consecration then
            return "consecration"

        end

    end

    return nil
end

Faceroll.registerSpec(spec)
