print("init_wabits.lua startup")

KEY_TOGGLE = 116 -- F5
KEY_SPEC = 116 -- F5
KEY_ST = 81 -- q
KEY_AOE = 69 -- e
KEY_SLASH = 191 -- /
KEY_AOENTER = 13 -- enter
KEY_DELETE = 8 -- backspace

local sendKeyVKCodes = {
    ["`"]=192,
    ["["]=219,
    ["]"]=221,

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
