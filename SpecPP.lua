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

spec.actions = {
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

spec.states = {
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
}

spec.calcState = function(state)
    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holAvailable then
        state.holavailable = true
    end

    if holypower > 0 then
        state.holypower1 = true
    end
    if holypower >= 3 then
        state.holypower3 = true
    end

    -- some health threshold (60%?)
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Shining Light") > 0 then
        state.needsheal = true
    end

    if Faceroll.isBuffActive("Shake the Heavens") then
        state.shaketheheavensbuff = true
    end
    if Faceroll.isBuffActive("Blessing of Dawn") then
        state.blessingofdawnbuff = true
    end
    if Faceroll.isBuffActive("Consecration") then
        state.consecrationbuff = true
    end

    if Faceroll.isSpellAvailable("Blessed Hammer") then
        state.blessedhammer = true
    end
    if Faceroll.isSpellAvailable("Eye of Tyr") then
        state.eyeoftyr = true
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        state.divinetoll = true
    end
    if Faceroll.isSpellAvailable("Judgment") then
        state.judgment = true
    end
    if Faceroll.isSpellAvailable("Avenger's Shield") then
        state.avengersshield = true
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        state.hammerofwrath = true
    end
    if Faceroll.isSpellAvailable("Consecration") then
        state.consecration = true
    end

    if Faceroll.hold then
        state.holding = true
    end

    if UnitAffectingCombat("player") then
        state.incombat = true
    end

    return state
end

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
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

    elseif mode == Faceroll.MODE_AOE then
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
