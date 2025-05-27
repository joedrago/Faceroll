print("init_wabits.lua startup")

KEY_TOGGLE = 116 -- F5
KEY_SPEC = 116 -- F5
KEY_Q = 81 -- q
KEY_E = 69 -- e
KEY_SLASH = 191 -- /
KEY_ENTER = 13 -- enter
KEY_DELETE = 8 -- backspace

local sendKeyVKCodes = {
    ["["]=219,
    ["]"]=221,

    ["7"]=55,
    ["8"]=56,
    ["9"]=57,
    ["0"]=48,
    ["-"]=189,
    ["="]=187,

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

function sendKeyToWow(key)
    print("sendKeyToWow("..key..")")
    if sendKeyVKCodes[key] ~= nil then
        sendKeyToWowNative(sendKeyVKCodes[key])
    else
        print("sendKeyToWowNative() not called: " .. key)
    end
end

require("./actor/Faceroll")
