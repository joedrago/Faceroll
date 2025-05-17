-----------------------------------------------------------------------------------------
-- Boomkin

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local lunareclipseactive = bitand(bits, 0x1)
    local moonfireneeded = bitand(bits, 0x2)
    local sunfireneeded = bitand(bits, 0x4)
    local furyofeluneready = bitand(bits, 0x8)
    local warriorofeluneready = bitand(bits, 0x10)
    local dreamstateactive = bitand(bits, 0x20)
    local ap36 = bitand(bits, 0x40)
    local ap45 = bitand(bits, 0x80)
    local ap75 = bitand(bits, 0x100)
    local eclipsewrathdeadzone = bitand(bits, 0x200)
    local incarnationready = bitand(bits, 0x400)
    local moving = bitand(bits, 0x800)

    if action == ACTION_Q then
        -- Single Target

        if sunfireneeded > 0 then
            return press("8", "DoT all eligible targets with Moonfire and Sunfire")
        elseif moonfireneeded > 0 then
            return press("7", "DoT all eligible targets with Moonfire and Sunfire")

        elseif furyofeluneready > 0 then
            return press("pad7", "Cast Fury of Elune to get the cooldown rolling and to generate passive Astral Power")

        elseif incarnationready > 0 and lunareclipseactive == 0 then
            return press("f7", "Use Incarnation")

        elseif warriorofeluneready > 0 and dreamstateactive == 0 then
            return press("pad8", "use Warrior of Elune charges when you don't have stacks of Dreamstate")

        elseif lunareclipseactive == 0 and eclipsewrathdeadzone == 0 then
            return press("0", "Cast Wrath twice to enter Eclipse (Lunar) if you are not in an Eclipse (or cooldowns)")

        elseif ap75 > 0 or (moving > 0 and ap36 > 0) then
            return press("=", "Spend Astral Power on Starsurge")

        else
            return press("9", "Build Astral Power with Starfire")

        end

    elseif action == ACTION_E then
        -- AOE

        if sunfireneeded > 0 then
            return press("8", "DoT all eligible targets with Moonfire and Sunfire")

        elseif moonfireneeded > 0 and ap75 == 0 then
            return press("7", "DoT all eligible targets with Moonfire and Sunfire")

        elseif furyofeluneready > 0 then
            return press("pad7", "Cast Fury of Elune to get the cooldown rolling and to generate passive Astral Power")

        elseif warriorofeluneready > 0 and dreamstateactive == 0 then
            return press("pad8", "use Warrior of Elune charges when you don't have stacks of Dreamstate")

        elseif lunareclipseactive == 0 and eclipsewrathdeadzone == 0 then
            return press("0", "Cast Wrath twice to enter Eclipse (Lunar) if you are not in an Eclipse (or cooldowns)")

        elseif ap75 > 0 or (moving > 0 and ap45 > 0) then
            return press("-", "Spend Astral Power on Starfall")

        else
            return press("9", "Build Astral Power with Starfire")

        end

    end

    return nil
end

return nextAction
