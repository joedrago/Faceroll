-----------------------------------------------------------------------------------------
-- Vengeance Demon Hunter

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["metamorphosis"] = { ["name"]="Metamorphosis" },
    ["soulfragments"] = { ["name"]="Soul Fragments" },
})

local function calcBits()
    local bits = 0

    if Faceroll.isBuffActive("metamorphosis") then
        bits = bits + 0x1
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        bits = bits + 0x2
    end
    if Faceroll.isSpellAvailable("Fel Devastation") then
        bits = bits + 0x4
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        bits = bits + 0x8
    end
    if Faceroll.isSpellAvailable("Immolation Aura") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Felblade") then
        bits = bits + 0x40
    end
    if Faceroll.spellCharges("Fracture") > 0 then
        bits = bits + 0x80
    end

    local fury = UnitPower("player")
    if fury >= 30 then
        bits = bits + 0x100
    end
    if fury >= 40 then
        bits = bits + 0x200
    end
    if fury >= 50 then
        bits = bits + 0x400
    end
    if fury < 130 then
        bits = bits + 0x800
    end

    if Faceroll.getBuffStacks("soulfragments") >= 4 then
        bits = bits + 0x1000
    end
    if Faceroll.getBuffStacks("soulfragments") == 0 then
        bits = bits + 0x2000
    end

    if Faceroll.isDotActive("Fiery Brand") <= 0 and Faceroll.isSpellAvailable("Fiery Brand") then
        bits = bits + 0x4000
    end

    if Faceroll.isSpellAvailable("Sigil of Spite") then
        bits = bits + 0x8000
    end

    if Faceroll.debug then
        local o = ""
        local avl = "N"
        if Faceroll.isSpellAvailable("Fiery Brand") then
            avl = "Y"
        end
        o = o .. "dot(Fiery Brand): " .. Faceroll.isDotActive("Fiery Brand") .. "\n"
        o = o .. "avl(Fiery Brand): " .. avl .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("DEMONHUNTER", 2, calcBits)
