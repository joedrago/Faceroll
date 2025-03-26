-----------------------------------------------------------------------------------------
-- Elemental Shaman

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["tempest"] = {
        ["id"]=0,
        ["name"]="Tempest",
    },
})

local function calcBits()
    local bits = 0
    if Faceroll.isBuffActive("tempest") then
        bits = bits + 0x1
    end
    if UnitPower("player") >= 55 then
        bits = bits + 0x2
    end
    local name, _, _, _, fullDuration, expirationTime = AuraUtil.FindAuraByName("Flame Shock", "target", "HARMFUL")
    if (name ~= nil) then
        local remainingDuration = expirationTime - GetTime()
        if remainingDuration > (fullDuration * 0.3) then
            bits = bits + 0x4
        end
    end
    if Faceroll.isSpellAvailable("Stormkeeper") then
        bits = bits + 0x8
    end
    return bits
end

Faceroll.registerSpec("SHAMAN", 1, calcBits)
