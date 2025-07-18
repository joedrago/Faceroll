-----------------------------------------------------------------------------------------
-- World of Warcraft Faceroll Logic

-----------------------------------------------------------------------------------------
-- Basic debug/helper stuff

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

-----------------------------------------------------------------------------------------
-- Stub some functions that the mod needs but the actor doesn't

Faceroll.trackBuffs = function() end
Faceroll.deadzoneCreate = function() end

-----------------------------------------------------------------------------------------
-- Load and prepare all specs and settings

require("Registry")

for _, spec in ipairs(Faceroll.load) do
    if spec ~= "OFF" then
        print("Loading Spec : " .. spec)
        local requirePath = "Spec" .. spec
        require(requirePath)
    end
end

-- Pressing any of these keys will auto-disable Faceroll internally
-- These are listed here as the mod hardcodes this behavior in ModMain.lua's
-- DEFAULT_CHAT_FRAME.editBox:HookScript() call
Faceroll.keys["disable1"] = "/"
Faceroll.keys["disable2"] = "return"
Faceroll.keys["disable3"] = "backspace"

require("Settings")

Faceroll.activateKeybinds()

-----------------------------------------------------------------------------------------
-- Globals

local facerollSpec = Faceroll.SPEC_OFF      --  Which spec are we trying to be right now?
local facerollActive = false                --  An additional way to temporarily behave like SPEC_OFF when people hit enter/slash/delete
local facerollAction = Faceroll.MODE_NONE --  Which faceroll key action is running? (the "paradigm")
local facerollSpecSendRemaining = 0         --  Where are with our rotary-phone-sending of the spec number
local facerollSlowDown = 0                  --  Offer a means to only act every so many ticks
local facerollGameBits = 0                  --  The current game state!

-----------------------------------------------------------------------------------------
-- Key handlers

KEYCODE_TOGGLE1 = Faceroll.lookupKeyCode(Faceroll.keys["toggle1"])
KEYCODE_TOGGLE2 = Faceroll.lookupKeyCode(Faceroll.keys["toggle2"])
KEYCODE_ST1 = Faceroll.lookupKeyCode(Faceroll.keys["mode_st1"])
KEYCODE_ST2 = Faceroll.lookupKeyCode(Faceroll.keys["mode_st2"])
KEYCODE_AOE1 = Faceroll.lookupKeyCode(Faceroll.keys["mode_aoe1"])
KEYCODE_AOE2 = Faceroll.lookupKeyCode(Faceroll.keys["mode_aoe2"])
KEYCODE_RESET1 = Faceroll.lookupKeyCode(Faceroll.keys["reset1"])
KEYCODE_RESET2 = Faceroll.lookupKeyCode(Faceroll.keys["reset2"])
KEYCODE_DISABLE1 = Faceroll.lookupKeyCode(Faceroll.keys["disable1"])
KEYCODE_DISABLE2 = Faceroll.lookupKeyCode(Faceroll.keys["disable2"])
KEYCODE_DISABLE3 = Faceroll.lookupKeyCode(Faceroll.keys["disable3"])

function onReset()
    if facerollSpec ~= nil then
        FRDEBUG("Faceroll: Reset")
        facerollAction = Faceroll.MODE_NONE
    end
end

function onKeyCode(keyCode)
    -- FRDEBUG("lole key " .. keyCode
    --     .. " KEYCODE_TOGGLE1 " .. KEYCODE_TOGGLE1
    --     .. " KEYCODE_TOGGLE2 " .. KEYCODE_TOGGLE2
    --     .. " KEYCODE_ST1 " .. KEYCODE_ST1
    --     .. " KEYCODE_ST2 " .. KEYCODE_ST2
    --     .. " KEYCODE_AOE1 " .. KEYCODE_AOE1
    --     .. " KEYCODE_AOE2 " .. KEYCODE_AOE2
    -- )

    if ((KEYCODE_TOGGLE1 ~= nil) and (keyCode == KEYCODE_TOGGLE1))
    or ((KEYCODE_TOGGLE2 ~= nil) and (keyCode == KEYCODE_TOGGLE2))
    then
        if facerollActive then
            facerollActive = false
            facerollSpec = Faceroll.SPEC_OFF
        else
            local specIndex = math.floor(Faceroll.bitand(facerollGameBits, 0xf0000000) / 0x10000000)
            facerollActive = true
            facerollSpec = specIndex
        end
        facerollSlowDown = 0
        facerollSpecSendRemaining = 0
        sendKeyToWow(Faceroll.keys["froff"])
        facerollSpecSendRemaining = facerollSpec
        print("Faceroll: " .. Faceroll.activeSpecsByIndex[facerollSpec].name)

    elseif keyCode == KEYCODE_DISABLE1 or keyCode == KEYCODE_DISABLE2 or keyCode == KEYCODE_DISABLE3 then
        facerollActive = false

    elseif facerollActive then
        if ((KEYCODE_RESET1 ~= nil) and (keyCode == KEYCODE_RESET1))
        or ((KEYCODE_RESET2 ~= nil) and (keyCode == KEYCODE_RESET2))
        then
            onReset()
            return true
        elseif ((KEYCODE_ST1 ~= nil) and (keyCode == KEYCODE_ST1))
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
        end

    end
    return false
end

-----------------------------------------------------------------------------------------
-- The heart of action ticks

function onUpdate(bits)
    -- FRDEBUG("onUpdate("..bits..")")

    facerollGameBits = bits

    if facerollSpecSendRemaining > 0 then
        facerollSpecSendRemaining = facerollSpecSendRemaining - 1
        sendKeyToWow(Faceroll.keys["fron"])
        return
    end

    if not facerollActive or facerollAction == Faceroll.MODE_NONE then
        return
    end

    facerollSlowDown = facerollSlowDown + 1
    if facerollSlowDown > 2 then
        facerollSlowDown = 0
        if facerollSpec ~= Faceroll.SPEC_OFF then
            if facerollAction == Faceroll.MODE_ST then
                sendKeyToWow(Faceroll.keys["signal_st"]) -- signal we're in ST
            elseif facerollAction == Faceroll.MODE_AOE then
                sendKeyToWow(Faceroll.keys["signal_aoe"]) -- signal we're in AOE
            end
        end
        return
    elseif facerollSlowDown == 1 then
        local action = nil

        local spec = Faceroll.activeSpecsByIndex[facerollSpec]
        if spec ~= nil and spec.calcAction ~= nil then
            local state = spec.bits:unpack(facerollGameBits)
            action = spec.calcAction(facerollAction, state)
        end

        if action ~= nil then
            local key = spec.keys[action]
            if key ~= nil then
                sendKeyToWow(key)

                if Faceroll.debug then
                    print("Action: " .. action .. " ("..key..")")
                end
            else
                print("UNKNOWN ACTION: " .. action)
            end
        else
            if Faceroll.debug and facerollAction ~= Faceroll.MODE_NONE then
                print("No action (nil) facerollAction " .. facerollAction)
            end
        end
    end

    return
end

-----------------------------------------------------------------------------------------

print("Faceroll loaded.")
