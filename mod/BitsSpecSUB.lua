-----------------------------------------------------------------------------------------
-- Subtlety Rogue

local _, Faceroll = ...

Faceroll.trackBuffs({
    -- Rogue
    ["shadowblades"] = { ["name"]="Shadow Blades" },
    ["symbolsofdeath"] = { ["name"]="Symbols of Death" },
    ["flagellation"] = { ["name"]="Flagellation" },
    ["premeditation"] = { ["name"]="Premeditation" },
    ["shadowdance"] = { ["name"]="Shadow Dance" },
    ["stealth"] = { ["name"]="Stealth" },
    ["vanish"] = { ["name"]="Vanish" },
    ["coldblood"] = { ["name"]="Cold Blood" },
    ["dansemacabre"] = { ["name"]="Danse Macabre" },
})

local bitMap = {
    -- player/base class state
    ["combat"]                      = 0x1,
    ["cp6"]                         = 0x2,
    ["stealth"]                     = 0x4,

    -- buffs
    ["shadowblades_active"]         = 0x10,
    ["symbolsofdeath_active"]       = 0x20,
    ["premeditation_active"]        = 0x40,
    ["shadowdance_active"]          = 0x80,
    ["coldblood_active"]            = 0x100,
    ["flagellation_active"]         = 0x200,
    ["flagellation_maxed"]          = 0x400,
    ["dansemacabre_low"]            = 0x800,

    -- cds
    ["shadowblades_available"]      = 0x1000,
    ["symbolsofdeath_available"]    = 0x2000,
    ["shadowdance_available"]       = 0x4000,
    ["coldblood_available"]         = 0x8000,
    ["flagellation_available"]      = 0x10000,
    ["flagellation_soon"]           = 0x20000,
    ["vanish_available"]            = 0x40000,
    ["secrettechnique_available"]  = 0x80000,
    ["secrettechnique_soon"]       = 0x100000,

    -- target debuffs
    ["should_rupture"]              = 0x200000,
}

local function calcBits()
    local bits = 0

    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    -- player/base class state
    if UnitAffectingCombat("player") then
        bits = bits + bitMap["combat"]
    end
    if cp >= 6 then
        bits = bits + bitMap["cp6"]
    end
    if Faceroll.isBuffActive("stealth") or Faceroll.isBuffActive("vanish") then
        bits = bits + bitMap["stealth"]
    end

    -- buffs
    if Faceroll.isBuffActive("shadowblades") then
        bits = bits + bitMap["shadowblades_active"]
    end
    if Faceroll.isBuffActive("symbolsofdeath") then
        bits = bits + bitMap["symbolsofdeath_active"]
    end
    if Faceroll.isBuffActive("premeditation") then
        bits = bits + bitMap["premeditation_active"]
    end
    if Faceroll.isBuffActive("shadowdance") then
        bits = bits + bitMap["shadowdance_active"]
    end
    if Faceroll.isBuffActive("coldblood") then
        bits = bits + bitMap["coldblood_active"]
    end
    if Faceroll.isBuffActive("flagellation") then
        bits = bits + bitMap["flagellation_active"]
    end
    if Faceroll.getBuffStacks("flagellation") >= 30 then
        bits = bits + bitMap["flagellation_maxed"]
    end
    if Faceroll.getBuffStacks("dansemacabre") <= 2 then
        bits = bits + bitMap["dansemacabre_low"]
    end

    -- cds
    if Faceroll.isSpellAvailable("Shadow Blades") then
        bits = bits + bitMap["shadowblades_available"]
    end
    if Faceroll.spellCharges("Symbols of Death") > 0 then
        bits = bits + bitMap["symbolsofdeath_available"]
    end
    if Faceroll.spellCharges("Shadow Dance") > 0 then
        bits = bits + bitMap["shadowdance_available"]
    end
    if Faceroll.isSpellAvailable("Cold Blood") then
        bits = bits + bitMap["coldblood_available"]
    end
    if Faceroll.isSpellAvailable("flagellation") then
        bits = bits + bitMap["flagellation_available"]
    end
    if Faceroll.spellCooldown("flagellation") < 30 and Faceroll.spellCooldown("flagellation") > 1.5 then
        bits = bits + bitMap["flagellation_soon"]
    end
    if Faceroll.isSpellAvailable("vanish") then
        bits = bits + bitMap["vanish_available"]
    end
    if Faceroll.spellCooldown("Secret Technique") < 1.5 then
        bits = bits + bitMap["secrettechnique_available"]
    end
    if Faceroll.spellCooldown("Secret Technique") < 10 then
        bits = bits + bitMap["secrettechnique_soon"]
    end

    -- target debuffs
    if Faceroll.isDotActive("Rupture") < .3 then
        bits = bits + bitMap["should_rupture"]
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    if Faceroll.debug then
        local o = ""
        
        o = o .. "SD: " .. bt(Faceroll.isBuffActive("shadowdance")) .. "\n"
        
        local stAvailable = Faceroll.spellCooldown("Secret Technique") < 1.5
        o = o .. "ST: " .. bt(stAvailable) .. "\n"

        Faceroll.setDebugText(o)
    end
    return bits
end

Faceroll.registerSpec("ROGUE-3", calcBits)
