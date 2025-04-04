-----------------------------------------------------------------------------------------
-- Shadow Priest

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["deathspeaker"] = { ["name"]="Deathspeaker" },
})

local function calcBits()
    local bits = 0
    local insanity = UnitPower("player")

    local targetlowhp = false
    local targethp = UnitHealth("target")
    local targethpmax = UnitHealthMax("target")
    if targethp > 0 and targethpmax > 0 and ((targethp / targethpmax) < 0.2) then
        targetlowhp = true
    end

    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    local castingSpellDone = 0
    if castingSpell then
        castingSpellDone = castingSpellEndTime / 1000 - GetTime()
        -- print("castingSpell " .. castingSpell .. " castingSpellDone " .. castingSpellDone)
    end

    if Faceroll.spellCooldown("Shadow Crash") < 1.5 then
        bits = bits + 0x1
    end
    if Faceroll.spellCooldown("Shadow Crash") >= 18 then
        bits = bits + 0x2
    end
    if Faceroll.spellCooldown("Shadow Crash") > 6 then
        bits = bits + 0x4
    end
    if Faceroll.spellCooldown("Devouring Plague") < 1.5 and insanity >= 45 then
        bits = bits + 0x8
    end
    if Faceroll.spellCooldown("Dark Ascension") < 1.5 then
        bits = bits + 0x10
    end
    if Faceroll.spellChargesSoon("Mind Blast", 1, 1.5) then
        bits = bits + 0x20
    end
    if Faceroll.spellCooldown("Void Torrent") < 1.5 then
        bits = bits + 0x40
    end
    if Faceroll.spellCooldown("Shadow Word: Death") < 1.5 and (Faceroll.isBuffActive("deathspeaker") or targetlowhp) then
        bits = bits + 0x80
    end

    if Faceroll.isDotActive("Vampiric Touch") < 0.3 and (castingSpell ~= "Vampiric Touch" or castingSpellDone > 0.5) then
        bits = bits + 0x100
    end
    if Faceroll.isDotActive("Devouring Plague") > 0.5 then
        bits = bits + 0x200
    end

    if Faceroll.spellChargesSoon("Mind Blast", 2, 1.5) then
        bits = bits + 0x400
    end

    if Faceroll.debug then
        local o = ""
        if castingSpell then
            o = o .. "castingSpell: " .. castingSpell .. "done: " .. castingSpellDone ..  "\n"
        end
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("PRIEST", 3, calcBits)
