-----------------------------------------------------------------------------------------
-- Marksmanship Hunter

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["trickshots"] = {
        ["id"]=0,
        ["name"]="Trick Shots",
    },
    ["streamline"] = {
        ["id"]=0,
        ["name"]="Streamline",
    },
    ["preciseshots"] = {
        ["id"]=0,
        ["name"]="Precise Shots",
    },
    ["spottersmark"] = {
        ["id"]=0,
        ["name"]="Spotter's Mark",
    },
    ["movingtarget"] = {
        ["id"]=0,
        ["name"]="Moving Target",
    },
})

local function calcBits()
    local bits = 0
    if Faceroll.isBuffActive("trickshots") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("streamline") then
        bits = bits + 0x2
    end
    if Faceroll.isBuffActive("preciseshots") then
        bits = bits + 0x4
    end
    if Faceroll.isBuffActive("spottersmark") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("movingtarget") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Aimed Shot") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Rapid Fire") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Kill Shot") then
        bits = bits + 0x100
    end
    if UnitPower("player") < 30 then
        bits = bits + 0x200
    end
    return bits
end

Faceroll.registerSpec("HUNTER", 2, calcBits)
