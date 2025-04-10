-----------------------------------------------------------------------------------------
-- Druid Bear

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["galacticguardian"] = { ["name"]="Galactic Guardian" },
    ["frenziedregeneration"] = { ["name"]="Frenzied Regeneration" },
    ["ironfur"] = { ["name"]="Ironfur" },
})

local function calcBits()
    local bits = 0

    local ggremaining = Faceroll.getBuffRemaining("galacticguardian")
    if ggremaining > 0 and ggremaining < 3 then
        bits = bits + 0x1
    end

    if Faceroll.getBuffStacks("ironfur") < 5 then
        bits = bits + 0x2
    end

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Frenzied Regeneration") > 0 and Faceroll.getBuffStacks("frenziedregeneration") < 2 then
        bits = bits + 0x4
    end

    return bits
end

Faceroll.registerSpec("DRUID-3", calcBits)
