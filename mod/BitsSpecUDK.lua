-----------------------------------------------------------------------------------------
-- Unholy DK

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["suddendoom"] = { ["name"]="Sudden Doom" },
    ["plaguebringer"] = { ["name"]="Plaguebringer" },
    ["deathanddecay"] = { ["name"]="Death and Decay" },
    ["festeringscythe"] = { ["name"]="Festering Scythe" },
})

local function calcBits()
    local bits = 0

    local targetlowhp = false
    local targethp = UnitHealth("target")
    local targethpmax = UnitHealthMax("target")
    if targethp > 0 and targethpmax > 0 and ((targethp / targethpmax) < 0.35) then
        targetlowhp = true
    end

    local runicpower = UnitPower("player")
    local wounds = Faceroll.dotStacks("Festering Wound")

    local runecount = 0
    for i=1,6 do
        runecount = runecount + GetRuneCount(i)
    end

    if (not UnitExists("pet") or not UnitIsVisible("pet")) and Faceroll.isSpellAvailable("Raise Dead") then
        bits = bits + 0x1
    end

    if Faceroll.isSpellAvailable("Raise Abomination") then
        bits = bits + 0x2
    end
    if Faceroll.isSpellAvailable("Abomination Limb") then
        bits = bits + 0x4
    end
    if Faceroll.isSpellAvailable("Dark Transformation") then
        bits = bits + 0x8
    end
    if Faceroll.isSpellAvailable("Unholy Assault") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Apocalypse") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Soul Reaper") and targetlowhp then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Death Coil") and (runicpower > 80 or Faceroll.isBuffActive("suddendoom")) then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Outbreak") and not (Faceroll.isDotActive("Blood Plague") or Faceroll.isDotActive("Frost Fever") or Faceroll.isDotActive("Virulent Plague")) then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Festering Strike") and wounds < 3 then
        bits = bits + 0x200
    end
    if Faceroll.isSpellAvailable("Scourge Strike") and not Faceroll.isBuffActive("plaguebringer") then
        bits = bits + 0x400
    end
    if Faceroll.isSpellAvailable("Death Coil") and not Faceroll.isDotActive("Death Rot") then
        bits = bits + 0x800
    end
    if Faceroll.isSpellAvailable("Scourge Strike") and wounds >= 3 then
        bits = bits + 0x1000
    end
    if Faceroll.isSpellAvailable("Epidemic") and runicpower >= 30 and Faceroll.isBuffActive("suddendoom") then
        bits = bits + 0x2000
    end
    if Faceroll.isSpellAvailable("Epidemic") and runicpower >= 30 and runecount < 2 then
        bits = bits + 0x4000
    end
    if Faceroll.isBuffActive("deathanddecay") then
        bits = bits + 0x8000
    end
    if Faceroll.isSpellAvailable("Outbreak") and not Faceroll.isDotActive("Virulent Plague") and not Faceroll.isSpellAvailable("Dark Transformation") then
        bits = bits + 0x10000
    end
    if Faceroll.isSpellAvailable("Festering Strike") and Faceroll.isBuffActive("festeringscythe") then
        bits = bits + 0x20000
    end
    if runecount > 0 and wounds > 0 then
        bits = bits + 0x40000
    end
    if Faceroll.isSpellAvailable("Outbreak") and not Faceroll.isDotActive("Virulent Plague") then
        bits = bits + 0x80000
    end

    return bits
end

Faceroll.registerSpec("DEATHKNIGHT-3", calcBits)
