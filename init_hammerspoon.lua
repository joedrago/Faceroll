print("init_hammerspoon")

package.path = package.path .. ";" .. hs.configdir .. "/Faceroll/?.lua"

Faceroll = {}

-----------------------------------------------------------------------------------------
-- Platform Specific Global Constants

Faceroll.lookupKeyCode = function(keyName)
    if keyName == nil then
        return nil
    end
    if string.find(keyName, "^gamepad_") ~= nil then
        return nil
    end
    if keyName == "backspace" then
        return hs.keycodes.map["delete"]
    end
    if keyName == "enter" then
        return hs.keycodes.map["return"]
    end
    return hs.keycodes.map[keyName]
end

-----------------------------------------------------------------------------------------
-- App interation

function sendKeyToWow(keyName)
    local wowApplication = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')[1]
    if wowApplication == nil then
        wowApplication = hs.application.applicationsForBundleID('com.moonlight-stream.Moonlight')[1]
        if wowApplication == nil then
            FRDEBUG("cant find moonlight app")
        end
    end
    if wowApplication ~= nil then
        hs.eventtap.keyStroke({}, keyName, 20000, wowApplication)
    end
end

-----------------------------------------------------------------------------------------
-- Shared code

require("faceroll/ActMain")

-----------------------------------------------------------------------------------------
-- Window listener stuff

local wowTapKey = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    -- local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    return onKeyCode(keyCode)
end)

local wowTapFlags = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    return onReset()
end)

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

local function facerollSupportedWindow(w, reason)
    if w ~= nil then
        local app = w:application()
        if app ~= nil then
            local bundleID = app:bundleID()
            if bundleID == "com.blizzard.worldofwarcraft"
            or bundleID == "com.moonlight-stream.Moonlight"
            then
                FRDEBUG("["..reason.."] Supported Bundle: " .. bundleID)
                return true
            else
                FRDEBUG("["..reason.."] Unsupported Bundle: " .. bundleID)
            end
        end
    end
    return false
end

local WoWFilter = hs.window.filter.new(true)--"Wow")
WoWFilter:subscribe(hs.window.filter.windowFocused, function(w)
    if facerollSupportedWindow(w, "focus") then
        facerollListenStart()
    end
end)
WoWFilter:subscribe(hs.window.filter.windowUnfocused, function(w)
    if facerollSupportedWindow(w, "unfocus") then
        facerollListenStop()
    end
end)

-----------------------------------------------------------------------------------------
-- UDP socket listening for game bits

function onGameBits(newBits, addr)
    local bits = tonumber(newBits)
    onUpdate(bits)
end
server = hs.socket.udp.server(9001, onGameBits):receive()

-----------------------------------------------------------------------------------------
-- Bundle Debug

function dumpBundles()
    print("Active WoW Bundles:")
    local bundles = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')
    for bundleIndex,b in ipairs(bundles) do
        print("Bundle["..bundleIndex.."]: " .. b:name())
    end
end
-- dumpBundles()
