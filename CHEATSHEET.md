# New Spec Cheat Sheet

## Overview

A spec file's job is to provide the following:

* Identify which unique class/spec combos it is responsible for driving
* Harvest instantaneous game state for that spec into a single `state` structure
* Determine the appropriate "action" for each mode _(ST, AOE)_ based on that `state`
* _(optional)_ provide dots to automatically track on all nearby mobs
* _(optional)_ provide character specific macros
* _(optional)_ provide automatic spell/macro keybinds


## Instructions

* Create a new `Spec*.lua` file, using this [skeleton](#skeleton).
* Add the new file's name to `Faceroll.toc`
* Restart wow client entirely
* Tweak the spec, then use `/reload` to see changes

## Spec Choice

Faceroll uses the "spec key" to determine what spec is active when signed into a character. It follows a pattern that looks like this: `CLASS-SPEC`, where `CLASS` is always the name of the class in all caps (like `DRUID`), and `SPEC` depends on the version of WoW you are playing:

* If you are on a Classic realm and have no points allocated, the spec is `CLASSIC`
* If you are on a Classic realm and have points allocated, it is the number corresponding to the talent tab with the most points spent in it. For example, a Feral Druid would be `DRUID-2`.
* If you are on a class-free realm like Ascension's Area 52, your class is always `HERO` and either `ASCENSION` if you don't have a legendary ME slotted, or it is the full name of the Legendary ME if one is slotted.

Because you might have a single spec file which you level from 1-10 with no talent points but _eventually_ will have points in tab `2`, you can use `Faceroll.aliasSpec()` to signal multiple spec keys for a single spec file. This allows you to have both `DRUID-CLASSIC` and `DRUID-2` use a single spec, or perhaps have a special spec that is only useful until you pick your first point instead.

## Enemy Grid

If you want to track AOE dots, you can leverage `Faceroll.enemyGridTrack()` for a spec which simply takes a dot you want to track on targets and a name/color for the UI, and it'll do the rest. You can track as many dots as you want.

## Macros

`spec.macros` can list all macros the spec is planning to use. It not required to use this tech at all, but it makes setting up a new character very easy, using `/frsetup` or `/frm`. If you never use either of these commands, this table is completely unused. If do use them though, each entry will have ` FR` appended to it and automatically created in your character specific macros (a macro named `Bear` will be stored on the character macros as `Bear FR`).

Macros declared in this way have a special _optional_ syntax when naming spells which allow you to do some cool fallbacks or bailouts when building macros. For example, if instead of using the raw text `Bear Form` in a macro you instead wrapped it as `@Bear Form@`, the `/frm` or `/frsetup` command will make sure you have a spell named `Bear Form` before creating this macro at all. This will allow you to avoid creating macros during `/frsetup` that can't be used, and allows checks like `Faceroll.isActionAvailable()` to organically see that you just don't have that button yet. Similarly, if you connect multiple spells together like `@Dire Bear Form|Bear Form@`, it will try to find the first one you own and only use that. This allows a single macro to transform from one spell to another if you run `/frsetup` when you level up and learn new ranks of spells.

Finally, there's a double wrap like `@@Blizzard@@`, which performs similar checks as explained above, but if it finds it, it writes the _spell ID_ instead. This is a very special case but works out really well for certain GM commands like `.cast`.

## Options

`spec.options` allows for manually toggled options which can show up as state in `calcState()`. For example, if you wanted to have a "burst window" which you rarely did, you could make an option named `"burst"`, and then have a macro named `/fro burst` which would toggle it from false to true in the UI. This value would then show up as `state.burst` in any spec functions automatically.

You can also append `|SOMEWORD` to make radio buttons. For example, if you wanted a "mode" which toggled between `dps` and `tank`, you could make two options `dps|mode` and `tank|mode`, and `/frr mode` would cycle between all radio buttons for `mode`.

# Debug Overlay / Automatic Tracking

The values passed to `createOverlay()` signal what is tracked in Faceroll's debug overlay (`/frd` to cycle between debug overlay display modes). It simply displays whatever subset of `state` variables you want to see while debugging a spec, but can also be used as a shorthand to tracking specific kinds of state.

Any string listed with a dash in front (`"- Spells -",`) is treated as a header and is ignored everywhere except in the overlay render.

Simply listing a property as a string will track it, and you can set the value of that `state.property` inside of your `calcState()`, but there's some really common patterns that faceroll's overlay table will allow as a shorthand to save you time:

Example:

```lua
    { "f_cat",        3 },
    { "b_rejuv",      "Rejuvenation" },
    { "s_fff",        "Faerie Fire (Feral)" },
    { "d_fff",        "Faerie Fire (Feral)" },
```

Each of these has a prefix (such as `f_`) and an argument (`3`), and based on the prefix, assumes the following:

| Prefix | Description | Argument | Shorthand For |
|---|---|---|---|
| `f_` | is in form `v`? | form/stance # | `GetShapeshiftForm() == v` |
| `b_` | is buff `v` active? | buff name | `Faceroll.isBuffActive(v)` |
| `d_` | is dot `v` on target? | dot name | `Faceroll.getDotRemainingNorm(v) > 0.1` |
| `s_` | is spell `v` ready? | spell name | `Faceroll.isSpellAvailable(v)` |

If an overlay table is setup this way, these properties will already have that shorthand's value in it when entering `calcState()`. You can use/override the values in there, and then use them in `calcAction()` later.

In addition to the above shorthands, the `createOverlay()` function also enables a few stock properties that are autopopulated:

| Property | Description |
|---|---|
| `state.level` | your character's level |
| `state.targetingenemy` | you currently targeting a mob you can attack |
| `state.targetcasting` | your target is casting a spell |
| `state.combat` | you are in combat |
| `state.group` | you are in a group |
| `state.autoattack` | you are auto-attacking |
| `state.melee` | you are in melee range to your target |
| `state.hp` | your normalized HP value (`1.0` is full) |
| `state.mana` | your normalized Mana value (`1.0` is full) |
| `state.rage` | your raw rage amount |
| `state.energy` | your raw energy amount |
| `state.combopoints` | your current combo points  |

## calcState()

This is where you look over gamestate and populate the `state` variable, then return it. You do not need to have anything in this function other than `return state` if the overlay shorthand and options are sufficient, but in addition to any `Faceroll.*()` functions you might want to call, you have full access to any WoW Lua APIs here as well. This is where your spec can come up with truly custom state to be shown in the overlay or acted on in `calcAction()`.

## spec.actions

This table lists all possible return values for `calcAction()`, and represents all possible actions this spec can ever perform. The order of actions in this table maps directly to the ordinal keys in `Faceroll.keys`, such as `Faceroll.keys[1]`'s keybinding mapping directly to the first action. If `calcAction()` ever returns the first action's string for the active mode, Faceroll will mash whatever is set to `Faceroll.keys[1]` until `calcAction()` returns a different string or the mode is disabled.

Similarly to the overlay table, it can simply be a list of freeform strings whose names are only meaningful to `calcAction()`, but they can also be small tables which hint at what these bindings should have in them (spells, macros, etc). As an example:

```lua
spec.actions = {
    { "bear",       macro = "Bear" },
    { "maul",       macro = "Maul" },
    { "swipe",      spell = "Swipe" },
    { "roar",       spell = "Demoralizing Roar" },
}
```

This binds the first 4 keybinds to `bear`, `maul`, `swipe`, and `roar`, respectively, but also signals to the `/frsetup` system what those action bar slots should hold, if you wanted to set them up for you. It will attempt to populate all `spell =` with the highest rank spell you have learned by that name, or it will leave the bar blank. `macro = ` will attempt to use that macro name with ` FR` appended, similarly to how `/frm` above creates the macros. This means if you create macros in `state.macros`, name them here, then use `/frsetup`, it will create all macros, and then populate as many action bar slots as it can. Any slots that don't get populated can be queried by name in `calcAction()` via `Faceroll.isActionAvailable()`, which takes one of your action's names and returns true if it thinks there's something in that slot.

**TL;DR** - Running `/frsetup` after learning new spells/ranks can slowly populate your bars, and combining this careful use of `Faceroll.isActionAvailable()` in `calcAction()` will allow a single spec file to work across the entire leveling experience with little effort!

## calcAction()

The goal of this function is to take a `state` that was crafted via all of the code above and a `mode` which is either `Faceroll.MODE_ST` (single target) or `Faceroll.MODE_AOE` (AOE) and returns which action string from the `spec.actions` table should be pressed. If no action should be pressed, return `nil`.

This function _can_ do anything `calcState()` can do, but will be called multiple times for each "state" calculation, as both the overlay and the bits channels always sends both modes' worth of answers at all times. Do complicated queries in `calcState()` and simply pick an action based on the state in `calcAction()`.

## Skeleton
```lua
-----------------------------------------------------------------------------------------
-- Classic Feral Druid

if Faceroll == nil then
    _, Faceroll = ...
end

-- 2 is "this is when this class has most of its talent points in the tree 2"
local spec = Faceroll.createSpec("ABC", "aaffaa", "DRUID-2")

-- if you want to use this file when your class has no talent points spent
Faceroll.aliasSpec(spec, "DRUID-CLASSIC")

-----------------------------------------------------------------------------------------
-- Enemy Grid

-- actual dot name / name in UI / color in UI
Faceroll.enemyGridTrack(spec, "Rake", "RAKE", "621518")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Bear"] = [[
#showtooltip
/cast !@Dire Bear Form|Bear Form@
]],

["Maul"] = [[
#showtooltip
/cast !@Maul@
/startAttack
]],

["OSomeOption"] = [[
/fro someoption
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.options = {
    "someoption",
}

spec.overlay = Faceroll.createOverlay({
    "- Options -",
    "someoption",

    "- Form -",
    { "f_bear",       1 },

    "- Bear -",
    { "s_roar",       "Demoralizing Roar" },
    { "d_roar",       "Demoralizing Roar" },
})

-- (spec.calcState is optional — only define it if you need custom state.)

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "bear",       macro = "Bear" },
    { "maul",       macro = "Maul" },
    { "swipe",      spell = "Swipe" },
    { "roar",       spell = "Demoralizing Roar" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if not state.f_bear then
            return "bear"

        elseif state.melee and state.s_roar and not state.d_roar then
            return "roar"
        elseif aoe and state.melee then
            return "swipe"
        else
            return "maul"
        end
    end
end
```
