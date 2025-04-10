-----------------------------------------------------------------------------------------
-- Outlaw Rogue

local _, Faceroll = ...

Faceroll.trackBuffs({
    -- Rogue
    ["adrenalinerush"] = { ["name"]="Adrenaline Rush" },
    ["bladeflurry"] = { ["name"]="Blade Flurry" },
    ["ruthlessprecision"] = { ["name"]="Ruthless Precision" },
    ["subterfuge"] = { ["name"]="Subterfuge" },
    ["stealth"] = { ["name"]="Stealth" },
    ["vanish"] = { ["name"]="Vanish" },
    ["opportunity"] = { ["name"]="Opportunity" },
    ["audacity"] = { ["name"]="Audacity" },

    -- Roll the bones buffs (the first 3 are "the good ones")
    ["rtb1"] = { ["name"]="Broadside" },
    ["rtb2"] = { ["name"]="True Bearing" },
    ["rtb3"] = { ["name"]="Ruthless Precision" },
    ["rtb4"] = { ["name"]="Skull and Crossbones" },
    ["rtb5"] = { ["name"]="Buried Treasure" },
    ["rtb6"] = { ["name"]="Grand Melee" },
})

local function calcBits()
    local bits = 0

    local kirCount = 0
    local goodRtbCount = 0
    local rtbCount = 0

    local rtbShortest = 1000
    for rtbIndex = 1,6 do
        local rtbName = "rtb" .. rtbIndex
        if Faceroll.isBuffActive(rtbName) then
            if rtbIndex <= 3 then
                goodRtbCount = goodRtbCount + 1
            end
            kirCount = kirCount + 1
            if not Faceroll.getBuff(rtbName).cto then
                rtbCount = rtbCount + 1
            end
            local remaining = math.max(Faceroll.getBuff(rtbName).expirationTime - GetTime(), 0)
            if rtbShortest > remaining then
                rtbShortest = remaining
            end
        end
    end

    -- print("rtbCount " .. rtbCount .. " goodRtbCount " .. goodRtbCount .. " kirCount " .. kirCount)

    local energy = UnitPower("player")
    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    if (kirCount >= 4 and rtbShortest < 2) or (kirCount >= 6) then
        bits = bits + 0x1
    end
    if rtbCount <= 2 and goodRtbCount == 0 or Faceroll.rtbNeedsAPressAfterKIR then
        bits = bits + 0x2
    end

    if Faceroll.isBuffActive("adrenalinerush") then
        bits = bits + 0x4
    end
    if not Faceroll.isBuffActive("bladeflurry") and Faceroll.isSpellAvailable("Blade Flurry") then
        -- tracking "should I blade flurry"
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("ruthlessprecision") then
        bits = bits + 0x10
    end
    if Faceroll.isBuffActive("subterfuge") then
        bits = bits + 0x20
    end
    if Faceroll.isBuffActive("stealth") or Faceroll.isBuffActive("vanish") then
        bits = bits + 0x40
    end
    if Faceroll.isBuffActive("opportunity") then
        bits = bits + 0x80
    end
    if Faceroll.isBuffActive("audacity") then
        bits = bits + 0x100
    end

    if Faceroll.isSpellAvailable("Keep It Rolling") then
        bits = bits + 0x200
    end
    if Faceroll.isSpellAvailable("Adrenaline Rush") then
        bits = bits + 0x400
    end
    if Faceroll.isSpellAvailable("Between the Eyes") then
        bits = bits + 0x800
    end
    if Faceroll.isSpellAvailable("Vanish") then
        bits = bits + 0x1000
    end
    if Faceroll.isSpellAvailable("Roll the Bones") then
        bits = bits + 0x2000
    end

    if cp >= 5 then
        bits = bits + 0x4000
    end
    if cp >= 6 then
        bits = bits + 0x8000
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    if Faceroll.debug then
        local rtbRem = math.max(Faceroll.rtbEnd - GetTime(), 0)
        local o = ""
        o = o .. "rtbStart: " .. Faceroll.rtbStart .. "\n"
        o = o .. "rtbEnd  : " .. Faceroll.rtbEnd .. "\n"
        o = o .. "rtbRem  : " .. rtbRem .. "\n"
        o = o .. "\n"
        o = o .. "rtbCount: " .. rtbCount .. "\n"
        o = o .. "kirCount: " .. kirCount .. "\n"
        o = o .. "rtbNeeds: " .. bt(Faceroll.rtbNeedsAPressAfterKIR) .. "\n"
        o = o .. "\n"
        o = o .. "rtbShort: " .. rtbShortest .. "\n"
        o = o .. "\n"
        for rtbIndex = 1,6 do
            local rtbName = "rtb" .. rtbIndex
            local rtbBuff = Faceroll.getBuff(rtbName)
            o = o .. rtbName .. ": remain: " .. bt(rtbBuff.remain) .. " cto: " .. bt(rtbBuff.cto) .. "  [" .. rtbBuff.id .. "]\n"
        end
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("ROGUE-2", calcBits)
