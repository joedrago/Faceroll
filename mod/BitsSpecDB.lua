-----------------------------------------------------------------------------------------
-- Druid Bear

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["galacticguardian"] = { ["name"]="Galactic Guardian" },
    ["frenziedregeneration"] = { ["name"]="Frenzied Regeneration" },
    ["toothandclaw"] = { ["name"]="Tooth and Claw" },
    ["ironfur"] = { ["name"]="Ironfur" },
})

local function calcBits()
    local bits = 0

    -- bear form
    if GetShapeshiftForm() == 1 then
        bits = bits + 0x1
    end

    -- galactic guardian
    local ggremaining = Faceroll.getBuffRemaining("galacticguardian")
    if ggremaining > 0 and ggremaining < 3 then
        bits = bits + 0x2
    end

    -- thrash available
    if Faceroll.isSpellAvailable("Thrash") then
        bits = bits + 0x4
    end

    if Faceroll.isSpellAvailable("Mangle") then
        bits = bits + 0x8
    end

    if Faceroll.isSpellAvailable("Lunar Beam") then
        bits = bits + 0x10
    end

    -- ironfur stacks
    if Faceroll.getBuffStacks("ironfur") < 2 then
        bits = bits + 0x20
    end

    if Faceroll.getBuffStacks("toothandclaw") > 0 then
        bits = bits + 0x40
    end

    -- do i have >=40 rage
    local rage = UnitPower("player", Enum.PowerType.Rage)
    if rage >= 40 then
        bits = bits + 0x80
    end

    -- some health threshold (60%?)
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Frenzied Regeneration") > 0 and Faceroll.getBuffStacks("frenziedregeneration") < 2 then
        bits = bits + 0x100
    end

    return bits
end

Faceroll.registerSpec("DRUID-3", calcBits)
