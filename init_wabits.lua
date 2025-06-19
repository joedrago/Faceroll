print("init_wabits.lua startup")

Faceroll = {}

local sendKeyVKCodes = {
    ["["]=219,
    ["]"]=221,

    ["e"]=69,
    ["q"]=81,

    ["/"]=191,
    ["enter"]=13,
    ["return"]=13,
    ["backspace"]=8,

    ["7"]=55,
    ["8"]=56,
    ["9"]=57,
    ["0"]=48,
    ["-"]=189,
    ["="]=187,

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

require("./actor/Faceroll")
