-----------------------------------------------------------------------------------------
-- Beast Mastery Hunter

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["frenzy"] = { ["name"]="Thrill of the Hunt" }, -- yes this is weird but TotH and Frenzy line up exactly
    ["beastcleave"] = { ["name"]="Beast Cleave" },
    ["hogstrider"] = { ["name"]="Hogstrider" },
})

local function calcBits()
    local bits = 0

    local barbedShotCharges = Faceroll.spellCharges("Barbed Shot")
    local barbedShotTwoChargesSoon = Faceroll.spellChargesSoon("Barbed Shot", 2, 2.5)
    local killCommandCharges = Faceroll.spellCharges("Kill Command")
    if barbedShotCharges > 0 then
        if Faceroll.getBuffRemaining("frenzy") < 2
        or barbedShotTwoChargesSoon
        or barbedShotCharges > killCommandCharges
        or Faceroll.spellCooldown("Bestial Wrath") < 5
        then
            bits = bits + 0x1
        end
    end

    if Faceroll.isSpellAvailable("Bestial Wrath") then
        bits = bits + 0x2
    end
    if Faceroll.isSpellAvailable("Kill Command") then
        bits = bits + 0x4
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        bits = bits + 0x8
    end
    if Faceroll.isSpellAvailable("Dire Beast") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Barbed Shot") then
        bits = bits + 0x20
    end
    if barbedShotTwoChargesSoon then
        bits = bits + 0x40
    end

    if Faceroll.isBuffActive("hogstrider") then
        bits = bits + 0x80
    end
    if Faceroll.isBuffActive("beastcleave") then
        bits = bits + 0x100
    end
    if Faceroll.getBuffRemaining("beastcleave") < 2.5 then
        bits = bits + 0x200
    end

    local energy = UnitPower("player")
    if energy >= 85 then
        bits = bits + 0x400
    end
    return bits
end

Faceroll.registerSpec("HUNTER-1", calcBits)
