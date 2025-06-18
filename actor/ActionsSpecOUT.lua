-----------------------------------------------------------------------------------------
-- Outlaw Rogue

-- Actions to Keybind table
local actions = {
    ["ambush"] = "1",
    ["sinisterstrike"] = "1",
    ["pistolshot"] = "`",
    ["dispatch"] = "pad7",
    ["betweentheeyes"] = "pad8",
    ["rollthebones"] = "pad4",
    ["killingspree"] = "z",
    ["keepitrolling"] = "z",
    ["adrenalinerush"] = "q",
    ["bladeflurry"] = "x",
    ["ghostlystrike"]= "f",
    ["stealth"] = "9",
    ["vanish"] = "v",
}

local function nextAction(action, bits)
    local shouldkeepitrolling = bitand(bits, 0x1)
    local shouldrollthebones = bitand(bits, 0x2)
    local adrenalinerushbuff = bitand(bits, 0x4)
    local bladeflurry = bitand(bits, 0x8)
    local ruthlessprecision = bitand(bits, 0x10)
    local subterfuge = bitand(bits, 0x20)
    local stealth = bitand(bits, 0x40)
    local opportunity = bitand(bits, 0x80)
    local audacity = bitand(bits, 0x100)
    local keepitrollingcd = bitand(bits, 0x200)
    local adrenalinerushcd = bitand(bits, 0x400)
    local betweentheeyescd = bitand(bits, 0x800)
    local vanishcd = bitand(bits, 0x1000)
    local rollthebonescd = bitand(bits, 0x2000)
    local ghostlystrikecd = bitand(bits, 0x4000)
    local killingspreecd = bitand(bits, 0x8000)
    local cp5 = bitand(bits, 0x10000)
    local cp6 = bitand(bits, 0x20000)

    if action == ACTION_ST then
        -- Single Target
        if shouldkeepitrolling > 0 and keepitrollingcd > 0 then
            -- Keep It Rolling if you have any 4 active Roll the Bones buffs.
            return actions["keepitrolling"]

        elseif shouldrollthebones > 0 and rollthebonescd > 0 then
            -- Roll the Bones if you have 2 or fewer buffs if neither consist of
            -- Broadside, Ruthless Precision or True Bearing. Cast ONCE
            -- immediately after using Keep It Rolling.
            return actions["rollthebones"]

        elseif adrenalinerushcd > 0 and cp5 == 0 then
            -- Adrenaline Rush on cooldown at 2 or fewer combo points.
            return actions["adrenalinerush"]
        
        elseif killingspreecd > 0 and cp6 > 0 then
            -- Killing spree off CD, Adrenaline Rush > 5s remaining and at least 6 CP
            return actions["killingspree"]

        elseif betweentheeyescd > 0 and (cp6 > 0 or (cp5 > 0 and subterfuge > 0)) then
            -- Between the Eyes if buff duration is 4 or less seconds, or you
            -- have Ruthless Precision buff active at 6 or more combo points.
            -- During Subterfuge finish at 5 or more as your only finisher.
            return actions["betweentheeyes"]
            
        elseif ghostlystrikecd > 0 then
            -- Ghostly Strike on CD.
            return actions["ghostlystrike"]
            
        elseif stealth == 0 and subterfuge == 0 and vanishcd > 0 and cp6 > 0 and adrenalinerushbuff > 0 then
            -- Vanish followed by Between the Eyes at 6 or more combo points
            -- while Adrenaline Rush is active AND ANY 1 of the following
            -- conditions is met. Adrenaline Rush has 3 or less seconds
            -- remaining. Vanish has 15 seconds remaining on overcapping.
            -- Between the Eyes is on cooldown AND  Ruthless Precision is
            -- active.
            return actions["vanish"]

        elseif cp6 > 0 then
            -- Dispatch if at 6 or more combo points.
            return actions["dispatch"]

        elseif cp5 == 0 and (audacity > 0 or subterfuge > 0) then
            -- Ambush if you have Audacity, or are in Subterfuge at 4 or less
            -- combo points.
            return actions["ambush"]

        elseif opportunity > 0 and cp5 == 0 then
            --  Pistol Shot if you have Opportunity at 3 or less combo points.
            --  With Broadside active, only cast at 1 or less combo points.
            return actions["pistolshot"]

        elseif cp6 == 0 then
            -- Sinister Strike at 5 or less combo points.
            return actions["sinisterstrike"]

        end

    elseif action == ACTION_AOE then
        -- AOE
        if bladeflurry > 0 then
            -- Blade Flurry if there are 2 or more targets in range, and is not
            -- already active.
            return actions["bladeflurry"]

        elseif shouldkeepitrolling > 0 and keepitrollingcd > 0 then
            -- Keep It Rolling if you have any 4 active Roll the Bones buffs.
            return actions["keepitrolling"]

        elseif shouldrollthebones > 0 and rollthebonescd > 0 then
            -- Roll the Bones if you have 2 or fewer buffs if neither consist of
            -- Broadside, Ruthless Precision or True Bearing. Cast ONCE
            -- immediately after using Keep It Rolling.
            return actions["rollthebones"]

        elseif adrenalinerushcd > 0 and cp5 == 0 then
            -- Adrenaline Rush on cooldown at 2 or fewer combo points.
            return actions["adrenalinerush"]
        
        elseif killingspreecd > 0 and cp6 > 0 then
            -- Killing spree off CD, Adrenaline Rush > 5s remaining and at least 6 CP
            return actions["killingspree"]

        elseif betweentheeyescd > 0 and (cp6 > 0 or (cp5 > 0 and subterfuge > 0)) then
            -- Between the Eyes if buff duration is 4 or less seconds, or you
            -- have Ruthless Precision buff active at 6 or more combo points.
            -- During Subterfuge finish at 5 or more as your only finisher.
            return actions["betweentheeyes"]

        elseif ghostlystrikecd > 0 then
            -- Ghostly Strike on CD.
            return actions["ghostlystrike"]

        elseif stealth == 0 and subterfuge == 0 and vanishcd > 0 and cp6 > 0 and adrenalinerushbuff > 0 then
            -- Vanish followed by Between the Eyes at 6 or more combo points
            -- while Adrenaline Rush is active AND ANY 1 of the following
            -- conditions is met. Adrenaline Rush has 3 or less seconds
            -- remaining. Vanish has 15 seconds remaining on overcapping.
            -- Between the Eyes is on cooldown AND  Ruthless Precision is
            -- active.
            return actions["vanish"]

        elseif cp6 > 0 then
            -- Dispatch if at 6 or more combo points.
            return actions["dispatch"]

        elseif cp5 == 0 and (audacity > 0 or subterfuge > 0) then
            -- Ambush if you have Audacity, or are in Subterfuge at 4 or less
            -- combo points.
            return actions["ambush"]

        elseif opportunity > 0 and cp5 == 0 then
            --  Pistol Shot if you have Opportunity at 3 or less combo points.
            --  With Broadside active, only cast at 1 or less combo points.
            return actions["pistolshot"]

        elseif cp6 == 0 then
            -- Sinister Strike at 5 or less combo points.
            return actions["sinisterstrike"]
        end
    end

    return nil
end

return nextAction
