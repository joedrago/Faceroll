-----------------------------------------------------------------------------------------
-- World of Warcraft Faceroll Logic

-- Macros:
-- FRON  ('['): /fron
-- FROFF (']'): /froff

-- Set FR text for 500ms: /fr AE, /fr ST, etc

-- Keybinds:
-- '[', ']', '6'            - see macros
-- 7890-= num7 num8 num9    - ST rotatoe
-- F7-F12 num4 num5 num6    - AOE rotatoe
-- Q, E, F5, /, enter, del  - automatic (see below)

-----------------------------------------------------------------------------------------
-- Duplicate this block at the top of both hammerspoon's and mod's Faceroll.lua files
local FR_SPECS = {}
local SPEC_OFF = 0  FR_SPECS[ SPEC_OFF ] = { ["name"]="OFF", ["color"]="333333", ["key"]=""              }
local SPEC_SV  = 1  FR_SPECS[ SPEC_SV  ] = { ["name"]="SV",  ["color"]="337733", ["key"]="HUNTER-3"      }
local SPEC_MM  = 2  FR_SPECS[ SPEC_MM  ] = { ["name"]="MM",  ["color"]="88aa00", ["key"]="HUNTER-2"      }
local SPEC_BM  = 3  FR_SPECS[ SPEC_BM  ] = { ["name"]="BM",  ["color"]="448833", ["key"]="HUNTER-1"      }
local SPEC_VDH = 4  FR_SPECS[ SPEC_VDH ] = { ["name"]="VDH", ["color"]="993399", ["key"]="DEMONHUNTER-2" }
local SPEC_HDH = 5  FR_SPECS[ SPEC_HDH ] = { ["name"]="HDH", ["color"]="993300", ["key"]="DEMONHUNTER-1" }
local SPEC_UDK = 6  FR_SPECS[ SPEC_UDK ] = { ["name"]="UDK", ["color"]="996699", ["key"]="DEATHKNIGHT-3" }
local SPEC_OUT = 7  FR_SPECS[ SPEC_OUT ] = { ["name"]="OUT", ["color"]="336699", ["key"]="ROGUE-2"       }
local SPEC_DP  = 8  FR_SPECS[ SPEC_DP  ] = { ["name"]="DP",  ["color"]="999933", ["key"]="PRIEST-1"      }
local SPEC_SP  = 9  FR_SPECS[ SPEC_SP  ] = { ["name"]="SP",  ["color"]="7a208c", ["key"]="PRIEST-3"      }
local SPEC_DB  = 10 FR_SPECS[ SPEC_DB  ] = { ["name"]="DB",  ["color"]="559955", ["key"]="DRUID-3"       }
local SPEC_FM  = 11 FR_SPECS[ SPEC_FM  ] = { ["name"]="FM",  ["color"]="005599", ["key"]="MAGE-3"        }
local SPEC_ELE = 12 FR_SPECS[ SPEC_ELE ] = { ["name"]="ELE", ["color"]="003399", ["key"]="SHAMAN-1"      }
local SPEC_LAST = #FR_SPECS
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Global Constants

KEY_TOGGLE = hs.keycodes.map["F5"]
KEY_SPEC = hs.keycodes.map["F5"]
KEY_Q = hs.keycodes.map["q"]
KEY_E = hs.keycodes.map["e"]
KEY_SLASH = hs.keycodes.map["/"]
KEY_ENTER = hs.keycodes.map["return"]
KEY_DELETE = hs.keycodes.map["delete"]

ACTION_NONE = 0
ACTION_Q = 1
ACTION_E = 2

-----------------------------------------------------------------------------------------
-- Globals

local facerollSpec = SPEC_OFF       -- Which spec are we trying to be right now?
local facerollActive = true         -- An additional way to temporarily behave like SPEC_OFF when people hit enter/slash/delete
local facerollAction = ACTION_NONE  -- Which faceroll key action is running? (the "paradigm")
local facerollSpecSendRemaining = 0 -- Where are with our rotary-phone-sending of the spec number
local facerollSlowDown = 0          -- Offer a means to only act every so many ticks
local facerollGameBits = 0          -- The current game state!

-----------------------------------------------------------------------------------------
-- Basic debug/helper stuff

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

-----------------------------------------------------------------------------------------
-- UDP socket listening for game bits

function onGameBits(newBits, addr)
    facerollGameBits = tonumber(newBits)
    -- print("onGameBits[a]: " .. facerollGameBits)
    -- print("onGameBits[g]: " .. bitand(facerollGameBits, 0xffff))
end
server = hs.socket.udp.server(9001, onGameBits):receive()

-----------------------------------------------------------------------------------------
-- App interation

local wowApplication = nil
local function sendKeyToWow(keyName)
    -- if wowApplication == nil then
        wowApplication = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')[1]
    -- end
    if wowApplication ~= nil then
        hs.eventtap.keyStroke({}, keyName, 20000, wowApplication)
    end
end

-----------------------------------------------------------------------------------------
-- The heart of action ticks

for _, spec in pairs(FR_SPECS) do
    if spec.name ~= "OFF" then
        print("Loading Spec: " .. spec.name)
        local requirePath = "Faceroll/ActionsSpec" .. spec.name
        spec.nextAction = require(requirePath)
    end
end

local wowTick = hs.timer.new(0.02, function()
    -- FRDEBUG("wowTick")
    if not facerollActive or facerollAction == ACTION_NONE then
        return
    end

    facerollSlowDown = facerollSlowDown + 1
    if facerollSlowDown > 10 then
        facerollSlowDown = 0
        if facerollSpec ~= SPEC_OFF then
            if facerollAction == ACTION_Q then
                sendKeyToWow("pad9") -- signal we're in Q
            elseif facerollAction == ACTION_E then
                sendKeyToWow("pad6") -- signal we're in E
            end
        end
        return
    elseif facerollSlowDown == 1 then
        local key = nil

        local spec = FR_SPECS[facerollSpec]
        if spec ~= nil and spec.nextAction ~= nil then
            key = spec.nextAction(facerollAction, facerollGameBits)
        end

        if key ~= nil then
            sendKeyToWow(key)
        end
    end

    return
end, true)

-----------------------------------------------------------------------------------------
-- The mechanism used to tell the game which spec we're in (like a rotary phone would)

local wowSendSpecTick = hs.timer.new(0.05, function()
    -- FRDEBUG("wowSendSpecTick")
    if facerollSpecSendRemaining > 0 then
        facerollSpecSendRemaining = facerollSpecSendRemaining - 1
        sendKeyToWow("[")
    end
    return
end, true)

local function updateSpec()
    facerollSpecSendRemaining = 0
    sendKeyToWow("]")
    facerollSpecSendRemaining = facerollSpec
    if not wowSendSpecTick:running() then
        wowSendSpecTick:start()
    end

    print("Faceroll: " .. FR_SPECS[facerollSpec].name)
end

-----------------------------------------------------------------------------------------
-- Key handlers

local wowTapKey = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    -- local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    -- FRDEBUG("lole key " .. keyCode)

    if keyCode == KEY_SPEC then
        if facerollActive then
            facerollActive = false
            facerollSpec = SPEC_OFF
        else
            local specIndex = math.floor(bitand(facerollGameBits, 0xf0000000) / 0x10000000)
            facerollActive = true
            facerollSpec = specIndex
        end
        facerollSlowDown = 0
        updateSpec()

    elseif keyCode == KEY_SLASH or keyCode == KEY_ENTER or keyCode == KEY_DELETE then
        facerollActive = false
    elseif facerollActive then
        if keyCode == KEY_Q then
            FRDEBUG("Faceroll: Q")
            facerollAction = ACTION_Q
            if not wowTick:running() then
                wowTick:start()
            end
            return true
        elseif keyCode == KEY_E then
            FRDEBUG("Faceroll: E")
            facerollAction = ACTION_E
            if not wowTick:running() then
                wowTick:start()
            end
            return true
        end
    end
end)

local wowTapFlags = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    if facerollSpec ~= nil then
        FRDEBUG("Faceroll: Reset")
        facerollAction = ACTION_NONE
    end
end)

-----------------------------------------------------------------------------------------
-- Window listener stuff

local function facerollListenStart()
    print("facerollListenStart()")
    wowTapKey:start()
    wowTapFlags:start()
end
local function facerollListenStop()
    print("facerollListenStop()")
    wowTapKey:stop()
    wowTapFlags:stop()
end

local WoWFilter = hs.window.filter.new(true)--"Wow")
WoWFilter:subscribe(hs.window.filter.windowFocused, function(w)
    if w == nil then
        FRDEBUG("Focus: w is nil")
    else
        FRDEBUG("Focus: " .. w:title())
        if w:title() == "World of Warcraft" then
            facerollListenStart()
        end
    end
end)
WoWFilter:subscribe(hs.window.filter.windowUnfocused, function(w)
    if w ~= nil then
        FRDEBUG("Unfocus: " .. w:title())
        if w:title() == "World of Warcraft" then
            facerollListenStop()
        end
    end
end)

-----------------------------------------------------------------------------------------

print("Faceroll loaded.")
