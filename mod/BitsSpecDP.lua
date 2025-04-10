-----------------------------------------------------------------------------------------
-- Discipline Priest

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["atonement"] = { ["name"]="Atonement" },
})

local function calcBits()
    local bits = 0

    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    local castingSpellDone = 0
    if castingSpell then
        castingSpellDone = castingSpellEndTime / 1000 - GetTime()
        -- print("castingSpell " .. castingSpell .. " castingSpellDone " .. castingSpellDone)
    end

    -- local needsRadiance = false
    -- for _,unit in ipairs({"player", "party1", "party2", "party3", "party4"}) do
    --     if UnitExists(unit) and not UnitIsDead(unit) then
    --         local remaining = Faceroll.isHotActive("Atonement", unit)
    --         if remaining < 2.5 then
    --             if UnitHealth(unit) < UnitHealthMax(unit) then
    --                 needsRadiance = true
    --             end
    --         end
    --     end
    -- end

    local reaction = UnitReaction("player", "target")
    if reaction ~= nil then
        if reaction < 5 then
            bits = bits + 0x1
        else
            bits = bits + 0x2
        end
    end

    if Faceroll.getBuffRemaining("atonement") < 2.5
    and (castingSpell ~= "Power Word: Radiance" or castingSpellDone > 0.5)
    and Faceroll.spellChargesSoon("Power Word: Radiance", 1, 1.5)
    then
        bits = bits + 0x4
    end

    if Faceroll.spellCooldown("Penance") < 1.5 then
        bits = bits + 0x8
    end
    if Faceroll.spellCooldown("Power Word: Shield") < 1.5 then
        bits = bits + 0x10
    end
    if Faceroll.spellCooldown("Mind Blast") < 1.5 then
        bits = bits + 0x20
    end
    if Faceroll.spellCooldown("Mindbender") < 1.5 then
        bits = bits + 0x40
    end

    if Faceroll.isDotActive("Shadow Word: Pain") < 0.3 then
        bits = bits + 0x80
    end

    return bits
end

Faceroll.registerSpec("PRIEST-1", calcBits)
