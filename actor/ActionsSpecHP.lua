-----------------------------------------------------------------------------------------
-- Holy Paladin

local function press(button, name)
    -- print("Think: " .. name)
    return button
end

local function nextAction(action, bits)
    local holypower5 = bitand(bits, 0x1)
    local crusaderstrike = bitand(bits, 0x2)
    local divinetoll = bitand(bits, 0x4)
    local judgment = bitand(bits, 0x8)
    local hammerofwrath = bitand(bits, 0x10)
    local consecration = bitand(bits, 0x20)

    if action == ACTION_Q then
        -- Single Target

        if hammerofwrath > 0 then
            return press("0", "Hammer of Wrath")

        elseif judgment > 0 then
            return press("8", "Judgment")

        elseif crusaderstrike > 0 then
            return press("7", "Crusader Strike")

        elseif consecration > 0 then
            return press("9", "Consecration")

        end

    elseif action == ACTION_E then
        -- AOE

        if hammerofwrath > 0 then
            return press("0", "Hammer of Wrath")

        elseif judgment > 0 then
            return press("8", "Judgment")

        elseif crusaderstrike > 0 then
            return press("7", "Crusader Strike")

        elseif consecration > 0 then
            return press("9", "Consecration")

        end

    end

    return nil
end

return nextAction
