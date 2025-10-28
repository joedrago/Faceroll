if Faceroll == nil then
    _, Faceroll = ...
end

Faceroll.initSpecs()

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

Faceroll.setOption = function(option, enabled)
    if enabled then
        Faceroll.options[option] = true
    else
        Faceroll.options[option] = nil
    end
    enabledFrameUpdate()
end

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
local function toggleDebug()
    Faceroll.debug = Faceroll.debug + 1
    if Faceroll.debug > Faceroll.DEBUG_LAST then
        Faceroll.debug = 0
    end
    Faceroll.updateDebugOverlay()
    updateBits("toggleDebug")
end

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
-- init() - the entry point

local function init()
    Faceroll.debugInit()

    enabledFrameCreate()
    enabledFrameUpdate()
    activeFrameCreate()

    createBits()
    updateBits("init()")

    print("Faceroll: Initialized")
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
        init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Faceroll.resetBuffs()
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
        if arg1 == "player" then
            Faceroll.onPlayerAura(arg2)
        end
        updateBits("UNIT_AURA")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, spellEvent, _, source, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if source == UnitGUID("player") then
            Faceroll.onPlayerSpellEvent(spellEvent, spellID)
        end
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
