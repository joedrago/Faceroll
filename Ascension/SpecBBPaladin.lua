-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "975774", "PALADIN-ASCENSION")
Faceroll.aliasSpec(spec, "PALADIN-Twist of Faith")
Faceroll.aliasSpec(spec, "PALADIN-Hammerstorm")

spec.melee = "Crusader Strike"

local availableBuffs = {}
availableBuffs.m = {["name"]="Blessing of Might",  ["key"]="might"}
availableBuffs.w = {["name"]="Blessing of Wisdom", ["key"]="wisdom"}
availableBuffs.k = {["name"]="Blessing of Kings", ["key"]="kings"}

local partyBuffsRequested = nil
local partyBuffSeen = {}
local function partyBuffSeenCount()
    local count = 0
    for k,v in pairs(partyBuffSeen) do
        count = count + 1
    end
    return count
end

local function everyoneBuffed()
    if partyBuffsRequested == nil then
        -- no buffs configured
        return true
    end

    local countSeen = partyBuffSeenCount()
    if countSeen > 0 and ((countSeen+1) == GetNumGroupMembers()) then
        return true
    end
    return false
end

local function targetIsPartyMember()
    for i = 1,4 do
        if UnitIsUnit("target", "party" .. i) == 1 then
            return true
        end
    end
    return false
end

local function UnitRole(unit)
    local roleTank, roleHealer, roleDPS = UnitGroupRolesAssigned(unit)
    local role = "NONE"
    if roleTank then
        role = "TANK"
    elseif roleHealer then
        role = "HEALER"
    elseif roleDPS then
        role = "DPS"
    end
    return role
end

local function requestedBuff(unitIndex, class, role)
    if partyBuffsRequested == nil then
        return nil
    end

    local reqCount = #partyBuffsRequested
    if unitIndex < 1 or unitIndex > reqCount then
        return nil
    end

    local buffShortName = partyBuffsRequested[unitIndex]

    if buffShortName == "a" then
        -- assume Kings
        buffShortName = "k"

        if role == "HEALER" then
            buffShortName = "w"
        end
        if class == "MAGE" then
            buffShortName = "w"
        end
        if class == "WARLOCK" then
            buffShortName = "w"
        end
        if class == "PRIEST" then
            buffShortName = "w"
        end
        if not Faceroll.options["nomight"] then
            if class == "HUNTER" then
                buffShortName = "m"
            end
            if class == "ROGUE" then
                buffShortName = "m"
            end
            if class == "WARRIOR" and role == "DPS" then
                buffShortName = "m"
            end
        end
    end

    local buff = availableBuffs[buffShortName]
    if buff == nil then
        return nil
    end
    return buff
end

spec.setOption = function(raw)
    partyBuffSeen = {}
    if strlenutf8(raw) == 0 then
        partyBuffsRequested = nil
        print("Disabling party buffs.")
        return
    end

    partyBuffsRequested = { strsplit(" ", raw) }
    for i, v in ipairs(partyBuffsRequested) do
        local unit = "party" .. i
        local unitName = UnitName(unit)
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            local role = UnitRole(unit)
            local buff = requestedBuff(i, class, role)
            local buffName = "(Ignore)"
            if buff ~= nil then
                buffName = buff.name
            end
            print(" * " .. Faceroll.textColor(unitName, "ffffaa") .. "(" .. Faceroll.textColor(class, "aaaaff") .. ", " .. Faceroll.textColor(role, "aaffff") .. ") -> " .. Faceroll.textColor(buffName, "aaffaa"))
        end
    end
end

-----------------------------------------------------------------------------------------
-- States

spec.options = {
    "nomight",
    "burn",
}

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "selfheal",
    "normHP",
    "normMana",
    "group",
    "allbuffed",
    "twisting",
    "nomight",
    "burn",

    "- Buffs -",
    "sealcommand",
    "echocommand",
    "echovengeance",
    "blessing",

    "- Spells -",
    "crusaderstrike",
    "judgement",
    "hand",
    "consecration",
    "hammerstorm",
    "divineplea",
    "hammerofwrath",
    "holyshield",
    "holywrath",
    "avengersshield",
    "divinestorm",
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    if Faceroll.combatJustEnded then
        partyBuffSeen = {}
    end
    state.allbuffed = everyoneBuffed()
    state.twisting = (state.key == "PALADIN-Twist of Faith")

    -- Resources --
    Faceroll.deadzoneUpdate(healDeadzone)
    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if Faceroll.hasManaForSpell("Holy Light") and not Faceroll.deadzoneActive(healDeadzone) then
        state.selfheal = true
    end
    state.normHP = norHP
    if IsInGroup() then
        state.group = true
    end
    local curMana = UnitPower("player")
    local maxMana = UnitPowerMax("player")
    local norMana = curMana / maxMana
    state.normMana = norMana

    -- Buffs --

    if Faceroll.isBuffActive("Seal of Command") or Faceroll.isBuffActive("Seal of Wisdom") then
        state.sealcommand = true
    end
    if Faceroll.getBuffRemaining("Echo of Command") >= 1 then
        state.echocommand = true
    end
    if Faceroll.getBuffRemaining("Echo of Vengeance") >= 1 then
        state.echovengeance = true
    end
    if Faceroll.isBuffActive("Blessing of Wisdom") then
        state.blessing = true
    end

    -- if Faceroll.isBuffActive("Arcane Intellect") or Faceroll.isBuffActive("Arcane Brilliance") then
    --     state.arcaneintellect = true
    -- end
    -- if Faceroll.isBuffActive("Drink") then
    --     state.drink = true
    -- end
    -- if Faceroll.getBuffRemaining("Drink") < 4 then
    --     state.drinkending = true
    -- end
    -- if Faceroll.isBuffActive("Ice Barrier") then
    --     state.icebarrier = true
    -- end

    -- Spells --

    if Faceroll.isSpellAvailable("Crusader Strike") then
        state.crusaderstrike = true
    end
    if Faceroll.isSpellAvailable("Judgement of Light") then
        state.judgement = true
    end
    if Faceroll.isSpellAvailable("Hand of Reckoning") then
        state.hand = true
    end
    if Faceroll.isSpellAvailable("Consecration") then
        state.consecration = true
    end
    if Faceroll.isSpellAvailable("Hammerstorm") then
        state.hammerstorm = true
    end
    if Faceroll.isSpellAvailable("Divine Plea") then
        state.divineplea = true
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        state.hammerofwrath = true
    end
    if Faceroll.isSpellAvailable("Holy Shield") then
        state.holyshield = true
    end
    if Faceroll.isSpellAvailable("Holy Wrath") then
        state.holywrath = true
    end
    if Faceroll.isSpellAvailable("Avenger's Shield") then
        state.avengersshield = true
    end
    if Faceroll.isSpellAvailable("Divine Storm") then
        state.divinestorm = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "might",
    "wisdom",
    "kings",
    "sealcommand",
    "hammerstorm", -- "sealvengeance",
    "crusaderstrike",
    "judgement",
    "hand",
    "consecration",
    "targetparty",
    "divineplea",
    "hammerofwrath",
    "heal",
    "holyshield",
    "holywrath",
    "avengersstorm", -- this is *also* divine storm
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.selfheal and (not state.combat and (state.normHP <= 0.7)) then
        return "heal"

    elseif not state.twisting and not state.sealcommand then
        return "sealcommand"

    elseif state.twisting and not state.echocommand and not state.echovengeance then
        if state.sealcommand then
            return "sealvengeance"
        else
            return "sealcommand"
        end

    elseif state.divineplea and state.normMana <= 0.70 then
        return "divineplea"

    elseif not state.blessing then
        return "wisdom"

    elseif state.targetingenemy then
            if not state.combat and not state.group and state.hand then
                return "hand"

            elseif state.holyshield then
                return "holyshield"

            elseif state.burn and state.avengersshield then
                return "avengersstorm"

            elseif state.judgement then
                return "judgement"

            elseif state.melee and state.consecration then
                return "consecration"

            elseif state.melee and state.hammerstorm then
                return "hammerstorm"

            elseif aoe and state.melee and state.divinestorm then
                return "avengersstorm"

            elseif state.burn and state.melee and state.holywrath then
                return "holywrath"

            elseif state.melee and state.hammerofwrath then
                return "hammerofwrath"

            elseif state.crusaderstrike then
                return "crusaderstrike"

            elseif state.melee and state.divinestorm then
                return "avengersstorm"

            end
        -- end

    elseif not state.combat and not aoe and state.group and everyoneBuffed() and targetIsPartyMember() then
        return nil

    elseif not state.combat and not aoe and state.group and not everyoneBuffed() then
        -- buff teammates
        local unitIndex = 0
        for i = 1,4 do
            if (unitIndex == 0) and (UnitIsUnit("target", "party" .. i) == 1) then
                unitIndex = i
            end
        end
        if unitIndex > 0 then
            local unit = "party" .. unitIndex
            local _, class = UnitClass(unit)
            local role = UnitRole(unit)
            local reqBuff = requestedBuff(unitIndex, class, role)
            if reqBuff == nil then
                print("Unit " .. unit .. " does not want a buff.")
                partyBuffSeen[unit] = true
                if everyoneBuffed() then
                    print("I've buffed everyone.")
                    return nil
                end
            else
                local aura = Faceroll.ascensionFindAura(unit, reqBuff.name, "HELPFUL")
                if aura == nil then
                    -- print("Unit " .. unit .. " NEEDS " .. reqBuff.name .. " (" .. reqBuff.key .. ")")
                    return reqBuff.key
                else
                    -- print("Unit " .. unit .. " already has " .. reqBuff.name .. " (" .. reqBuff.key .. ")")
                    partyBuffSeen[unit] = true

                    if everyoneBuffed() then
                        print("I've buffed everyone.")
                        return nil
                    end
                    return "targetparty"
                end
            end
        else
            return "targetparty"
        end
    end

    return nil
end
