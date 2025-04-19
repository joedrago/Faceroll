-----------------------------------------------------------------------------------------
-- Frost DK

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["pillaroffrost"] = { ["name"]="Pillar of Frost" },
    ["rime"] = { ["name"]="Rime" },
    ["icytalons"] = { ["name"]="Icy Talons" },
    ["deathanddecay"] = { ["name"]="Death and Decay" },
    ["killingmachine"] = { ["name"]="Killing Machine" },
})

local function calcBits()
    local bits = 0

    local rp = UnitPower("player")
    local runes = 0
    for i=1,6 do
        runes = runes + GetRuneCount(i)
    end

    if runes >= 1 then
        bits = bits + 0x1
    end
    if runes >= 2 then
        bits = bits + 0x2
    end
    if rp >= 30 then
        bits = bits + 0x4
    end

    if Faceroll.isBuffActive("pillaroffrost") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("rime") then
        bits = bits + 0x10
    end
    if Faceroll.getBuffRemaining("icytalons") > 3 then
        bits = bits + 0x20
    end
    if Faceroll.getBuffRemaining("deathanddecay") > 1.5 then
        bits = bits + 0x40
    end

    if Faceroll.getBuffStacks("killingmachine") >= 1 then
        bits = bits + 0x80
    end
    if Faceroll.getBuffStacks("killingmachine") >= 2 then
        bits = bits + 0x100
    end

    if Faceroll.isDotActive("Frost Fever") then
        bits = bits + 0x200
    end

    if Faceroll.isSpellAvailable("Death and Decay") then
        bits = bits + 0x400
    end
    if Faceroll.isSpellAvailable("Remorseless Winter") then
        bits = bits + 0x800
    end
    if Faceroll.isSpellAvailable("Pillar of Frost") then
        bits = bits + 0x1000
    end
    if Faceroll.isSpellAvailable("Abomination Limb") then
        bits = bits + 0x2000
    end
    if Faceroll.isSpellAvailable("Empower Rune Weapon") then
        bits = bits + 0x4000
    end

    return bits
end

Faceroll.registerSpec("DEATHKNIGHT-2", calcBits)
