-----------------------------------------------------------------------------------------
-- Frost Mage

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["winterschill"] = { ["name"]="Winter's Chill" },
    ["fingersoffrost"] = { ["name"]="Fingers of Frost" },
    ["excessfire"] = { ["name"]="Excess Fire" },
    ["excessfrost"] = { ["name"]="Excess Frost" },
    ["glacialspike"] = { ["name"]="Glacial Spike!" },
    ["frostfireempowerment"] = { ["name"]="Frostfire Empowerment" },
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

    if Faceroll.spellCooldown("Icy Veins") > 10 and Faceroll.spellCooldown("Comet Storm") > 10 then
        bits = bits + 0x200
    end
    if Faceroll.spellCooldown("Ray of Frost") > 10 and Faceroll.spellCooldown("Frozen Orb") > 10 then
        bits = bits + 0x400
    end

    if Faceroll.isBuffActive("frostfireempowerment") then
        bits = bits + 0x800
    end

    if Faceroll.isSpellAvailable("Blizzard") then
        bits = bits + 0x1000
    end
    if Faceroll.isSpellAvailable("Icy Veins") then
        bits = bits + 0x2000
    end
    if Faceroll.isSpellAvailable("Cone of Cold") then
        bits = bits + 0x4000
    end
    if Faceroll.spellCooldown("Cone of Cold") > 10 then
        bits = bits + 0x8000
    end

    if Faceroll.spellCooldown("Comet Storm") > 28 then
        bits = bits + 0x10000
    end

    -- if Faceroll.debug then
    --     local o = ""
    --     o = o .. "CS: " .. Faceroll.spellCooldown("Comet Storm") .. "\n"
    --     Faceroll.setDebugText(o)
    -- end

    return bits
end

Faceroll.registerSpec("MAGE-3", calcBits)
