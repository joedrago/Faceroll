-----------------------------------------------------------------------------------------
-- Shadow Priest

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local shadowcrash = bitand(bits, 0x1)
    local shadowcrashjustcast = bitand(bits, 0x2)
    local shadowcrashfaraway = bitand(bits, 0x4)
    local devouringplague = bitand(bits, 0x8)
    local darkascension = bitand(bits, 0x10)
    local mindblast = bitand(bits, 0x20)
    local voidtorrent = bitand(bits, 0x40)
    local swdeath = bitand(bits, 0x80)
    local vampirictouch = bitand(bits, 0x100)
    local devouringplagueactive = bitand(bits, 0x200)
    local mindblastcapped = bitand(bits, 0x400)

    if action == ACTION_Q then
        -- Hold

        if vampirictouch > 0 then
            return press("8", "vampiric touch")

        elseif devouringplague > 0 then
            return press("9", "devouring plague")

        elseif mindblast > 0 then
            return press("-", "mind blast")

        elseif swdeath > 0 then
            return press("=", "sw death")

        else
            return press("pad7", "mind spike")

        end

    elseif action == ACTION_E then
        -- On

        if shadowcrash > 0 then
            return press("7", "shadow crash")

        elseif vampirictouch > 0 and shadowcrashjustcast == 0 and shadowcrashfaraway > 0 then
            return press("8", "vampiric touch")

        elseif darkascension > 0 then
            return press("pad8", "dark ascension")

        elseif devouringplague > 0 then
            return press("9", "devouring plague")

        elseif mindblastcapped > 0 then
            return press("-", "mind blast")

        elseif voidtorrent > 0 and vampirictouch == 0 and devouringplagueactive > 0 then
            return press("0", "void torrent")

        elseif mindblast > 0 then
            return press("-", "mind blast")

        elseif swdeath > 0 then
            return press("=", "sw death")

        else
            return press("pad7", "mind spike")

        end
    end

    return nil
end

return nextAction
