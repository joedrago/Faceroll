print("ToolInitWabits.lua startup")

Faceroll = {}

local sendKeyVKCodes = {
    ["`"]=192,
    ["["]=219,
    ["]"]=221,

    ["/"]=191,
    ["enter"]=13,
    ["return"]=13,
    ["backspace"]=8,

    ["gamepad_middle_button"]=7,

    ["1"]=49,
    ["2"]=50,
    ["3"]=51,
    ["4"]=52,
    ["5"]=53,
    ["6"]=54,
    ["7"]=55,
    ["8"]=56,
    ["9"]=57,
    ["0"]=48,
    ["-"]=189,
    ["="]=187,

    ["c"]=67,
    ["e"]=69,
    ["f"]=70,
    ["q"]=81,
    ["v"]=86,
    ["x"]=88,
    ["z"]=90,

    ["f5"]=116,
    ["f6"]=117,
    ["f7"]=118,
    ["f8"]=119,
    ["f9"]=120,
    ["f10"]=121,
    ["f11"]=122,
    ["f12"]=123,

    ["pad4"]=100,
    ["pad5"]=101,
    ["pad6"]=102,
    ["pad7"]=103,
    ["pad8"]=104,
    ["pad9"]=105,

    -- this must correspond to the values in wabits_lua.c
    ["gamepad_up"]=1001,
    ["gamepad_down"]=1002,
    ["gamepad_left"]=1003,
    ["gamepad_right"]=1004,
    ["gamepad_start"]=1005,
    ["gamepad_back"]=1006,
    ["gamepad_l3"]=1007,
    ["gamepad_r3"]=1008,
    ["gamepad_l1"]=1009,
    ["gamepad_r1"]=1010,
    ["gamepad_a"]=1011,
    ["gamepad_b"]=1012,
    ["gamepad_x"]=1013,
    ["gamepad_y"]=1014,
}

Faceroll.lookupKeyCode = function(keyName)
    if keyName == nil then
        return nil
    end
    return sendKeyVKCodes[keyName]
end

function sendKeyToWow(key)
    print("sendKeyToWow("..key..")")
    if sendKeyVKCodes[key] ~= nil then
        sendKeyToWowNative(sendKeyVKCodes[key])
    else
        print("sendKeyToWowNative() not called: " .. key)
    end
end

-----------------------------------------------------------------------------------------
-- Discover the list of Spec*.lua files to give to ActMain

Faceroll.load = WABITS_LOAD

-----------------------------------------------------------------------------------------
-- Shared code

require("./ActMain")
