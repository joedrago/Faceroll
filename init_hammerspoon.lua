print("init_hammerspoon")

package.path = package.path .. ";" .. hs.configdir .. "/Faceroll/?.lua"

Faceroll = {}

-----------------------------------------------------------------------------------------
-- Platform Specific Global Constants

Faceroll.lookupKeyCode = function(keyName)
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

wowApplication = nil
function sendKeyToWow(keyName)
    -- if wowApplication == nil then
        wowApplication = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')[1]
    -- end
    if wowApplication ~= nil then
        hs.eventtap.keyStroke({}, keyName, 20000, wowApplication)
    end
end

-----------------------------------------------------------------------------------------
-- Discover the list of Spec*.lua files to give to ActMain

Faceroll.load = {}
for file in hs.fs.dir("Faceroll") do
    if string.find(file, "^Spec") then
        file = string.gsub(file, "^Spec", "")
        file = string.gsub(file, ".lua$", "")
        table.insert(Faceroll.load, file)
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
-- UDP socket listening for game bits

function onGameBits(newBits, addr)
    local bits = tonumber(newBits)
    onUpdate(bits)
end
server = hs.socket.udp.server(9001, onGameBits):receive()
