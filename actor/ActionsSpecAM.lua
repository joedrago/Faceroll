-----------------------------------------------------------------------------------------
-- Arcane Mage

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local clearcasting = bitand(bits, 0x1)
    local netherprecision = bitand(bits, 0x2)
    local intuition = bitand(bits, 0x4)
    local arcaneharmony12 = bitand(bits, 0x8)
    local arcaneharmony18 = bitand(bits, 0x10)
    local evocation = bitand(bits, 0x20)
    local arcanesurge = bitand(bits, 0x40)
    local touchofthemagi = bitand(bits, 0x80)
    local arcaneorb = bitand(bits, 0x100)
    local shiftingpower = bitand(bits, 0x200)
    local lowmana = bitand(bits, 0x400)
    local ac2 = bitand(bits, 0x800)
    local ac3 = bitand(bits, 0x1000)
    local ac4 = bitand(bits, 0x2000)
    local arcanesurgebuff = bitand(bits, 0x4000)
    local moving = bitand(bits, 0x8000)
    local holding = bitand(bits, 0x10000)

    if action == ACTION_Q then
        -- Single Target

        if holding == 0 and evocation > 0 then
            return press("f7", "evocation")

        elseif holding == 0 and arcanesurge > 0 then
            return press("f8", "arcane surge")

        elseif holding == 0 and touchofthemagi > 0 then
            return press("f9", "touch of the magi")

        elseif holding == 0 and arcanesurgebuff == 0 and shiftingpower > 0 and evocation == 0 and arcanesurge == 0 and touchofthemagi == 0 then
            return press("f11", "shifting power")

        elseif clearcasting > 0 then
            return press("9", "arcane missiles")

        elseif arcaneorb > 0 and ac2 == 0 then
            return press("f10", "arcane orb")

        elseif intuition > 0 or arcaneharmony18 > 0 or arcaneorb > 0 or lowmana > 0 then
            return press("0", "arcane barrage")

        else
            return press("7", "arcane blast")

        end

    elseif action == ACTION_E then
        -- AOE

        if holding == 0 and evocation > 0 then
            return press("f7", "evocation")

        elseif holding == 0 and arcanesurge > 0 then
            return press("f8", "arcane surge")

        elseif holding == 0 and touchofthemagi > 0 then
            return press("f9", "touch of the magi")

        elseif holding == 0 and arcanesurgebuff == 0 and shiftingpower > 0 and evocation == 0 and arcanesurge == 0 and touchofthemagi == 0 then
            return press("f11", "shifting power")

        elseif clearcasting > 0 then
            return press("9", "arcane missiles")

        elseif arcaneorb > 0 and ac3 == 0 then
            return press("f10", "arcane orb")

        elseif ac4 > 0 or intuition > 0 or arcaneharmony12 > 0 or arcaneorb > 0 or lowmana > 0 then
            return press("0", "arcane barrage")

        elseif ac3 == 0 or (ac4 == 0 and moving > 0) then
            return press("8", "arcane explosion")

        else
            return press("7", "arcane blast")

        end

    end

    return nil
end

return nextAction
