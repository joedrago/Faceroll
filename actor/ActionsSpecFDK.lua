-----------------------------------------------------------------------------------------
-- Frost DK

local function press(button, name)
    -- print("Think: " .. name)
    return button
end

local function nextAction(action, bits)
    local runes1 = bitand(bits, 0x1)
    local runes2 = bitand(bits, 0x2)
    local rp30 = bitand(bits, 0x4)
    local pillaroffrostbuff = bitand(bits, 0x8)
    local rimebuff = bitand(bits, 0x10)
    local icytalonsbuff = bitand(bits, 0x20)
    local deathanddecaybuff = bitand(bits, 0x40)
    local killingmachine1 = bitand(bits, 0x80)
    local killingmachine2 = bitand(bits, 0x100)
    local frostfeverdebuff = bitand(bits, 0x200)
    local deathanddecayavailable = bitand(bits, 0x400)
    local remorselesswinteravailable = bitand(bits, 0x800)
    local pillaroffrostavailable = bitand(bits, 0x1000)
    local abominationlimbavailable = bitand(bits, 0x2000)
    local empowerruneweaponavailable = bitand(bits, 0x4000)

    if action == ACTION_Q then
        -- Single Target

        if pillaroffrostbuff > 0 then
            -- CD window

            if rp30 > 0 and icytalonsbuff == 0 then
                return press("9", "[CD] Frost Strike if Icy Talons and Unleashed Frenzy are about to fall off")

            elseif empowerruneweaponavailable > 0 then
                return press("pad8", "[CD] Empower Rune Weapon")

            elseif runes2 > 0 and killingmachine1 > 0 then
                return press("8", "[CD] Obliterate if you have a Killing Machine proc")

            elseif rp30 > 0 and killingmachine1 > 0 and runes2 == 0 then
                return press("9", "[CD] Frost Strike if you have a Killing Machine proc and less than 2 Runes")

            elseif rimebuff > 0 then
                return press("7", "[CD] Howling Blast if you have a Rime proc")

            elseif rp30 > 0 then
                return press("9", "[CD] Frost Strike")
            else
                return press(nil, "[CD] NOTHING")

            end

        else
            -- Normal window

            if rp30 > 0 and icytalonsbuff == 0 then
                return press("9", "Frost Strike if Icy Talons and Unleashed Frenzy are about to fall off")

            elseif runes1 > 0 and frostfeverdebuff == 0 then
                return press("7", "Howling Blast if the target does not have Frost Fever ticking on it.")

            elseif remorselesswinteravailable > 0 then
                return press("0", "Remorseless Winter, delaying for Pillar of Frost if it is almost ready")

            elseif pillaroffrostavailable > 0 then
                return press("=", "Pillar of Frost")

            elseif runes2 > 0 and killingmachine2 > 0 then
                return press("8", "Obliterate if you have 2 stacks of Killing Machine")

            elseif rp30 > 0 and killingmachine1 > 0 and runes2 == 0 then
                return press("9", "Frost Strike if you have a Killing Machine proc and less than 2 Runes")

            elseif runes2 > 0 and killingmachine1 > 0 then
                return press("8", "Obliterate if you have a Killing Machine proc")

            elseif rimebuff > 0 then
                return press("7", "Howling Blast if you have a Rime proc")

            elseif runes2 > 0 then
                return press("8", "Obliterate")

            elseif rp30 > 0 then
                return press("9", "Frost Strike")

            elseif abominationlimbavailable > 0 then
                return press("pad7", "Abomination Limb")
            else
                return press(nil, "NOTHING")

            end
        end

    elseif action == ACTION_E then
        -- AOE

        if pillaroffrostbuff > 0 then
            -- CD window

            if rp30 > 0 and icytalonsbuff == 0 then
                return press("9", "[CD] Frost Strike if Icy Talons and Unleashed Frenzy are about to fall off")

            elseif empowerruneweaponavailable > 0 then
                return press("pad8", "[CD] Empower Rune Weapon")

            elseif deathanddecayavailable > 0 and deathanddecaybuff == 0 then
                return press("-", "[CD] Death and Decay if Mograine's Might is not active")

            elseif runes2 > 0 and killingmachine1 > 0 then
                return press("8", "[CD] Obliterate if you have a Killing Machine proc")

            elseif rp30 > 0 and killingmachine1 > 0 and runes2 == 0 then
                return press("9", "[CD] Frost Strike if you have a Killing Machine proc and less than 2 Runes")

            elseif rimebuff > 0 then
                return press("7", "[CD] Howling Blast if you have a Rime proc")

            elseif rp30 > 0 then
                return press("9", "[CD] Frost Strike")

            else
                return press(nil, "[CD] NOTHING")
            end

        else
            -- Normal window

            if rp30 > 0 and icytalonsbuff == 0 then
                return press("9", "Frost Strike if Icy Talons and Unleashed Frenzy are about to fall off")

            elseif runes1 > 0 and frostfeverdebuff == 0 then
                return press("7", "Howling Blast if the target does not have Frost Fever ticking on it.")

            elseif remorselesswinteravailable > 0 then
                return press("0", "Remorseless Winter, delaying for Pillar of Frost if it is almost ready")

            elseif deathanddecayavailable > 0 and deathanddecaybuff == 0 then
                return press("-", "Death and Decay if Mograine's Might is not active")

            elseif pillaroffrostavailable > 0 then
                return press("=", "Pillar of Frost")

            elseif runes2 > 0 and killingmachine2 > 0 then
                return press("8", "Obliterate if you have 2 stacks of Killing Machine")

            elseif rp30 > 0 and killingmachine1 > 0 and runes2 == 0 then
                return press("9", "Frost Strike if you have a Killing Machine proc and less than 2 Runes")

            elseif runes2 > 0 and killingmachine1 > 0 then
                return press("8", "Obliterate if you have a Killing Machine proc")

            elseif rimebuff > 0 then
                return press("7", "Howling Blast if you have a Rime proc")

            elseif runes2 > 0 then
                return press("8", "Obliterate")

            elseif rp30 > 0 then
                return press("9", "Frost Strike")

            elseif abominationlimbavailable > 0 then
                return press("pad7", "Abomination Limb")
            else
                return press(nil, "NOTHING")

            end
        end

    end

    return nil
end

return nextAction
