-----------------------------------------------------------------------------------------
-- Elemental Shaman

local function nextAction(action, bits)
    local tempest = bitand(bits, 0x1)
    local icefury = bitand(bits, 0x2)
    local ascendance = bitand(bits, 0x4)
    local echoesofgreatsundering = bitand(bits, 0x8)
    local masteroftheelements = bitand(bits, 0x10)
    local fusionofelements = bitand(bits, 0x20)
    local flameshock = bitand(bits, 0x40)
    local stormkeeper = bitand(bits, 0x80)
    local lavaburst = bitand(bits, 0x100)
    local enough_maelstrom_eq = bitand(bits, 0x200)
    local enough_maelstrom_eb = bitand(bits, 0x400)
    local too_much_maelstrom = bitand(bits, 0x800)

    if action == ACTION_Q then
        -- Single Target

        if stormkeeper > 0 then
            -- Use Stormkeeper roughly on cooldown. Hold it for up to 10 seconds
            -- to sync with Ascendance.
            return "=" -- stormkeeper

        elseif flameshock_on_target == 0 then
            -- Use Flame Shock to maintain the DoT on your target. Delay it, if
            -- Ascendance comes up before the DoT runs out.
            return "-" -- flame shock

        elseif tempest > 0 then
            -- Use Tempest when available.
            return "7" -- lightning bolt

        elseif enough_maelstrom_eq > 0 and echoesofgreatsundering > 0 and masteroftheelements > 0 then
            -- Use Earthquake if you have Echoes of Great Sundering and Master
            -- of the Elements active.
            return "9" -- earthquake

        elseif echoesofgreatsundering > 0 and too_much_maelstrom > 0 then
            -- Use Earthquake if you have Echoes of Great Sundering and are less
            -- than 15 Maelstrom away from cap.
            return "9" -- earthquake

        elseif too_much_maelstrom > 0 then
            -- Use Elemental Blast/ Earth Shock if you are less than 15
            -- Maelstrom away from cap.
            return "0" -- elemental blast

        elseif enough_maelstrom_eb > 0 and masteroftheelements > 0 then
            -- Use Elemental Blast/ Earth Shock if you have Master of the
            -- Elements active.
            return "0" -- elemental blast

        elseif lavaburst > 0 then
            -- Use Lava Burst.
            return "pad8" -- lava burst

        elseif icefury > 0 and ascendance == 0 then
            -- Use Frost Shock if you have Icefury active and you are not in
            -- Ascendance.
            return "pad7" -- frost shock

        else
            -- Use Lightning Bolt.
            return "7" -- lightning bolt
        end

    elseif action == ACTION_E then
        -- AOE

        if stormkeeper > 0 then
            -- Use Stormkeeper roughly on cooldown. Hold it for up to 10 seconds
            -- to sync with Ascendance.
            return "=" -- stormkeeper

        elseif tempest > 0 then
            -- Use Tempest when available.
            return "7" -- lightning bolt

        elseif echoesofgreatsundering > 0 and too_much_maelstrom > 0 then
            -- Use Earthquake if you have Echoes of Great Sundering and are less
            -- than 15 Maelstrom away from cap.
            return "9" -- earthquake

        elseif too_much_maelstrom > 0 then
            -- Use Elemental Blast/ Earth Shock if you are less than 15
            -- Maelstrom away from cap.
            return "0" -- elemental blast

        else
            -- Use Chain Lightning.
            return "8" -- chain lightning
        end
    end
    return nil
end

return nextAction
