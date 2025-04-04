local addonName, Faceroll = ...

-----------------------------------------------------------------------------------------
-- Duplicate this block at the top of both hammerspoon's and mod's Faceroll.lua files
local FACEROLL_SPECS = {}
local SPEC_OFF = 0  FACEROLL_SPECS[ SPEC_OFF ] = { ["name"]="OFF", ["color"]="333333" }
local SPEC_SV  = 1  FACEROLL_SPECS[ SPEC_SV  ] = { ["name"]="SV",  ["color"]="337733" }
local SPEC_MM  = 2  FACEROLL_SPECS[ SPEC_MM  ] = { ["name"]="MM",  ["color"]="88aa00" }
local SPEC_BM  = 3  FACEROLL_SPECS[ SPEC_BM  ] = { ["name"]="BM",  ["color"]="448833" }
local SPEC_OUT = 4  FACEROLL_SPECS[ SPEC_OUT ] = { ["name"]="OUT", ["color"]="336699" }
local SPEC_DP  = 5  FACEROLL_SPECS[ SPEC_DP  ] = { ["name"]="DP",  ["color"]="999933" }
local SPEC_SP  = 6  FACEROLL_SPECS[ SPEC_SP  ] = { ["name"]="SP",  ["color"]="7a208c" }
local SPEC_DB  = 7  FACEROLL_SPECS[ SPEC_DB  ] = { ["name"]="DB",  ["color"]="559955" }
local SPEC_FM  = 8  FACEROLL_SPECS[ SPEC_FM  ] = { ["name"]="FM",  ["color"]="005599" }
local SPEC_ELE = 9  FACEROLL_SPECS[ SPEC_ELE ] = { ["name"]="ELE", ["color"]="003399" }
local SPEC_HDH = 10 FACEROLL_SPECS[ SPEC_HDH ] = { ["name"]="HDH", ["color"]="993300" }
local SPEC_LAST = #FACEROLL_SPECS
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- The little "OFF" / "SV" text

local enabledFrame = nil
local enabledSpec = SPEC_OFF

local function enabledFrameCreate()
    enabledFrame = Faceroll.createFrame(34, 34,                   -- size
                                        "BOTTOMLEFT", 470, 70,    -- position
                                        "TOOLTIP", 0.0,           -- strata/alpha
                                        "CENTER", "firamono", 18) -- text
end

local function enabledFrameUpdate()
    if enabledFrame ~= nil then
        local spec = FACEROLL_SPECS[enabledSpec]
        enabledFrame:setText(Faceroll.textColor(spec.name, spec.color))
    end
end

function enabledFrameCycle()
    enabledSpec = enabledSpec + 1
    if enabledSpec > SPEC_LAST then
        enabledSpec = SPEC_LAST
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
    activeFrame = Faceroll.createFrame(100, 20,                      -- size
                                       "CENTER", 0, -185,            -- position
                                       "TOOLTIP", 0.0,               -- strata/alpha
                                       "CENTER", "forcedsquare", 24) -- text
end

function activeFrameSet(text)
    local activeText = "FR " .. text
    activeFrameTime = GetTime()
    activeFrame:setText(Faceroll.textColor(activeText, "F5FF9D"))
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
    bitsBG:SetPoint("TOPRIGHT", -155, -5)
    bitsBG:SetHeight(32)
    bitsBG:SetWidth(32)
    bitsBG:SetFrameStrata("TOOLTIP")
    bitsBG.texture = bitsBG:CreateTexture()
    bitsBG.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    bitsBG.texture:SetVertexColor(0.0, 0.0, 0.0, 1.0)
    bitsBG.texture:SetAllPoints(bitsBG)
    bitsBG:Show()

    for bitIndex = 0,15 do
        local bitX = bitIndex % 4
        local bitY = floor(bitIndex / 4)
        local bitName = "bit" .. bitIndex
        local cell = CreateFrame("Frame", bitName, bitsBG)
        cell:SetPoint("TOPLEFT", bitX * 8, bitY * -8)
        cell:SetHeight(8)
        cell:SetWidth(8)
        cell.texture = cell:CreateTexture()
        cell.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
        cell.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        cell.texture:SetAllPoints(cell)
        cell:Hide()
        bitsCells[bitIndex] = cell
    end
end

local function showBits(bits)
    bitsBG:Show()
    local b = 1
    for bitIndex = 0,15 do
        if bit.band(bits, b)==0 then
            bitsCells[bitIndex]:Hide()
        else
            bitsCells[bitIndex]:Show()
        end
        b = b * 2
    end
end

local function hideBits()
    bitsBG:Hide()
    for bitIndex = 0,15 do
        bitsCells[bitIndex]:Hide()
    end
end

local function updateBits()
    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization()
    if playerClass == nil or specIndex == nil then
        return
    end
    local specKey = playerClass .. "-" .. specIndex
    local calcBitsFunc = Faceroll.registeredSpecs[specKey]
    if calcBitsFunc ~= nil then
        showBits(calcBitsFunc())
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
    remainingTicks = 10
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
    if not initialized and ((event == "ADDON_LOADED" and addonName == arg1) or (event == "PLAYER_LOGIN")) then
        initialized = true
        eventFrame:UnregisterEvent("ADDON_LOADED")
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Faceroll.resetBuffs()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
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
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", onEvent)

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
