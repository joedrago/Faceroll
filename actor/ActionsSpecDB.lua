-----------------------------------------------------------------------------------------
-- Druid Bear

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local bearform = bitand(bits, 0x1)
    local galacticguardian = bitand(bits, 0x2)
    local thrash = bitand(bits, 0x4)
    local mangle = bitand(bits, 0x8)
    local lunarbeam = bitand(bits, 0x10)
    local needsironfur = bitand(bits, 0x20)
    local toothandclaw = bitand(bits, 0x40)
    local rage40 = bitand(bits, 0x80)
    local needsfr = bitand(bits, 0x100)

    if action == ACTION_Q or action == ACTION_E then

        if bearform == 0 then
            return press("f7", "Bear Form")

        elseif needsfr > 0 then
            return press("f9", "Frenzied Regeneration")

        elseif needsironfur > 0 and rage40 > 0 then
            return press("f8", "Ironfur")

        elseif lunarbeam > 0 then
            return press("9", "Lunar Beam")

        elseif thrash > 0 then
            return press("7", "Thrash")

        elseif mangle > 0 then
            return press("8", "Mangle")

        elseif rage40 > 0 or toothandclaw > 0 then
            return press("=", "Raze")

        elseif galacticguardian > 0 then
            return press("0", "Moonfire")

        else
            return press("-", "Swipe")
        end

    end

    return nil
end

return nextAction
