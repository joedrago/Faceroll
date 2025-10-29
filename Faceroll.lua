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

Faceroll.createSpec("OFF", "333333", "OFF")

Faceroll.createState = function(spec)
    local state = {}
    for _,name in ipairs(spec.options) do
        if Faceroll.options[name] ~= nil then
            state[name] = true
        end
    end
    return state
end

Faceroll.startup = function()
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

    print("Faceroll.startup(): " .. #Faceroll.activeSpecsByIndex .. " available specs.")
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

-----------------------------------------------------------------------------------------
-- Queries

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

Faceroll.getDotRemainingNorm = function(spellName)
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

Faceroll.isDotActive = function(spellName)
    return (Faceroll.getDotRemainingNorm(spellName) > 0)
end

Faceroll.getDotStacks = function(spellName)
    local dot = Faceroll.getDot(spellName)
    if dot ~= nil and dot.duration > 0 then
        return dot.stacks
    end
    return 0
end

Faceroll.isSpellAvailable = function(spellName, ignoreUsable)
    if not builtinISU(spellName) and not ignoreUsable then
        return false
    end
    local currentCharges, maxCharges = Faceroll.getSpellCharges(spellName)
    if maxCharges > 0 then
        if Faceroll.getSpellCharges(spellName) > 0 then
            return true
        end
        return false
    end

    if builtinGSC(spellName).duration > 1.5 then
        return false
    end
    return true
end

Faceroll.getSpellCharges = function(spellName)
    return builtinGSCharges(spellName)
end

Faceroll.getSpellCooldown = function(spellName)
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

Faceroll.getSpellChargesSoon = function(spellName, count, seconds)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    if chargeInfo == nil then
        return false
    end
    if chargeInfo.currentCharges < count - 1 then
        return false
    end
    if Faceroll.getSpellCooldown(spellName) > seconds then
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
-- The little "OFF" / "SV" text and the options list above it

local enabledFrame = nil
local optionsFrame = nil

local function enabledFrameCreate()
    enabledFrame = Faceroll.createFrame(34, 34,
                                        Faceroll.enabledFrameAnchor, Faceroll.enabledFrameX, Faceroll.enabledFrameY,
                                        "TOOLTIP", 0.0,
                                        "CENTER", "firamono", Faceroll.enabledFrameFontSize)

    optionsFrame = Faceroll.createFrame(34, 34,
                                        Faceroll.optionsFrameAnchor, Faceroll.optionsFrameX, Faceroll.optionsFrameY,
                                        "TOOLTIP", 0.0,
                                        "BOTTOM", "firamono", Faceroll.optionsFrameFontSize)
                                    end

local function enabledFrameUpdate()
    if enabledFrame ~= nil and optionsFrame ~= nil then
        local spec = nil
        if Faceroll.active then
            spec = Faceroll.activeSpec()
        else
            spec = Faceroll.activeSpecsByIndex[Faceroll.SPEC_OFF]
        end

        enabledFrame:setText(Faceroll.textColor(spec.name, spec.color))

        local optionsFrameColor = Faceroll.optionsFrameColor
        if optionsFrameColor == nil then
            optionsFrameColor = spec.color
        end

        local optionsText = ""
        if Faceroll.active then
            for _,name in ipairs(spec.options) do
                if Faceroll.optionsFrameShowAll then
                    local color = optionsFrameColor
                    if not Faceroll.options[name] then
                        color = "222222"
                    end
                    optionsText = optionsText .. Faceroll.textColor(string.upper(name), color) .. "\n"
                else
                    if Faceroll.options[name] then
                        optionsText = optionsText .. string.upper(name) .. "\n"
                    end
                end
            end
        end
        optionsFrame:setText(Faceroll.textColor(optionsText, optionsFrameColor))
    end
end

-----------------------------------------------------------------------------------------
-- The text in the center of the screen saying "FR AE", etc

local activeFrame = nil
local activeFrameTime = 0

local function activeFrameCreate()
    activeFrame = Faceroll.createFrame(100, 20,
                                       Faceroll.activeFrameAnchor, Faceroll.activeFrameX, Faceroll.activeFrameY,
                                       "TOOLTIP", 0.0,               -- strata/alpha
                                       "CENTER", "forcedsquare", Faceroll.activeFrameFontSize) -- text
end

function activeFrameSet(text)
    local activeText = "FR " .. text
    activeFrameTime = GetTime()
    activeFrame:setText(Faceroll.textColor(activeText, Faceroll.activeFrameColor))
end

-- This timer auto-resets the active frame text after ~500ms,
-- making this behave like a keepalive/heartbeat
C_Timer.NewTicker(0.25, function()
    if activeFrameTime > 0 then
        local since = GetTime() - activeFrameTime
        if since > 0.5 then
            activeFrameTime = 0
            activeFrame:setText("")
        end
    end
end, nil)

-----------------------------------------------------------------------------------------
-- The wabits interface grid of bits!

local bitsBG = nil
local bitsCells = {}

local function createBits()
    bitsBG = CreateFrame("Frame")
    bitsBG:SetPoint(Faceroll.bitsPanelAnchor, Faceroll.bitsPanelX, Faceroll.bitsPanelY)
    bitsBG:SetHeight(32)
    bitsBG:SetWidth(16)
    bitsBG:SetFrameStrata("TOOLTIP")
    bitsBG.texture = bitsBG:CreateTexture()
    bitsBG.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    bitsBG.texture:SetVertexColor(0.0, 0.0, 0.0, 1.0)
    bitsBG.texture:SetAllPoints(bitsBG)
    bitsBG:Show()

    for bitIndex = 0,31 do
        local bitX = bitIndex % 4
        local bitY = floor(bitIndex / 4)
        local bitName = "bit" .. bitIndex
        local cell = CreateFrame("Frame", bitName, bitsBG)
        cell:SetPoint("TOPLEFT", bitX * 4, bitY * -4)
        cell:SetHeight(4)
        cell:SetWidth(4)
        cell.texture = cell:CreateTexture()
        cell.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
        cell.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        cell.texture:SetAllPoints(cell)
        cell:Hide()
        bitsCells[bitIndex] = cell
    end
end

local function showBits(bits)
    -- print("showBits: " .. bits)
    bitsBG:Show()
    local b = 1
    for bitIndex = 0,31 do
        if Faceroll.bitand(bits, b)==0 then
            bitsCells[bitIndex]:Hide()
        else
            bitsCells[bitIndex]:Show()
        end
        b = b * 2
    end
end

local function hideBits()
    bitsBG:Hide()
    for bitIndex = 0,31 do
        bitsCells[bitIndex]:Hide()
    end
end

local function actionKey(spec, mode, state)
    local action = spec.calcAction(mode, state)
    if action == nil then
        return Faceroll.BRIDGE_KEY_NONE
    end
    local key = spec.keys[action]
    if key == nil then
        print("Faceroll: Unknown action: " .. action)
        return Faceroll.BRIDGE_KEY_NONE
    end
    return key
end

local function updateBits(who)
    if Faceroll.debugLastUpdateEventsEnabled then
        if Faceroll.debugLastUpdateWho[who] == nil then
            Faceroll.debugLastUpdateWho[who] = 0
        end
        Faceroll.debugLastUpdateWho[who] = Faceroll.debugLastUpdateWho[who] + 1
    end

    local spec = Faceroll.activeSpec()
    if spec and spec.calcState then
        Faceroll.clearDebugLines()
        local state = spec.calcState(Faceroll.createState(spec))

        local bridgeState = {}
        bridgeState.key0 = actionKey(spec, Faceroll.MODE_ST, state)
        bridgeState.key1 = actionKey(spec, Faceroll.MODE_AOE, state)
        bridgeState.active = Faceroll.active
        -- Faceroll.bridgeStateDump(bridgeState)
        bits = Faceroll.bridgeStatePack(bridgeState)

        showBits(bits)
        Faceroll.setDebugState(spec, state)
    else
        hideBits()
    end

    Faceroll.updateBitsCounter = Faceroll.updateBitsCounter + 1
end

-----------------------------------------------------------------------------------------
-- Options (/fro)

Faceroll.setOption = function(option, enabled)
    if enabled then
        Faceroll.options[option] = true
    else
        Faceroll.options[option] = nil
    end
    enabledFrameUpdate()
end

local function toggleOption(option)
    if Faceroll.options[option] ~= nil then
        Faceroll.options[option] = nil
    else
        Faceroll.options[option] = true
    end
    enabledFrameUpdate()
    updateBits("toggleOption")
end

local function setOptionTrue(option)
    Faceroll.options[option] = true
    enabledFrameUpdate()
    updateBits("setOptionTrue")
end

local function setOptionFalse(option)
    Faceroll.options[option] = nil
    enabledFrameUpdate()
    updateBits("setOptionFalse")
end

-----------------------------------------------------------------------------------------
-- Extra ticks (/frtick)

local remainingTicks = 0
local function tick()
    -- print("tick! " .. remainingTicks)
    updateBits("tick")

    remainingTicks = remainingTicks - 1
    if remainingTicks > 0 then
        C_Timer.After(0.1, tick)
    end
end
local function tickReset()
    if remainingTicks == 0 then
        C_Timer.After(0.1, tick)
    end
    remainingTicks = 20
end

-----------------------------------------------------------------------------------------
-- Debug Overlay Toggle (/frd)

local function toggleDebug()
    Faceroll.debug = Faceroll.debug + 1
    if Faceroll.debug > Faceroll.DEBUG_LAST then
        Faceroll.debug = 0
    end
    Faceroll.updateDebugOverlay()
    updateBits("toggleDebug")
end

-----------------------------------------------------------------------------------------
-- Keybind dumping (/frk)

local function dumpKeybinds()
    local spec = Faceroll.activeSpec()
    if spec and spec.actions then
        for actionIndex,action in ipairs(spec.actions) do
            local key = Faceroll.keys[action]
            if key == nil then
                key = Faceroll.keys[actionIndex]
            end
            if key == nil then
                key = "UNKNOWN"
            end
            print(Faceroll.textColor("[frk] ", "333333") .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor(key, "ffffaa"))
        end
    else
        print("Faceroll [/frk]: No active spec!")
    end
end

-----------------------------------------------------------------------------------------
-- Faceroll Activation (default: F5)

function facerollActivateToggle()
    Faceroll.active = not Faceroll.active
    enabledFrameUpdate()
    updateBits("activatetoggle")
end

function facerollActivate()
    Faceroll.active = true
    enabledFrameUpdate()
    updateBits("activate")
end

function facerollDeactivate()
    Faceroll.active = false
    enabledFrameUpdate()
    updateBits("deactivate")
end

-----------------------------------------------------------------------------------------
-- onLoaded() - the entry point which doesn't fire until we're loaded/logged-in

local function onLoaded()
    Faceroll.debugInit()

    enabledFrameCreate()
    enabledFrameUpdate()
    activeFrameCreate()

    createBits()
    updateBits("init()")
end

-----------------------------------------------------------------------------------------
-- Babysit zone boundaries to maintain Faceroll active state, if necessary

local lastTimeChatDisabledFaceroll = 0

function onPlayerEnteringWorld()
    if lastTimeChatDisabledFaceroll > 0 then
        local timeSinceChatDisable = GetTime() - lastTimeChatDisabledFaceroll
        if timeSinceChatDisable < 0.1 then
            -- print("Faceroll: Restoring active state on zone boundary.")
            facerollActivate()
        end
    end
    lastTimeChatDisabledFaceroll = 0
end

-----------------------------------------------------------------------------------------
-- Core event registration and handling

local eventFrame = CreateFrame("Frame")
local initialized = false
local function onEvent(self, event, arg1, arg2, ...)
    Faceroll.targetChanged = false
    if not initialized and ((event == "ADDON_LOADED" and arg1 == "Faceroll") or (event == "PLAYER_LOGIN")) then
        initialized = true
        eventFrame:UnregisterEvent("ADDON_LOADED")
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        onLoaded()
    elseif event == "PLAYER_ENTERING_WORLD" then
        onPlayerEnteringWorld()
        updateBits("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_TARGET_CHANGED" then
        Faceroll.targetChanged = true
        updateBits("PLAYER_TARGET_CHANGED")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        updateBits("UNIT_SPELLCAST_SUCCEEDED")
    elseif event == "UNIT_POWER_UPDATE" then
        updateBits("UNIT_POWER_UPDATE")
    elseif event == "UNIT_PET" then
        updateBits("UNIT_PET")
    elseif event == "PLAYER_REGEN_DISABLED" then
        updateBits("PLAYER_REGEN_DISABLED")
    elseif event == "BAG_UPDATE" then
        updateBits("BAG_UPDATE")
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        updateBits("UNIT_SPELLCAST_CHANNEL_STOP")
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        updateBits("ACTIONBAR_UPDATE_STATE")
    elseif event == "PLAYER_REGEN_ENABLED" then
        Faceroll.leftCombat = GetTime()
        updateBits("PLAYER_REGEN_ENABLED")
    elseif event == "PLAYER_STARTED_MOVING" then
        Faceroll.moving = true
        updateBits("PLAYER_STARTED_MOVING")
    elseif event == "PLAYER_STOPPED_MOVING" then
        Faceroll.moving = false
        Faceroll.movingStopped = GetTime()
        C_Timer.After(0.6, function()
            updateBits("PLAYER_STOPPED_MOVING")
        end)
        updateBits("PLAYER_STOPPED_MOVING")
    elseif event == "UNIT_AURA" then
        updateBits("UNIT_AURA")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if Faceroll.classic or Faceroll.ascension then
            -- Classic seems to get fewer other events, just blast here
            updateBits("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
eventFrame:SetScript("OnEvent", onEvent)
if Faceroll.classic or Faceroll.ascension then
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
end

DEFAULT_CHAT_FRAME.editBox:HookScript("OnShow", function()
    -- If this fires, someone is trying to type in chat!
    if Faceroll.active then
        -- Keep track of when this fires, and if a PLAYER_ENTERING_WORLD fires
        -- shortly afterwards, this was probably spurious and we can restore the
        -- active state.
        lastTimeChatDisabledFaceroll = GetTime()
    end
    facerollDeactivate()
end)

-----------------------------------------------------------------------------------------
-- Slash command registration

SLASH_FR1 = '/fr'
SlashCmdList["FR"] = activeFrameSet

SLASH_FRA1 = '/fra'
SlashCmdList["FRA"] = facerollActivateToggle

SLASH_FRTICK1 = '/frtick'
SlashCmdList["FRTICK"] = tickReset

SLASH_FRO1 = '/fro'
SlashCmdList["FRO"] = toggleOption

SLASH_FRT1 = '/frt'
SlashCmdList["FRT"] = setOptionTrue

SLASH_FRD1 = '/frd'
SlashCmdList["FRF"] = setOptionFalse

SLASH_FRF1 = '/frf'
SlashCmdList["FRD"] = toggleDebug

SLASH_FRDEBUG1 = '/frdebug'
SlashCmdList["FRDEBUG"] = toggleDebug

SLASH_FRK1 = '/frk'
SlashCmdList["FRK"] = dumpKeybinds

-----------------------------------------------------------------------------------------
