-----------------------------------------------------------------------------------------
-- Arcane Mage

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["Clearcasting"] = { ["name"]="Clearcasting" },
    ["Nether Precision"] = { ["name"]="Nether Precision" },
    ["Intuition"] = { ["name"]="Intuition" },
    ["Arcane Harmony"] = { ["name"]="Arcane Harmony" },
    ["Arcane Surge"] = { ["name"]="Arcane Surge" },
})

local function calcBits()
    local bits = 0

    if Faceroll.isBuffActive("Clearcasting") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("Nether Precision") then
        bits = bits + 0x2
    end
    if Faceroll.isBuffActive("Intuition") then
        bits = bits + 0x4
    end
    if Faceroll.getBuffStacks("Arcane Harmony") >= 12 then
        bits = bits + 0x8
    end
    if Faceroll.getBuffStacks("Arcane Harmony") >= 18 then
        bits = bits + 0x10
    end

    if Faceroll.isSpellAvailable("Evocation") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Arcane Surge") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Touch of the Magi") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Arcane Orb") then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Shifting Power") then
        bits = bits + 0x200
    end

    local curMana = UnitPower("player", Enum.PowerType.Mana)
    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    local norMana = curMana / maxMana
    if norMana < 0.1 then
        bits = bits + 0x400
    end

    local arcaneCharges = UnitPower("player", Enum.PowerType.ArcaneCharges)
    if arcaneCharges >= 2 then
        bits = bits + 0x800
    end
    if arcaneCharges >= 3 then
        bits = bits + 0x1000
    end
    if arcaneCharges >= 4 then
        bits = bits + 0x2000
    end

    if Faceroll.isBuffActive("Arcane Surge") then
        bits = bits + 0x4000
    end

    local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
    local base = isGliding and forwardSpeed or GetUnitSpeed("player")
    local movespeed = Round(base / 7 * 100)
    if movespeed > 0 then
        bits = bits + 0x8000
    end

    if Faceroll.hold then
        bits = bits + 0x10000
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    if Faceroll.debug then
        local o = ""
        o = o .. "intuition    : " .. bt(Faceroll.getBuffStacks("Intuition") >= 18) .. "\n"
        o = o .. "arcaneharmony: " .. bt(Faceroll.isBuffActive("Arcane Harmony")) .. "\n"
        o = o .. "arcaneorb    : " .. bt(Faceroll.isSpellAvailable("Arcane Orb")) .. "\n"
        o = o .. "lowmana      : " .. bt(norMana < 0.1) .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("MAGE-1", calcBits)
