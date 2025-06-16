-----------------------------------------------------------------------------------------
-- Holy Paladin

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["Consecration"] = { ["name"]="Consecration" },
})

local function calcBits()
    local bits = 0

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    if holypower < 5 then
        bits = bits + 0x1
    end

    if Faceroll.isSpellAvailable("Crusader Strike") then
        bits = bits + 0x2
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits = bits + 0x4
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits = bits + 0x8
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Consecration") then
        bits = bits + 0x20
    end

    return bits
end

Faceroll.registerSpec("PALADIN-1", calcBits)
