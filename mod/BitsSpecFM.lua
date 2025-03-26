-----------------------------------------------------------------------------------------
-- Frost Mage

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["winterschill"] = {
        ["id"]=0,
        ["name"]="Winter's Chill",
    },
    ["fingersoffrost"] = {
        ["id"]=0,
        ["name"]="Fingers of Frost",
    },
    ["excessfire"] = {
        ["id"]=0,
        ["name"]="Excess Fire",
    },
    ["excessfrost"] = {
        ["id"]=0,
        ["name"]="Excess Frost",
    },
    ["glacialspike"] = {
        ["id"]=0,
        ["name"]="Glacial Spike!",
    },
})

local function calcBits()
    local bits = 0

    if Faceroll.isBuffActive("winterschill") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("fingersoffrost") then
        bits = bits + 0x2
    end
    if Faceroll.isBuffActive("excessfire") then
        bits = bits + 0x4
    end
    if Faceroll.isBuffActive("excessfrost") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("glacialspike") then
        bits = bits + 0x10
    end

    if Faceroll.isSpellAvailable("Frozen Orb") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Comet Storm") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Flurry") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Shifting Power") then
        bits = bits + 0x100
    end

    return bits
end

Faceroll.registerSpec("MAGE", 3, calcBits)
