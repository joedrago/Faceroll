-----------------------------------------------------------------------------------------
-- Beast Mastery Hunter

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local barbedshothighprio = bitand(bits, 0x1)
    local bestialwrath = bitand(bits, 0x2)
    local killcommand = bitand(bits, 0x4)
    local explosiveshot = bitand(bits, 0x8)
    local direbeast = bitand(bits, 0x10)
    local barbedshot = bitand(bits, 0x20)
    local barbedshottwochargessoon = bitand(bits, 0x40)
    local hogstrider = bitand(bits, 0x80)
    local beastcleave = bitand(bits, 0x100)
    local beastcleaveending = bitand(bits, 0x200)
    local energyG85 = bitand(bits, 0x400)

    if action == ACTION_Q then
        -- Single Target

        if bestialwrath > 0 then
            -- Use Bestial Wrath.
            return press("pad7", "bestial wrath")

        elseif barbedshothighprio > 0 then
            -- Use Barbed Shot if:
            -- * Frenzy has less than 1.5 seconds remaining.
            -- * You are about to reach two charges of Barbed Shot, or you have
            --   more charges of Barbed Shot than Kill Command.
            -- * Frenzy has fewer than 3 stacks and Call of the Wild or Bestial
            --   Wrath are coming off cooldown soon
            return press("0", "barbed shot")

        elseif direbeast > 0 then
            -- Dire Beast.
            return press("9", "dire beast")

        elseif killcommand > 0 then
            -- Use Kill Command.
            return press("-", "kill command")

        elseif barbedshot > 0 then
            -- Use Barbed Shot.
            return press("0", "barbed shot")

        else
            -- Use Cobra Shot.
            return press("8", "cobra shot")
        end

    elseif action == ACTION_E then
        -- AOE

        if bestialwrath > 0 then
            -- Use Bestial Wrath. Prioritize targets without Barbed Shot.
            return press("pad7", "bestial wrath")

        elseif barbedshothighprio > 0 then
            -- Use Barbed Shot if:
            -- * Frenzy has less than 1.5 seconds remaining.
            -- * You are about to reach two charges of Barbed Shot, or you have
            --   more charges of Barbed Shot than Kill Command.
            -- * Frenzy has fewer than 3 stacks and Call of the Wild or Bestial
            --   Wrath are coming off cooldown soon
            return press("0", "barbed shot")

        elseif beastcleaveending > 0 then
            -- Use Multi-Shot if Beast Cleave has less than 2 seconds remaining.
            return press("=", "multishot")

        elseif direbeast > 0 and beastcleave > 0 then
            -- Use Dire Beast if Beast Cleave is up.
            return press("9", "dire beast")

        elseif barbedshottwochargessoon > 0 then
            -- Use Barbed Shot if you are about to reach 2 charges.
            return press("0", "barbed shot")

        elseif killcommand > 0 then
            -- Use Kill Command.
            return press("-", "kill command")

        elseif barbedshot > 0 then
            -- Use Barbed Shot.
            return press("0", "barbed shot")

        elseif hogstrider > 0 then
            -- Use Cobra Shot if you have 4 stacks of Hogstrider.
            return press("8", "cobra shot")

        elseif direbeast > 0 then
            -- Dire Beast.
            return press("9", "dire beast")

        elseif energyG85 > 0 then
            -- Use Cobra Shot if you are about to cap on Focus.
            return press("8", "cobra shot")

        else
            -- Use Explosive Shot.
            return press("7", "explosive shot")
        end
    end

    return nil
end

return nextAction
