if Faceroll == nil then
    _, Faceroll = ...
end

-----------------------------------------------------------------------------------------
-- The little "OFF" / "SV" text

local enabledFrame = nil
local enabledSpec = Faceroll.SPEC_OFF

local function enabledFrameCreate()
    enabledFrame = Faceroll.createFrame(34, 34,
                                        Faceroll.enabledFrameAnchor, Faceroll.enabledFrameX, Faceroll.enabledFrameY,
                                        "TOOLTIP", 0.0,
                                        "CENTER", "firamono", Faceroll.enabledFrameFontSize)
end

local function enabledFrameUpdate()
    if enabledFrame ~= nil then
        local spec = Faceroll.activeSpecsByIndex[enabledSpec]
        local color = spec.color
        if Faceroll.hold and enabledSpec > 0 then
            color = "cccccc"
        end
        enabledFrame:setText(Faceroll.textColor(spec.name, color))
    end
end

function enabledFrameCycle()
    enabledSpec = enabledSpec + 1
    if enabledSpec > Faceroll.SPEC_LAST then
        enabledSpec = Faceroll.SPEC_LAST
    end
    enabledFrameUpdate()
end

function enabledFrameReset()
    enabledSpec = 0
    enabledFrameUpdate()
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
    if Faceroll.hold then
        activeText = "HOLD " .. text
    end
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

local function updateBits()
    local _, playerClass = UnitClass("player")
    local specIndex = "CLASSIC"
    if GetSpecialization ~= nil then
        specIndex = GetSpecialization()
    end
    if playerClass == nil or specIndex == nil then
        return
    end
    local specKey = playerClass .. "-" .. specIndex
    local spec = Faceroll.activeSpecsByKey[specKey]
    if spec and spec.calcState then
        local state = spec.calcState(spec.bits:unpack(0))
        local bits = spec.bits:pack(state)
        local specIndex = spec.index
        if specIndex ~= nil then
            -- use the last 4 bits for the current specIndex
            -- print("specIndex: " .. specIndex .. " oldBits: " .. bits)
            bits = bits + (0x10000000 * specIndex)
            -- print("specIndex: " .. specIndex .. " newBits: " .. bits)
        end
        showBits(bits)
    else
        hideBits()
    end
end

local remainingTicks = 0
local function tick()
    -- print("tick! " .. remainingTicks)
    updateBits()

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
local function toggleHold()
    if Faceroll.hold then
        Faceroll.hold = false
    else
        Faceroll.hold = true
    end
    enabledFrameUpdate()
end

-----------------------------------------------------------------------------------------
-- init() - the entry point

local function init()
    Faceroll.debugInit()

    enabledFrameCreate()
    enabledFrameUpdate()
    activeFrameCreate()

    createBits()
    updateBits()

    print("Faceroll: Initialized")
end

-----------------------------------------------------------------------------------------
-- Core event registration and handling

local eventFrame = CreateFrame("Frame")
local initialized = false
local function onEvent(self, event, arg1, arg2, ...)
    if not initialized and ((event == "ADDON_LOADED" and arg1 == "Faceroll") or (event == "PLAYER_LOGIN")) then
        initialized = true
        eventFrame:UnregisterEvent("ADDON_LOADED")
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Faceroll.resetBuffs()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        updateBits()
    elseif event == "UNIT_PET" then
        updateBits()
    elseif event == "PLAYER_TARGET_CHANGED" then
        updateBits()
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            Faceroll.onPlayerAura(arg2)
        end
        updateBits()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, spellEvent, _, source, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if source == UnitGUID("player") then
            Faceroll.onPlayerSpellEvent(spellEvent, spellID)
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
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", onEvent)

DEFAULT_CHAT_FRAME.editBox:HookScript("OnShow", function()
    -- If this fires, someone is trying to type in chat!
    enabledFrameReset()
end)

-----------------------------------------------------------------------------------------
-- Slash command registration

SLASH_FR1 = '/fr'
SlashCmdList["FR"] = activeFrameSet
SLASH_FRON1 = '/fron'
SlashCmdList["FRON"] = enabledFrameCycle
SLASH_FROFF1 = '/froff'
SlashCmdList["FROFF"] = enabledFrameReset
SLASH_FRTICK1 = '/frtick'
SlashCmdList["FRTICK"] = tickReset
SLASH_FRHOLD1 = '/frhold'
SlashCmdList["FRHOLD"] = toggleHold
