-----------------------------------------------------------------------------------------
-- World of Warcraft Faceroll Logic

-----------------------------------------------------------------------------------------
-- Basic debug/helper stuff

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

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
local facerollAction = Faceroll.ACTION_NONE --  Which faceroll key action is running? (the "paradigm")
local facerollSpecSendRemaining = 0         --  Where are with our rotary-phone-sending of the spec number
local facerollSlowDown = 0                  --  Offer a means to only act every so many ticks
local facerollGameBits = 0                  --  The current game state!

-----------------------------------------------------------------------------------------
-- Key handlers

KEYCODE_TOGGLE = Faceroll.lookupKeyCode(Faceroll.keys["toggle"])
KEYCODE_ST = Faceroll.lookupKeyCode(Faceroll.keys["action_st"])
KEYCODE_AOE = Faceroll.lookupKeyCode(Faceroll.keys["action_aoe"])
KEYCODE_DISABLE1 = Faceroll.lookupKeyCode(Faceroll.keys["disable1"])
KEYCODE_DISABLE2 = Faceroll.lookupKeyCode(Faceroll.keys["disable2"])
KEYCODE_DISABLE3 = Faceroll.lookupKeyCode(Faceroll.keys["disable3"])

function onKeyCode(keyCode)
    -- FRDEBUG("lole key " .. keyCode)

    if keyCode == KEYCODE_TOGGLE then
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
        print("Faceroll: " .. Faceroll.specs[facerollSpec].name)

    elseif keyCode == KEYCODE_DISABLE1 or keyCode == KEYCODE_DISABLE2 or keyCode == KEYCODE_DISABLE3 then
        facerollActive = false

    elseif facerollActive then
        if keyCode == KEYCODE_ST then
            FRDEBUG("Faceroll: ST")
            facerollAction = Faceroll.ACTION_ST
            return true
        elseif keyCode == KEYCODE_AOE then
            FRDEBUG("Faceroll: AOE")
            facerollAction = Faceroll.ACTION_AOE
            return true
        end

    end
    return false
end

function onReset()
    if facerollSpec ~= nil then
        FRDEBUG("Faceroll: Reset")
        facerollAction = Faceroll.ACTION_NONE
    end
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

    if not facerollActive or facerollAction == Faceroll.ACTION_NONE then
        return
    end

    facerollSlowDown = facerollSlowDown + 1
    if facerollSlowDown > 2 then
        facerollSlowDown = 0
        if facerollSpec ~= Faceroll.SPEC_OFF then
            if facerollAction == Faceroll.ACTION_ST then
                sendKeyToWow(Faceroll.keys["signal_st"]) -- signal we're in ST
            elseif facerollAction == Faceroll.ACTION_AOE then
                sendKeyToWow(Faceroll.keys["signal_aoe"]) -- signal we're in AOE
            end
        end
        return
    elseif facerollSlowDown == 1 then
        local action = nil

        local spec = Faceroll.specs[facerollSpec]
        if spec ~= nil and spec.nextAction ~= nil then
            action = spec.nextAction(facerollAction, facerollGameBits)
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
            if Faceroll.debug and facerollAction ~= Faceroll.ACTION_NONE then
                print("No action (nil) facerollAction " .. facerollAction)
            end
        end
    end

    return
end

-----------------------------------------------------------------------------------------

print("Faceroll loaded.")
