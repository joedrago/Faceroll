-----------------------------------------------------------------------------------------
-- Havoc Demon Hunter

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["metamorphosis"] = { ["name"]="Metamorphosis" },
    ["essencebreak"] = { ["name"]="Essence Break" },
})

local function calcBits()
    local bits = 0

    if Faceroll.isBuffActive("metamorphosis") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("essencebreak") then
        bits = bits + 0x2
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        bits = bits + 0x4
    end
    if Faceroll.isSpellAvailable("Essence Break") then
        bits = bits + 0x8
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Eye Beam") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Blade Dance") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Felblade") then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Immolation Aura") then
        bits = bits + 0x200
    end

    local fury = UnitPower("player")
    if fury >= 40 then
        bits = bits + 0x400
    end
    if fury < 130 then
        bits = bits + 0x800
    end
    if fury < 140 then
        bits = bits + 0x1000
    end

    return bits
end

Faceroll.registerSpec("DEMONHUNTER", 1, calcBits)
