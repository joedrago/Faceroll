-----------------------------------------------------------------------------------------
-- Survival Hunter

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["lunarstorm"] = { ["name"]="Lunar Storm", ["harmful"]=true },
    ["strikeitrich"] = { ["name"]="Strike it Rich" },
    ["tipofthespear"] = { ["name"]="Tip of the Spear" },
})

local function calcBits()
    local bits = 0
    if not Faceroll.isBuffActive("lunarstorm") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("strikeitrich") then
        bits = bits + 0x2
    end
    if Faceroll.isBuffActive("tipofthespear") then
        bits = bits + 0x4
    end
    if Faceroll.spellCharges("Wildfire Bomb") >= 2 then
        bits = bits + 0x8
    end
    if Faceroll.spellCharges("Wildfire Bomb") >= 1 then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Butchery") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Kill Command") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Kill Shot") then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Fury of the Eagle") then
        bits = bits + 0x200
    end
    if UnitPower("player") > 85 then
        bits = bits + 0x400
    end
    return bits
end

Faceroll.registerSpec("HUNTER", 3, calcBits)
