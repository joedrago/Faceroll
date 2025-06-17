-----------------------------------------------------------------------------------------
-- Prot Paladin

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["Shining Light"] = { ["name"]="Shining Light" },
    ["Shake the Heavens"] = { ["name"]="Shake the Heavens" },
    ["Blessing of Dawn"] = { ["name"]="Blessing of Dawn" },
    ["Consecration"] = { ["name"]="Consecration" },
})

local function calcBits()
    local bits = 0

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holAvailable then
        bits = bits + 0x1
    end

    if holypower > 0 then
        bits = bits + 0x2
    end
    if holypower >= 3 then
        bits = bits + 0x4
    end

    -- some health threshold (60%?)
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Shining Light") > 0 then
        bits = bits + 0x8
    end

    if Faceroll.isBuffActive("Shake the Heavens") then
        bits = bits + 0x10
    end
    if Faceroll.isBuffActive("Blessing of Dawn") then
        bits = bits + 0x20
    end
    if Faceroll.isBuffActive("Consecration") then
        bits = bits + 0x40
    end

    if Faceroll.isSpellAvailable("Blessed Hammer") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Eye of Tyr") then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits = bits + 0x200
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits = bits + 0x400
    end
    if Faceroll.isSpellAvailable("Avenger's Shield") then
        bits = bits + 0x800
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits = bits + 0x1000
    end
    if Faceroll.isSpellAvailable("Consecration") then
        bits = bits + 0x2000
    end

    if Faceroll.hold then
        bits = bits + 0x4000
    end

    if UnitAffectingCombat("player") then
        bits = bits + 0x8000
    end

    return bits
end

Faceroll.registerSpec("PALADIN-2", calcBits)
