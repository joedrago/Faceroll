-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock (Dungeon)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WD", "aaaaff", "WARLOCK-Demonic Reoccurence")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")
Faceroll.enemyGridTrack(spec, "Immolate", "IMM", "626218")
-- Faceroll.enemyGridTrack(spec, "Curse of Agony", "COA", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Spells -",
    "firestorm",
    "meta",
    "soulfire",
    "drainingsoul",
    "empowerment",

    "-- Buffs --",
    "shadowtrance",
    "moltencore",

    "-- Dots --",
    "corruption",
    "elements",
    "immolate",
    "immodeadzone",
    "incineratedeadzone",

    "- State -",
    "needtap",
    "wantstapbuff",
    "shards",

    "-- Mode --",
    "trash",
    "boss",
})

spec.options = {
    "shards",
    "boss|mode",
    "trash|mode",
}

spec.radioColors = {
    "ffaaaa",
    "ffffaa",
}

local immoDeadzone = Faceroll.deadzoneCreate("Immolate", 0.3, 2)
local soulfireDeadzone = Faceroll.deadzoneCreate("Soul Fire", 0.3, 2)
local incinerateDeadzone = Faceroll.deadzoneCreate("Incinerate", 0.3, 2)

spec.calcState = function(state)
    -- Spells
    if Faceroll.isSpellAvailable("Fire Storm") then
        state.firestorm = true
    end
    if Faceroll.isSpellAvailable("Metamorphosis") then
        state.meta = true
    end
    if Faceroll.isSpellAvailable("Demonic Empowerment") then
        state.empowerment = true
    end

    local channelingSpell, _, _, _, _, channelEndMS = UnitChannelInfo("player")
    if channelingSpell == "Drain Soul" then
        state.drainingsoul = true
    end

    Faceroll.deadzoneUpdate(soulfireDeadzone)
    if Faceroll.isBuffActive("Decimation") and Faceroll.isSpellAvailable("Soul Fire") and not Faceroll.deadzoneActive(soulfireDeadzone) then
        state.soulfire = true
    end

    if Faceroll.getBuffStacks("Molten Core") == 1 then
        Faceroll.deadzoneUpdate(incinerateDeadzone)
    end
    if Faceroll.deadzoneActive(incinerateDeadzone) then
        state.incineratedeadzone = true
    end

    -- Buffs
    if Faceroll.isBuffActive("Shadow Trance") then
        state.shadowtrance = true
    end
    if Faceroll.isBuffActive("Molten Core") then
        state.moltencore = true
    end

    -- -- Debuffs
    if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
        state.corruption = true
    end
    if Faceroll.getDotRemainingNorm("Curse of the Elements") > 0.1 then
        state.elements = true
    end
    if Faceroll.getDotRemainingNorm("Immolate") > 0.1 then
        state.immolate = true
    end

    -- Never cast Immolate twice in a row
    Faceroll.deadzoneUpdate(immoDeadzone)
    if Faceroll.deadzoneActive(immoDeadzone) then
        state.immodeadzone = true
    end

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    local mana = UnitPower("player", Enum.PowerType.Mana)
    local manamax = UnitPowerMax("player", Enum.PowerType.Mana)
    local mananorm = mana / manamax
    if (hpnorm >= 0.25) and (mananorm < hpnorm) then
        state.needtap = true
    end
    if not Faceroll.isBuffActive("Life Tap") then
        state.wantstapbuff = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "tap",
    "corruption",
    "elements",
    "immolate",
    "soulfire",
    "incinerate",
    "firestorm",
    "seed",
    "drainsoul",
    "empowerment",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.shards then
        if not state.drainingsoul then
            return "drainsoul"
        else
            return nil
        end

    -- get some mana back
    elseif state.needtap and (not state.combat or not state.targetingenemy or state.wantstapbuff) then
        return "tap"

    elseif st then
        if state.targetingenemy then
            -- Curse
            if state.boss and not state.elements then
                return "elements"

            -- Pet buff
            elseif state.empowerment then
                return "empowerment"

            -- maintain dots
            elseif not state.corruption then
                return "corruption"
            elseif not state.immolate and not state.immodeadzone then
                return "immolate"

            -- filler
            elseif state.soulfire then
                return "soulfire"
            else
                return "incinerate"

            end
        end

    elseif aoe then
        if state.firestorm then
            return "firestorm"

        else
            return "seed"

        end
    end

    return nil
end
