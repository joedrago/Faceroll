-----------------------------------------------------------------------------------------
-- Faceroll Tool (External)

-----------------------------------------------------------------------------------------
-- Basic debug/helper stuff

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

-----------------------------------------------------------------------------------------
-- Load Settings

-- Stub any functions that the mod needs but the actor doesn't, during Settings.lua
Faceroll.enableSpec = function() end
Faceroll.keys = {}

require("Bridge")
require("Settings")

-----------------------------------------------------------------------------------------
-- Globals

local facerollActive = false                --  An additional way to temporarily behave like SPEC_OFF when people hit enter/slash/delete
local facerollAction = Faceroll.MODE_NONE --  Which faceroll key action is running? (the "paradigm")
local facerollSlowDown = 0                  --  Offer a means to only act every so many ticks

-----------------------------------------------------------------------------------------
-- Key handlers

KEYCODE_ST1 = Faceroll.lookupKeyCode(Faceroll.keys["mode_st1"])
KEYCODE_ST2 = Faceroll.lookupKeyCode(Faceroll.keys["mode_st2"])
KEYCODE_AOE1 = Faceroll.lookupKeyCode(Faceroll.keys["mode_aoe1"])
KEYCODE_AOE2 = Faceroll.lookupKeyCode(Faceroll.keys["mode_aoe2"])
KEYCODE_RESET1 = Faceroll.lookupKeyCode(Faceroll.keys["reset1"])

function onKeyCode(keyCode)
    if facerollActive then
        if     ((KEYCODE_ST1 ~= nil) and (keyCode == KEYCODE_ST1))
            or ((KEYCODE_ST2 ~= nil) and (keyCode == KEYCODE_ST2))
        then
            FRDEBUG("Faceroll: ST")
            facerollAction = Faceroll.MODE_ST
            return true
        elseif ((KEYCODE_AOE1 ~= nil) and (keyCode == KEYCODE_AOE1))
            or ((KEYCODE_AOE2 ~= nil) and (keyCode == KEYCODE_AOE2))
        then
            FRDEBUG("Faceroll: AOE")
            facerollAction = Faceroll.MODE_AOE
            return true
        elseif (KEYCODE_RESET1 ~= nil) and (keyCode == KEYCODE_RESET1)
        then
            FRDEBUG("Faceroll: Reset")
            facerollAction = Faceroll.MODE_NONE
            return true
        end

    end
    return false
end

function onReset()
    facerollAction = Faceroll.MODE_NONE
end

-----------------------------------------------------------------------------------------
-- The heart of action ticks

function onUpdate(bits)
    local bridgeState = Faceroll.bridgeStateUnpack(bits)
    -- Faceroll.bridgeStateDump(bridgeState)
    if bridgeState == nil then
        print("ERROR: failed to parse bridge state!")
        return
    end

    facerollActive = bridgeState.active
    if not facerollActive then
        facerollAction = Faceroll.MODE_NONE
    end

    if facerollAction == Faceroll.MODE_NONE then
        return
    end

    facerollSlowDown = facerollSlowDown + 1
    if facerollSlowDown > 2 then
        facerollSlowDown = 0
        if facerollAction == Faceroll.MODE_ST then
            sendKeyToWow(Faceroll.keys["signal_st"]) -- signal we're in ST
        elseif facerollAction == Faceroll.MODE_AOE then
            sendKeyToWow(Faceroll.keys["signal_aoe"]) -- signal we're in AOE
        end
        return
    elseif facerollSlowDown == 1 then
        if facerollAction == Faceroll.MODE_ST and (bridgeState.key0 ~= Faceroll.BRIDGE_KEY_NONE) then
            sendKeyToWow(bridgeState.key0)
        elseif facerollAction == Faceroll.MODE_AOE and (bridgeState.key1 ~= Faceroll.BRIDGE_KEY_NONE) then
            sendKeyToWow(bridgeState.key1)
        end
    end

    return
end

-----------------------------------------------------------------------------------------

print("Faceroll loaded.")
