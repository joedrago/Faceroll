-----------------------------------------------------------------------------------------
-- Elemental Shaman

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["tempest"] = { ["name"]="Tempest" },
    ["icefury"] = { ["name"]="Icefury" },
    ["ascendance"] = { ["name"]="Ascendance" },
    ["echoesofgreatsundering"] = { ["name"]="Echoes of Great Sundering" },
    ["masteroftheelements"] = { ["name"]="Master of the Elements" },
    ["fusionofelements"] = { ["name"]="Fusion of Elements" },
})

local function calcBits()
    local bits = 0
    if Faceroll.isBuffActive("tempest") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("icefury") then
        bits = bits + 0x2
    end
    if Faceroll.isBuffActive("ascendance") then
        bits = bits + 0x4
    end
    if Faceroll.isBuffActive("echoesofgreatsundering") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("masteroftheelements") then
        bits = bits + 0x10
    end
    if Faceroll.isBuffActive("fusionofelements") then
        bits = bits + 0x20
    end

    if Faceroll.isDotActive("Flame Shock") >= 0.3 then
        bits = bits + 0x40
    end

    if Faceroll.isSpellAvailable("Stormkeeper") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Lava Burst") then
        bits = bits + 0x100
    end

    local maelstrom = UnitPower("player")
    if maelstrom >= 60 then
        -- enough for earthquake
        bits = bits + 0x200
    end
    if maelstrom >= 90 then
        -- enough for elemental blast
        bits = bits + 0x400
    end
    if maelstrom >= 125 then
        -- 25 from cap
        bits = bits + 0x800
    end
    return bits
end

Faceroll.registerSpec("SHAMAN", 1, calcBits)
