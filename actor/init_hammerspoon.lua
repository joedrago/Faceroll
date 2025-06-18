print("init_hammerspoon")

-----------------------------------------------------------------------------------------
-- Platform Specific Global Constants

KEY_TOGGLE = hs.keycodes.map["F5"]
KEY_SPEC = hs.keycodes.map["F5"]
KEY_ST = hs.keycodes.map["q"]
KEY_AOE = hs.keycodes.map["e"]
KEY_SLASH = hs.keycodes.map["/"]
KEY_AOENTER = hs.keycodes.map["return"]
KEY_DELETE = hs.keycodes.map["delete"]

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
-- Shared code

require("actor/Faceroll")

-----------------------------------------------------------------------------------------
-- Window listener stuff

if not WASPOON then
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
end

-----------------------------------------------------------------------------------------
-- UDP socket listening for game bits

function onGameBits(newBits, addr)
    local bits = tonumber(newBits)
    -- print("onGameBits[a]: " .. bits)
    -- print("onGameBits[g]: " .. bitand(bits, 0xffff))
    onUpdate(bits)
end
server = hs.socket.udp.server(9001, onGameBits):receive()
