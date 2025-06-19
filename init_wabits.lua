print("init_wabits.lua startup")

Faceroll = {}

local sendKeyVKCodes = {
    ["`"]=192,
    ["["]=219,
    ["]"]=221,

    ["/"]=191,
    ["enter"]=13,
    ["return"]=13,
    ["backspace"]=8,

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
}

Faceroll.lookupKeyCode = function(keyName)
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
