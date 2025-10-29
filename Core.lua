if Faceroll == nil then
    _, Faceroll = ...
end

-----------------------------------------------------------------------------------------
-- Faceroll Globals

Faceroll.keys = {}
Faceroll.options = {}
Faceroll.classic = false
Faceroll.ascension = false
if WOW_PROJECT_ID == nil then
    Faceroll.classic = true
    Faceroll.ascension = true
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    Faceroll.classic = true
end
Faceroll.leftCombat = 0
Faceroll.moving = false
Faceroll.movingStopped = 0
Faceroll.updateBitsCounter = 0
Faceroll.targetChanged = false
Faceroll.active = false

local nextSpec = 0
Faceroll.SPEC_OFF = 0
Faceroll.SPEC_LAST = 0
Faceroll.availableSpecs = {}
Faceroll.activeSpecsByIndex = {}
Faceroll.activeSpecsByKey = {}

-----------------------------------------------------------------------------------------
-- Helpers

Faceroll.textColor = function(text, color)
    return "\124cff" .. color .. text .. "\124r"
end

Faceroll.isSeparatorName = function(name)
    return (string.find(name, "^[- ]") ~= nil)
end

-----------------------------------------------------------------------------------------
-- Spec Management

Faceroll.createSpec = function(name, color, specKey)
    local spec = {
        ["name"]=name,
        ["color"]=color,
        ["key"]=specKey,
        ["calcState"]=nil,
        ["calcAction"]=nil,
        ["buffs"]=nil,
        ["overlay"]={},
        ["actions"]={},
        ["options"]={},
        ["keys"]={},
        ["index"]=nil,
    }
    table.insert(Faceroll.availableSpecs, spec)
    return spec
end

Faceroll.createState = function(spec)
    local state = {}
    for _,name in ipairs(spec.options) do
        if Faceroll.options[name] ~= nil then
            state[name] = true
        end
    end
    return state
end

Faceroll.initSpecs = function()
    for _, spec in ipairs(Faceroll.availableSpecs) do
        Faceroll.activeSpecsByIndex[nextSpec] = spec
        nextSpec = nextSpec + 1
        spec.index = #Faceroll.activeSpecsByIndex
        Faceroll.SPEC_LAST = #Faceroll.activeSpecsByIndex
        if Faceroll.activeSpecsByKey[spec.key] ~= nil then
            print("WARNING: Multiple specs for the same key active! Overriding preexisting spec key: " .. spec.key)
        end
        Faceroll.activeSpecsByKey[spec.key] = spec
        -- print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. "), ".. bitCount .. "/28 bits, " .. actionCount .. " actions")
    end

    for _, spec in ipairs(Faceroll.activeSpecsByIndex) do
        if spec.actions ~= nil then
            for index, action in ipairs(spec.actions) do
                local key = Faceroll.keys[action]
                if key == nil then
                    key = Faceroll.keys[index]
                end
                if key ~= nil then
                    -- print("["..spec.name.."] " .. action .. " -> " .. key)
                    spec.keys[action] = key
                else
                    -- print("["..spec.name.."] " .. action .. " -> UNMAPPED")
                end
            end
        end
    end

    print("Faceroll.activateSpecs(): " .. #Faceroll.activeSpecsByIndex .. " available specs.")
end

Faceroll.activeSpec = function()
    local _, playerClass = UnitClass("player")
    local specIndex = "CLASSIC"
    if Faceroll.ascension then
        specIndex = "ASCENSION"
        local mysticLego = MysticEnchantUtil.GetLegendaryEnchantID("player")
        if mysticLego ~= nil then
            local mysticLegoName = GetSpellInfo(mysticLego)
            if mysticLegoName ~= nil then
                specIndex = mysticLegoName
            end
        end
    elseif not Faceroll.classic then
        if GetSpecialization ~= nil then
            specIndex = GetSpecialization()
        end
    end
    if playerClass == nil or specIndex == nil then
        return nil
    end
    local specKey = playerClass .. "-" .. specIndex
    local spec = Faceroll.activeSpecsByKey[specKey]
    return spec
end

Faceroll.createSpec("OFF", "333333", "OFF")

-----------------------------------------------------------------------------------------
-- Generic "Frame" Creation (UI Elements)

local FONTS = {
    ["firamono"]="Interface\\AddOns\\Faceroll\\fonts\\FiraMono-Medium.ttf",
    ["forcedsquare"]="Interface\\AddOns\\Faceroll\\fonts\\FORCED SQUARE.ttf",
}

Faceroll.createFrame = function(
    width, height,
    corner, x, y,
    strata, alpha,
    justify, font, fontSize)

    local frFrame = {}

    local frame = CreateFrame("Frame")
    frame:SetPoint(corner, x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetFrameStrata(strata)
    local text = frame:CreateFontString(nil, "ARTWORK")
    text:SetFont(FONTS[font], fontSize, "OUTLINE")
    text:SetPoint(justify, 0,0)
    if justify == "TOPLEFT" then
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
    end
    frame.texture = frame:CreateTexture()
    frame.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    frame.texture:SetVertexColor(0.0, 0.0, 0.0, alpha)
    frame.texture:SetAllPoints(text)
    text:Show()
    frame:Show()

    frFrame.frame = frame
    frFrame.text = text
    frFrame.setText = function(self, text)
        self.text:SetText(text)
    end
    return frFrame
end

-----------------------------------------------------------------------------------------
-- Debug Overlay Shenanigans

Faceroll.DEBUG_OFF = 0
Faceroll.DEBUG_ON = 1
Faceroll.DEBUG_MINIMAL = 2
Faceroll.DEBUG_LAST = 2

Faceroll.debug = Faceroll.DEBUG_OFF
Faceroll.debugOverlay = nil
Faceroll.debugState = ""
Faceroll.debugLines = {}
Faceroll.debugUpdateText = ""
Faceroll.debugLastUpdateBitsCounter = 0
Faceroll.debugLastUpdateBitsTime = 0

Faceroll.debugLastUpdateEventsEnabled = false
Faceroll.debugLastUpdateWho = {}

Faceroll.updateDebugOverlay = function()
    if Faceroll.debugOverlay == nil then
        return
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = "\124cff444444      - Faceroll -      \124r\n\n"

        local updatesSince = Faceroll.updateBitsCounter - Faceroll.debugLastUpdateBitsCounter
        local now = GetTime()
        if Faceroll.debugLastUpdateBitsTime == 0 then
            Faceroll.debugLastUpdateBitsTime = now
        end
        local updateTimeDelta = now - Faceroll.debugLastUpdateBitsTime
        if updateTimeDelta > 1 then
            local updatesPerSec = updatesSince / updateTimeDelta
            Faceroll.debugUpdateText = string.format("Updates/sec: %.2f\n", updatesPerSec)
            Faceroll.debugLastUpdateBitsTime = now
            Faceroll.debugLastUpdateBitsCounter = Faceroll.updateBitsCounter

            if Faceroll.debugLastUpdateEventsEnabled then
                local REALLY_BAD = 50
                if updatesPerSec > REALLY_BAD then
                    print("---")
                end

                for who,count in pairs(Faceroll.debugLastUpdateWho) do
                    Faceroll.debugUpdateText = Faceroll.debugUpdateText .. who .. ": " .. count .. "\n"
                    if updatesPerSec > REALLY_BAD then
                        print("BAD: " .. who .. ": " .. count .. "\n")
                    end
                end
                Faceroll.debugLastUpdateWho = {}
            end
        end

        if Faceroll.debug == Faceroll.DEBUG_MINIMAL then
            o = o .. Faceroll.debugState .. "\n"
        else
            local debugLines = ""
            for _,line in ipairs(Faceroll.debugLines) do
                debugLines = debugLines .. line .. "\n"
            end
            o = o .. Faceroll.debugState .. "\n" .. debugLines .. Faceroll.debugUpdateText
        end

        Faceroll.debugOverlay:setText(o)
        Faceroll.debugOverlay.frame:Show()
    else
        Faceroll.debugOverlay.frame:Hide()
    end
end

Faceroll.clearDebugLines = function()
    Faceroll.debugLines = {}
end

Faceroll.addDebugLine = function(line)
    table.insert(Faceroll.debugLines, line)
end

Faceroll.setDebugState = function(spec, state)
    if Faceroll.debug == Faceroll.DEBUG_OFF then
        return
    end

    local pad = function(text, count)
        text = tostring(text)
        while strlenutf8(text) < count do
            text = " " .. text
        end
        return text
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    local o = ""

    if Faceroll.debug ~= Faceroll.DEBUG_MINIMAL then
        for _,k in ipairs(spec.overlay) do
            local v = state[k]
            if Faceroll.isSeparatorName(k) then
                if strlenutf8(o) > 0 then
                    o = o .. "\n"
                end
                o = o .. "\124cffffffaa" .. pad(k, 18) .. "\124r\n"
            elseif type(v) == "string" then
                o = o .. pad(k, 18) .. "  : " .. Faceroll.textColor(v, "ffaaff") .. "\n"
            else
                o = o .. pad(k, 18) .. "  : " .. bt(v) .. "\n"
            end
        end
        o = o .. "\n"
    end

    if spec.calcAction then
        o = o .. "\124cffffaaff - Next -\124r\n"

        local actionST = spec.calcAction(Faceroll.MODE_ST, state)
        if actionST == nil then
            actionST = "--"
        end
        o = o .. "\124cffffaaff * ST \124r" .. "  : \124cffaaffaa" .. actionST .. "\124r\n"

        local actionAOE = spec.calcAction(Faceroll.MODE_AOE, state)
        if actionAOE == nil then
            actionAOE = "--"
        end
        o = o .. "\124cffffaaff * AOE\124r" .. "  : \124cffaaffaa" .. actionAOE .. "\124r\n"
    end

    Faceroll.debugState = o
    Faceroll.updateDebugOverlay()
end


Faceroll.debugInit = function()
    Faceroll.debugOverlay = Faceroll.createFrame(200, 220,                  -- size
                                                    "TOPLEFT", 0, 0,           -- position
                                                    "TOOLTIP", 0.9,            -- strata/alpha
                                                    "TOPLEFT", "firamono", 13) -- text
    Faceroll.updateDebugOverlay()
end

-----------------------------------------------------------------------------------------
-- Shims for builtin functions that maybe don't exist in some versions

local builtinGSC = nil
if C_Spell ~= nil then
    builtinGSC = C_Spell.GetSpellCooldown
end
if builtinGSC == nil then
    builtinGSC = function(spellName)
        local startTime, duration = GetSpellCooldown(spellName)
        return { ["duration"]=duration, ["startTime"]=startTime, }
    end
end

local builtinISU = nil
if C_Spell ~= nil then
    builtinISU = C_Spell.IsSpellUsable
end
if builtinISU == nil then
    builtinISU = function(spellName)
        local isuResult = IsUsableSpell(spellName)
        if isuResult == 1 then
            return true
        end
        return false
    end
end

local builtinGSCharges = nil
if C_Spell ~= nil then
    builtinGSCharges = C_Spell.GetSpellCharges
end
if builtinGSCharges ~= nil then
    builtinGSCharges = function(spellName)
        local chargeInfo = C_Spell.GetSpellCharges(spellName)
        if chargeInfo == nil then
            return 0
        end
        return chargeInfo.currentCharges, chargeInfo.maxCharges
    end
else
    builtinGSCharges = function(spellName)
        local chargeCount, maxCharges = GetSpellCharges(C_Spell:GetSpellID(spellName))
        return chargeCount, maxCharges
    end
end

-----------------------------------------------------------------------------------------
-- Queries

Faceroll.ascensionFindAura = function(reqUnit, reqName, reqFilter)
    for auraIndex=1,40 do
        local name, rank, icon, stacks, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(reqUnit, auraIndex, reqFilter)
        if name == reqName then
            -- DevTools_Dump({UnitAura("player", auraIndex, reqFilter)})
            return { ["duration"]=duration, ["stacks"]=stacks, ["expirationTime"]=expirationTime, }
        end
    end
    return nil
end

Faceroll.getBuff = function(buffName)
    if Faceroll.ascension then
        return Faceroll.ascensionFindAura("player", buffName, "HELPFUL")
    else
        print("FIXME: Faceroll.getBuff("..buffName..")")
    end
    return nil
end

Faceroll.getDot = function(dotName)
    if Faceroll.ascension then
        return Faceroll.ascensionFindAura("target", dotName, "HARMFUL|PLAYER")
    else
        local name, _, stacks, _, duration, expirationTime = AuraUtil.FindAuraByName(spellName, "target", "HARMFUL|PLAYER")
        if name ~= nil then
            return { ["duration"]=duration, ["stacks"]=stacks, ["expirationTime"]=expirationTime, }
        end
    end
    return nil
end

Faceroll.isBuffActive = function(buffName)
    return (Faceroll.getBuff(buffName) ~= nil)
end

Faceroll.getBuffStacks = function(buffName)
    local buff = Faceroll.getBuff(buffName)
    if buff then
        return buff.stacks
    end
    return 0
end

Faceroll.getBuffRemaining = function(buffName)
    local buff = Faceroll.getBuff(buffName)
    if buff then
        local remaining = math.max(buff.expirationTime - GetTime(), 0)
        return remaining
    end
    return 0
end

Faceroll.spellCharges = function(spellName)
    return builtinGSCharges(spellName)
end

Faceroll.spellCooldown = function(spellName)
    local cd = builtinGSC(spellName)
    if cd == nil then
        return 0
    end
    local duration = cd.duration
    if duration > 0 then
        local since = GetTime() - cd.startTime
        return duration - since
    end
    return 0
end

Faceroll.spellChargesSoon = function(spellName, count, seconds)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    if chargeInfo == nil then
        return false
    end
    if chargeInfo.currentCharges < count - 1 then
        return false
    end
    if Faceroll.spellCooldown(spellName) > seconds then
        return false
    end
    return true
end

Faceroll.isSpellAvailable = function(spellName, ignoreUsable)
    if not builtinISU(spellName) and not ignoreUsable then
        return false
    end
    local currentCharges, maxCharges = Faceroll.spellCharges(spellName)
    if maxCharges > 0 then
        if Faceroll.spellCharges(spellName) > 0 then
            return true
        end
        return false
    end

    if builtinGSC(spellName).duration > 1.5 then
        return false
    end
    return true
end

Faceroll.hasManaForSpell = function(spellName)
    local curMana = UnitPower("player", 0)
    local spellCost = C_Spell.GetSpellPowerCost(spellName)
    if spellCost ~= nil and spellCost[1] ~= nil and spellCost[1].cost > 0 then
        if curMana >= spellCost[1].cost then
            return true
        end
    end
    return false
end

Faceroll.isDotActive = function(spellName)
    local dot = Faceroll.getDot(spellName)
    if dot ~= nil and dot.duration > 0 then
        local remainingDuration = dot.expirationTime - GetTime()
        local normalizedDuration = remainingDuration / dot.duration
        if normalizedDuration < 0 then
            normalizedDuration = 0
        end
        return normalizedDuration
    end
    return -1
end

Faceroll.dotStacks = function(spellName)
    local dot = Faceroll.getDot(spellName)
    if dot ~= nil and dot.duration > 0 then
        return dot.stacks
    end
    return 0
end

Faceroll.inShapeshiftForm = function(formName)
    local inform = false
    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and name == formName then
            inform = true
        end
    end
    return inform
end

Faceroll.targetingEnemy = function()
    return UnitExists("target") and not UnitIsDead("target") and not UnitIsFriend("player", "target")
end

Faceroll.inCombat = function()
    if UnitAffectingCombat("player") then
        return true
    end
    return false
end

-----------------------------------------------------------------------------------------
-- Dead Zones

-- Spellcasting "dead zones", aka windows of time where we should consider this spell unavailable/dead
-- This is useful for when we don't want to cast a spell *twice* but we don't know we shouldn't
-- press it until some dot appears or travel time finishes, etc.
-- WARNING: be sure to use /frkick in the macro for the spell you're trying to put in a deadzone!
Faceroll.deadzoneCreate = function(spellName, normalizedCastTimeRemaining, deadzoneDuration)
    return {
        ["spellName"]=spellName,
        ["castTimeRemaining"]=normalizedCastTimeRemaining,
        ["duration"]=deadzoneDuration,
        ["endTime"]=0,
    }
end

-- Safe to call any time
Faceroll.deadzoneActive = function(deadzone)
    return (deadzone.endTime > GetTime())
end

-- Only call this when all other state means you're interested in *starting* the deadzone,
-- e.g. you're trying to only cast Wrath twice to proc Eclipse and the wrath count has 1 left
Faceroll.deadzoneUpdate = function(deadzone)
    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    local castingSpellDone = 0
    if castingSpell then
        castingSpellDone = castingSpellEndTime / 1000 - GetTime()
        -- print("castingSpell " .. castingSpell .. " castingSpellDone " .. castingSpellDone)
    end
    if castingSpell == deadzone.spellName and castingSpellDone < deadzone.castTimeRemaining then
        deadzone.endTime = GetTime() + deadzone.duration
    end
    return Faceroll.deadzoneActive(deadzone)
end

-----------------------------------------------------------------------------------------
