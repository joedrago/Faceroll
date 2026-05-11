# Implementing a Faceroll Spec — Complete Guide

This document teaches you everything you need to implement a fully functional WoW WotLK spec file for the Faceroll addon. After reading this, you should be able to take a request like "implement Retribution Paladin" and produce a spec file that works from level 10 to 80 with no further guidance.

---

## 1. What Faceroll Does

Faceroll is a WoW addon that automates action selection. Each spec file is the "brain" for one class/spec combination. The pipeline is:

1. **Harvest state** — read buffs, dots, cooldowns, resources, combat status
2. **Decide action** — pick the best thing to press right now (ST and AOE independently)
3. **Signal the bridge** — tell the external key-press system which keybind to mash

Your spec file defines steps 1 and 2. Everything else is handled by the framework.

---

## 2. File Setup

### Naming Convention

- `SpecClass0.lua` — the "classic" spec, before first talent point (level 1-9)
- `SpecClass1Specname.lua` — talent tree 1 (e.g., `SpecMage1Arcane.lua`)
- `SpecClass2Specname.lua` — talent tree 2 (e.g., `SpecMage2Fire.lua`)
- `SpecClass3Specname.lua` — talent tree 3 (e.g., `SpecMage3Frost.lua`)

### Header and Initialization

Every file starts with:

```lua
-----------------------------------------------------------------------------------------
-- Nostalgia Arcane Mage (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ARC", "a674db", "MAGE-1")
```

- **First argument**: a short display name, 5 characters or fewer (e.g., "ARC", "FERAL", "BM")
- **Second argument**: a hex color that represents this spec's identity (no `#` prefix)
- **Third argument**: the spec key — `CLASS-N` where CLASS is uppercase and N is the tree number. For spec 0 files, use `CLASS-CLASSIC` (e.g., `"MAGE-CLASSIC"`)

### Faceroll.toc

Add your file to `Faceroll.toc` in the `# -- Nostalgia WoW Specs --` section, sorted alphabetically.

---

## 3. The /frsetup Pipeline — Why Everything "Just Works"

This is the single most important concept. Understanding this makes leveling-compatible specs trivial.

### The Flow

When a player types `/frsetup`, three things happen in order:

1. **`/frm`** — Create macros. For each entry in `spec.macros`, resolve any `@spell@` or `@@spell@@` patterns and create the macro. If a spell doesn't exist (because you haven't trained it yet), the macro **fails to create on purpose**.
2. **`/frb`** — Place actions. For each entry in `spec.actions` that has a `macro =` or `spell =` hint, place it on the corresponding action bar slot. If the macro doesn't exist (because it failed in step 1), the slot stays empty.
3. **Rebuild key map** — Faceroll scans the action bar to learn which slots have actions and which are empty.

### The Consequence

After `/frsetup`, `Faceroll.isActionAvailable("actionname")` returns `true` only if the action's bar slot has something in it. If a spell wasn't known, the macro wasn't created, the slot is empty, and `isActionAvailable` returns `false`.

**This means you never need explicit level checks.** The bar state *is* your level gate. Your `calcAction` can reference abilities the character doesn't have yet, and they'll be silently skipped because `isActionAvailable` (or the `s_` shorthand) will return false.

The player only needs to `/frsetup` once after training new spells or talents. Each run progressively fills in more of the action bar as spells become available.

### @ Syntax (Spell Existence Gate)

```
@Spell Name@
```

Wrapping a spell name in single `@` means: "only include this spell if the character knows it." If the spell isn't in the spellbook, the entire macro fails to create. This is intentional — it's how you gate actions behind spell availability.

**Fallback chains:**

```
@Dire Bear Form|Bear Form@
```

Try the first spell; if unknown, try the second. Use this when a spell upgrades (e.g., Bear Form → Dire Bear Form) so a single macro works at any level.

### @@ Syntax (Spell ID Resolution)

```
@@Blizzard@@
```

Double `@@` resolves to the spell's numeric ID (highest rank known). This is specifically needed for `.cast` ground-targeted macros that use GM commands, where the spell ID is required instead of the name.

---

## 4. Macros Deep Dive

Declare macros in `spec.macros`. Each key is the macro name (will be stored as `"Name FR"` in character macros), and the value is the macro body.

### Simple Cast

```lua
["Frostbolt"] = [[
#showtooltip
/cast @Frostbolt@
]],
```

The `@Frostbolt@` gate means this macro won't be created if Frostbolt isn't known.

### Channel Guard

When a spec uses a channeled spell (Blizzard, Hurricane, Arcane Missiles, etc.) alongside other spells in the same mode, any non-channeled spell that Faceroll might recommend during the channel needs a `[nochanneling]` guard in its macro. Without it, Faceroll will interrupt the channel the moment it decides another spell is higher priority.

**The rule:** if spell A is channeled and spell B can be recommended in the same mode (ST or AOE), spell B's macro should use `[nochanneling]`. This way, pressing B's keybind while A is channeling does nothing — the channel finishes naturally.

**Example — Frost Mage AOE:** Blizzard is channeled. Deep Freeze might also be recommended during AOE (e.g., to lock down a target). Without a guard, pressing Deep Freeze mid-Blizzard cancels the channel:

```lua
-- BAD: will interrupt Blizzard if Deep Freeze is recommended during AOE
["DeepFreeze"] = [[
#showtooltip
/cast @Deep Freeze@
]],

-- GOOD: won't fire while Blizzard is channeling
["DeepFreeze"] = [[
#showtooltip
/cast [nochanneling] @Deep Freeze@
]],
```

**Example — Arcane Mage:** Arcane Missiles is channeled. Arcane Blast is the filler and can be recommended at any time:

```lua
["Blast"] = [[
#showtooltip
/cast [nochanneling] @Arcane Blast@
]],
```

**When NOT to use it:** Don't add `[nochanneling]` to spells that are never recommended in the same mode as the channel, or to the channeled spell's own macro (channeled spells already have their own guards — see "Ground-Targeted Spells" for the `/stopmacro [channeling]` pattern). Also don't add it to spells that *should* interrupt the channel (e.g., a high-priority interrupt like Counterspell should cancel Blizzard to lock down a dangerous cast).

### On-Next-Hit Melee Abilities

Abilities like Maul, Heroic Strike, and Cleave are "on next melee hit" — they queue onto your next auto-attack. These need:
- The `!` prefix to prevent toggling off if pressed twice
- `/startAttack` to ensure auto-attack is running

```lua
["Maul"] = [[
#showtooltip
/cast !@Maul@
/startAttack
]],
```

### Plain Auto-Attack

For specs that just need to swing (early Paladin, early Warrior):

```lua
["Attack"] = [[
/startAttack
]],
```

### Ground-Targeted Spells (.cast)

Spells like Blizzard, Hurricane, Flamestrike, and Rain of Fire are ground-targeted. On private servers using GM-style `.cast`, they need the spell ID via `@@`:

```lua
["Blizzard"] = [[
#showtooltip Blizzard
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Blizzard@@
]],
```

The `/stopmacro [channeling]` prevents re-casting while already channeling. The `/stopmacro [noexist]` prevents casting with no target. The `@@Blizzard@@` resolves to the spell ID of the highest rank of Blizzard you know.

### Form-Conditional Macros

When a spell has different versions per form (e.g., Feral Charge in bear vs cat):

```lua
["Charge"] = [[
#showtooltip
/cast [form:1] @Feral Charge - Bear@
/cast [form:3] @Feral Charge - Cat@
]],
```

### Multi-Spell Fallback

When a spell upgrades at higher levels:

```lua
["Bear"] = [[
#showtooltip
/cast !@Dire Bear Form|Bear Form@
]],
```

Tries Dire Bear Form first; falls back to Bear Form if not yet trained.

### Option Toggle Macros

For toggling spec options (see Section 8):

```lua
["OBurst"] = [[
/fro burst
]],
```

Convention: prefix option toggle macros with `O`.

### Utility Macros

Many specs benefit from common utility macros that aren't part of the rotation but help with movement, form management, or quality-of-life. These don't need actions or calcAction logic — they're placed on the bar manually by the player via `/frsetup` or keybinding.

When researching a spec, look for utility patterns that guides commonly recommend. **Offer these to the user** rather than adding them silently — some players already have their own utility macros and don't want duplicates.

**Common patterns:**

**Dismount / Cancel Form** — drop out of a mount or shapeshift to act as a caster:

```lua
["Human"] = [[
/dismount
/cancelform
]],
```

**Stealth / Prowl with form swap** — enter Cat Form if needed, then stealth:

```lua
["Prowl"] = [[
#showtooltip
/cast [noform:3] !@Cat Form@
/cast [form:3] @Prowl@
]],
```

**Movement speed with form swap** — enter the right form first, then use the speed ability:

```lua
["Dash"] = [[
#showtooltip Dash
/cast [noform:3] !@Cat Form@
/cast [form:3] @Dash@
]],
```

**Mount-or-form travel** — use a travel form when a mount isn't appropriate:

```lua
["Travel"] = [[
#showtooltip
/cast !@Travel Form@
]],
```

**One-button stance swap** — cycle between stances or enter a specific one:

```lua
["DefStance"] = [[
#showtooltip
/cast @Defensive Stance@
]],
```

The key principle: utility macros use the same `@Spell@` gating as rotation macros, so they won't be created if the character doesn't know the spell yet. They don't need actions or overlay entries — they just need to exist in `spec.macros` so `/frsetup` creates them.

### Macro Reuse Across Specs

WoW has a hard limit on character-specific macro slots. Every macro defined in `spec.macros` is stored as `"Name FR"` in the character's macro list — and these add up fast when a class has four spec files (spec 0 + three talent specs). If two specs define a macro with the same name but different bodies, `/frsetup` will overwrite the macro each time you switch specs, but the slot is still consumed.

**The fix:** when multiple specs of the same class need the same spell, use the **same macro name and the same macro body** across all of them. Macros that are identical by name and body share a single character macro slot regardless of how many spec files reference them.

**Example:** every Druid spec that uses Rejuvenation for self-healing should define it identically:

```lua
["Rejuv"] = [[
#showtooltip
/cast [target=player] @Rejuvenation@
]],
```

Before writing a new macro, check the other spec files for the same class. If an existing macro does what you need, copy its name and body exactly. This applies to utility macros too — `"Human"`, `"Dash"`, `"Prowl"`, etc. should be identical across all specs that include them.

### Avoiding Macros for Solo Self-Casts

Self-cast spells that are only used outside of a group (self-buffs, solo self-healing) don't need a `[target=player]` macro. Since Faceroll is active, the player won't be targeting a friendly unit — they'll either have no target or an enemy target. With no friendly target selected, self-castable spells like Mark of the Wild, Thorns, and Rejuvenation default to the caster automatically.

Use `spell =` in the action instead of creating a macro. This saves a character macro slot per spell:

```lua
-- No macro needed — just use spell hint directly
{ "motw",    spell = "Mark of the Wild" },
{ "thorns",  spell = "Thorns" },
{ "rejuv",   spell = "Rejuvenation" },
```

**Exception:** if a self-cast spell is also used in group content (where the player might target a friendly), it still needs a `[target=player]` macro to guarantee it lands on self.

---

## 5. Overlay & Automatic State Tracking

The overlay definition serves two purposes: it configures the debug overlay display (`/frd`), and it **auto-populates state fields** using shorthand prefixes.

### Structure

```lua
spec.overlay = Faceroll.createOverlay({
    "- Buffs -",                              -- header (display only)
    { "b_slice",    "Slice and Dice" },       -- auto-check buff
    { "b_stealth",  "Stealth" },

    "- Debuffs -",
    { "d_rupture",  "Rupture" },              -- auto-check dot on target

    "- Spells -",
    { "s_kick",     "Kick" },                 -- auto-check spell availability
    { "s_riposte",  "Riposte" },

    "- Forms -",
    { "f_bear",     1 },                      -- auto-check shapeshift form

    "- Custom -",
    "abstacks",                               -- no prefix: you set this in calcState
})
```

### Shorthand Prefixes

| Prefix | What It Checks | Argument | Result in state |
|--------|---------------|----------|-----------------|
| `s_` | Is spell usable and off cooldown? | spell name | `true` or `false` |
| `b_` | Is buff active on player? | buff name | `true` or `false` |
| `d_` | Is DoT active on target (>10% duration remaining)? | spell name | `true` or `false` |
| `f_` | Is player in this shapeshift form? | form number | `true` or `false` |

These are checked **automatically before your calcState runs**. You don't need to query them manually.

**`f_` vs `b_` for forms:** The `f_` prefix checks by form index number, but form indices can shift when talents add new forms (e.g., Tree of Life moves Moonkin Form from index 5 to 6). If the form index is unstable, track the form as a buff with `b_` instead (e.g., `{ "b_moonkin", "Moonkin Form" }`). This is more robust — the buff name never changes regardless of form index.

### Headers

Strings starting with `"-"` are treated as section headers. They show up in the debug overlay for organization but are ignored everywhere else. Use them liberally — they make the overlay much easier to scan:

```lua
"- Buffs -",
"- Debuffs -",
"- Spells -",
"- Cooldowns -",
"- Procs -",
```

### Only Track What You Use

Every overlay entry runs a check every frame. Only add entries for state you actually reference in `calcState` or `calcAction`. If a spell isn't part of the rotation, don't add an `s_` entry for it. If a DoT isn't checked in the priority list, don't add a `d_` entry. The overlay should be a mirror of what the logic needs — nothing more.

### Auto-Populated Base State

These fields are always available in `state` without any overlay entries:

| Field | Type | Description |
|-------|------|-------------|
| `state.level` | number | Character level |
| `state.targetingenemy` | bool | Currently targeting an attackable enemy |
| `state.targetcasting` | bool | Target is casting a spell |
| `state.combat` | bool | In combat |
| `state.group` | bool | In a party or raid |
| `state.autoattack` | bool | Auto-attack is active |
| `state.melee` | bool | Within melee range of target |
| `state.hp` | float | Normalized health (1.0 = full) |
| `state.mana` | float | Normalized mana (1.0 = full) |
| `state.rage` | number | Raw rage (0-100) |
| `state.energy` | number | Raw energy (0-100) |
| `state.runicpower` | number | Raw runic power (0-130) |
| `state.combopoints` | number | Combo points (0-5) |

---

## 6. calcState — Custom State

`calcState` is **optional**. It runs after all automatic state population, and only if you need to compute something the shorthand prefixes (`b_`, `d_`, `s_`, `f_`) and action-property hooks (`deadzone`) can't already handle. If the overlay shorthands cover everything you need, omit `spec.calcState` entirely.

**Important:** Any custom state you set in `calcState` must also have a corresponding entry in the overlay (as a plain string, no prefix). This ensures it shows up in the debug overlay (`/frd`) so you can see its value. If `calcState` sets `state.moving`, the overlay should include `"moving"`.

### Common Custom State Patterns

**Debuff stacks** (e.g., Arcane Blast stacks):

```lua
spec.calcState = function(state)
    state.abstacks = 0
    local abDebuff = Faceroll.getDebuff("Arcane Blast")
    if abDebuff ~= nil then
        state.abstacks = abDebuff.stacks
    end
    return state
end
```

**Target health percentage:**

```lua
state.targethp = 0
if state.targetingenemy then
    state.targethp = UnitHealth("target") / UnitHealthMax("target")
end
```

**Current casting spell:**

```lua
local castingSpell = UnitCastingInfo("player")
if castingSpell then
    state.casting = castingSpell
else
    local channelingSpell = UnitChannelInfo("player")
    if channelingSpell then
        state.casting = channelingSpell
    end
end
```

**Totem presence:**

```lua
if Faceroll.isTotemActive("Searing Totem") then
    state.totems_st = true
end
```

**Conditional state based on form** (e.g., Feral Charge availability depends on bear vs cat):

```lua
if state.f_bear then
    if Faceroll.isSpellAvailable("Feral Charge - Bear") then
        state.s_charge = true
    end
elseif state.f_cat then
    if Faceroll.isSpellAvailable("Feral Charge - Cat") then
        state.s_charge = true
    end
end
```

### Deadzones

A deadzone prevents your spec from re-queuing a spell while it's still being cast or its effect is still in flight. Without a deadzone, Faceroll might recommend casting Vampiric Touch again immediately after the cast bar finishes but before the server confirms the DoT applied.

**When to use:** Any casted spell (non-instant) where re-casting prematurely wastes a GCD. Common examples: Healing Wave, Vampiric Touch, any channeled spell where you track the DoT separately.

**Setup:** Just hang `deadzone = true` on the action entry. Faceroll auto-creates the tracker, runs it each frame, and populates `state.z_<actionName>` (and appends it to the overlay under a `- Deadzones -` separator).

```lua
spec.actions = {
    { "vampirictouch", spell = "Vampiric Touch", deadzone = true },
}

-- In calcAction:
elseif not state.d_vampirictouch and not state.z_vampirictouch then
    return "vampirictouch"
```

`deadzone = true` defaults to a 1.5s cast-time-remaining threshold and a 0.5s post-cast duration — the right values for almost every spell. The deadzone uses `entry.spell` for the spell-name lookup.

**Overrides** (positional table form):

```lua
-- Override threshold/duration:
deadzone = { 0.3, 2 }

-- Override threshold/duration AND specify a spell name (needed when the action uses `macro = "..."`
-- and the actual cast spell isn't named in the entry):
deadzone = { 0.3, 2, spell = "Arcane Missiles" }
```

**Low-level API** (use only if you need to drive a deadzone manually from `calcState`, e.g. branching on its active state mid-frame): `Faceroll.deadzoneCreate(spellName, castTimeRemaining, duration)`, `Faceroll.deadzoneUpdate(dz)` (call every frame; returns true if active), `Faceroll.deadzoneActive(dz)` (peek without updating). The `deadzone =` action property uses these under the hood.

---

## 7. Enemy Grid Tracking

For multi-DoT specs, Faceroll can track your DoTs across all visible enemies using the Kui Nameplates integration.

```lua
Faceroll.enemyGridTrack(spec, "Shadow Word: Pain", "SWP", "621518")
Faceroll.enemyGridTrack(spec, "Devouring Plague", "DP", "621562")
```

Arguments:
1. `spec` — the spec object
2. Spell name — exact name of the DoT as it appears on enemy debuffs
3. Short name — 3-6 character abbreviation for the grid UI
4. Color — hex color for the grid cell

**When to use:** Only for specs whose AOE strategy revolves around spreading and maintaining DoTs on multiple targets — where the player needs to tab-target and refresh DoTs individually. Classic examples: Shadow Priest (SWP, DP, VT), Affliction Warlock (Corruption, UA, CoA). The grid shows remaining duration on each mob so the player knows which target needs a refresh.

**When NOT to use:** If the spec's AOE rotation is primarily direct-damage spells (Hurricane, Blizzard, Starfall, Rain of Fire), the enemy grid adds clutter without value. For example, Balance Druid applies Moonfire/Insect Swarm in ST, but its AOE is Hurricane/Starfall spam — no need to track DoTs across multiple targets.

Place these calls right after `createSpec`, before the macros section.

---

## 8. Options & Radio System

Options let the player toggle behavior at runtime without editing code.

### Boolean Toggles

```lua
spec.options = {
    "burst",
}
```

This creates a state field `state.burst` (default false). The player toggles it with `/fro burst`. Your `calcAction` can branch on it:

```lua
if state.burst and state.s_cooldown then
    return "cooldown"
end
```

Create a macro so the player can keybind the toggle:

```lua
["OBurst"] = [[
/fro burst
]],
```

### Radio Groups

For mutually exclusive options:

```lua
spec.options = {
    "dps|mode",
    "tank|mode",
}
```

`/frr mode` cycles between `dps` and `tank`. Only one in the group is true at a time. Use for specs that have distinct playstyles (Feral bear vs cat, Protection vs DPS stance dancing).

### When to Use Options

- Feral Druid: `"bleed"` toggle for bleed-based rotation, `"bear"` toggle for tank mode
- Any dual-role spec where the player might want to switch behavior mid-session
- Burst windows that the player controls manually

---

## 8.5. Missing-Buff Reminder Stripe (`spec.buffs`)

`spec.buffs` is an **optional** list of self-buffs you want a visual reminder for. Each entry produces one icon on the right edge of the screen *only when the buff is missing*. When you have the buff, the icon disappears and the rest of the stack reflows downward. This is purely visual — `spec.buffs` does not drive `calcAction` or auto-cast anything.

### Schema

```lua
spec.buffs = {
    "Mark of the Wild",                              -- bare string: single spell
    "Thorns",
    "Arcane Intellect|Arcane Brilliance",            -- synonyms: either active counts
    { "Mage Armor", "Ice Armor", "Frost Armor" },    -- cascade: first known wins
}
```

- **Bare string**: track one buff. The buff name is assumed equal to the spell name.
- **List of strings**: a cascade. At runtime, the first spell in the list that the player has actually trained becomes the "winner"; that spell's name is what gets buff-checked, and that spell's icon is what gets drawn. If none are trained, the entry is dormant and reserves no slot.
- **Pipe-separated synonyms (`"A|B"`)**: any candidate string (bare or inside a cascade) can list synonymous buffs separated by `|`. The track is "learned" if any synonym is learned, and "active" if any synonym is active. The icon uses the first synonym in the list.
- **Order of the outer list = stripe order, bottom-up.** The first entry sits at the bottom; subsequent entries stack above it.

### How it behaves

- If the cascade winner's buff is active → no icon (the slot disappears, others reflow down).
- If the cascade winner's buff is missing → icon shown.
- If no cascade candidate is trained → entry contributes nothing, ever.

### When to use a cascade vs a bare string

Use a cascade when one buff supersedes another at higher levels but they're mutually exclusive — armors (`Frost Armor` → `Ice Armor` → `Mage Armor`), seals, fel/demon armor, and similar progression chains. The cascade lets you write the priority once and have it Just Work from level 10 to 80.

For buffs without a progression chain (Mark of the Wild, Thorns, Arcane Intellect, Power Word: Fortitude, Inner Fire), a bare string is fine.

Use the `|` synonym syntax when two buffs are interchangeable — typically a self-cast version and its group-buff counterpart (`Arcane Intellect|Arcane Brilliance`, `Power Word: Fortitude|Prayer of Fortitude`, `Mark of the Wild|Gift of the Wild`). Either form active means you don't need to recast.

### Limits

- The buff name must equal the spell name. This holds for the vast majority of self-buffs in WotLK, but not all (e.g., Hunter aspects sometimes shift naming). If you hit a counterexample, leave a comment and we'll extend the schema.
- Placement is configured globally in `Settings.lua` (`Faceroll.buffsFrame*`), not per-spec.

---

## 9. Actions

```lua
spec.actions = {
    { "sinisterstrike",  macro = "SS" },           -- 1st keybind slot
    { "eviscerate",      spell = "Eviscerate" },   -- 2nd keybind slot
    { "slice",           spell = "Slice and Dice" },
    { "kick",            spell = "Kick" },
    { "fanofknives",     spell = "Fan of Knives" },
    "drink",                                        -- no bar placement
}
```

### Key Mapping

Actions are bound to Faceroll's keybind slots in order. The 1st action maps to `Faceroll.keys[1]`, the 2nd to `Faceroll.keys[2]`, etc. A loose convention is to put the most-frequently-pressed action first, but this is an organizational suggestion, not a requirement. A spec that orders actions differently is not wrong.

### Hints

- `spell = "Name"` — `/frsetup` places the highest rank of this spell on the bar slot
- `macro = "Name"` — `/frsetup` places the macro named `"Name FR"` on the bar slot (the macro must be defined in `spec.macros`)
- String-only entries (like `"drink"`) — no bar placement. Used for actions that the player sets up manually or that don't correspond to a castable ability

### Ordering Strategy

A reasonable default ordering:

1. **Filler/builder** (Sinister Strike, Shadow Bolt, Frostbolt)
2. **Spenders and maintenance** (Eviscerate, Slice and Dice)
3. **Cooldowns and situational** (interrupts, defensive, AOE)
4. **Non-bar actions** last (drink, stop)

This is a guideline, not a rule. Specs may deviate for readability or personal preference.

---

## 10. calcAction — The Heart of the Spec

This is where your WotLK knowledge meets Faceroll's state system. The function receives a mode (ST or AOE) and the fully-populated state, and returns the name of the action to press (or `nil` for nothing).

### Structure

```lua
spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- preamble: self-prep when not targeting enemy
    -- ...

    -- priority list: what to press when targeting enemy
    if state.targetingenemy then
        -- ...
    end
end
```

Always start with `local aoe = (mode == Faceroll.MODE_AOE)`. Add `local st` too if the rotation uses it, but it's fine to omit `st` if you only branch on `aoe`.

### 10a. The Preamble — Self-Prep When Not Targeting

Before the `if state.targetingenemy` block, handle everything the character should do when idle or between pulls. The philosophy: **when the player drops target or leaves combat, the character should automatically prep for the next fight.**

**Form/stance maintenance:**

```lua
if not state.b_moonkin and Faceroll.isActionAvailable("moonkin") then
    return "moonkin"
```

**Self-buffs:**

```lua
if not state.b_lightningshield then
    return "lightningshield"
```

**Out-of-combat self-healing** (solo only, if user opted in — see Section 11 item 10):

Pick **one** healing method — don't stack both a HoT and a cast-time heal. The goal is light sustain between pulls, not burning through mana to top off faster. If the spec has an instant HoT (Rejuvenation, Riptide), prefer that — it's mana-efficient and doesn't delay movement. Otherwise use a cast-time heal with a deadzone.

Instant-cast HoT (preferred when available):

```lua
elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_rejuv then
    return "rejuv"
```

Cast-time heal with deadzone (fallback for specs without a HoT):

```lua
elseif not state.combat and not state.group and state.hp < 0.6 and not state.healdeadzone then
    return "healself"
```

Note the `not state.group` — if you're in a group, let the healer handle it. The buff check (HoT) or deadzone check (cast-time) prevents spam. If the user opted out of self-healing, add a comment documenting that decision (see Section 11, "Documenting Omissions").

**Drinking:**

```lua
elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
    return "drink"
```

The preamble items often don't need `state.targetingenemy` — they apply regardless. Place them before the targeting check. Some specs (like the self-buff checks) can also fire while targeting an enemy, in which case they go inside the targetingenemy block but before combat priorities.

### 10b. The Priority List — Combat Decisions

Inside `if state.targetingenemy`, list priorities from highest to lowest using `if/elseif` chains:

```lua
if state.targetingenemy then
    -- 1. Interrupts (highest priority)
    if not aoe and state.targetcasting and state.s_kick then
        return "kick"

    -- 2. Short-window procs
    elseif state.b_riposte and state.s_riposte then
        return "riposte"

    -- 3. DoT/debuff maintenance
    elseif not state.d_rupture and state.combopoints >= 5 then
        return "rupture"

    -- 4. Buff maintenance
    elseif not state.b_slice and state.combopoints >= 2 then
        return "slice"

    -- 5. Resource spenders
    elseif state.combopoints >= 5 then
        return "eviscerate"

    -- 6. AOE abilities
    elseif aoe and state.melee and Faceroll.isActionAvailable("fanofknives") then
        return "fanofknives"

    -- 7. Filler (always last)
    else
        return "sinisterstrike"
    end
end
```

### General Priority Order

Most specs follow this rough hierarchy:

1. **Interrupts** — if target is casting and your interrupt is ready
2. **Emergency/defensive** — if health is critical
3. **Stealth/opener abilities** — if stealthed (Garrote, Ravage, Ambush)
4. **Short-duration procs** — react before they expire (Art of War, Missile Barrage, Riposte)
5. **Cooldowns** — offensive cooldowns if conditions are right
6. **DoT/debuff maintenance** — apply missing DoTs, refresh expiring ones
7. **Buff maintenance** — keep self-buffs up (Slice and Dice, Savage Roar)
8. **Resource spenders** — spend combo points, use Execute-range abilities
9. **AOE abilities** — when in AOE mode
10. **Filler** — the default spam button (Sinister Strike, Shadow Bolt, Frostbolt)

### 10c. ST vs AOE Branching

There are two common patterns:

**Early split** — when ST and AOE rotations are completely different:

```lua
if state.targetingenemy then
    if st then
        -- entire ST rotation
    elseif aoe then
        -- entire AOE rotation
    end
end
```

**Inline branching** — when most priorities are shared but a few differ:

```lua
if state.targetingenemy then
    if state.targetcasting and state.s_kick then
        return "kick"                          -- shared priority
    elseif aoe and state.melee then
        return "fanofknives"                   -- AOE-specific
    elseif not state.d_rupture and ... then
        return "rupture"                       -- ST-specific
    else
        return "sinisterstrike"                -- shared filler
    end
end
```

Inline branching is usually cleaner. Use early split only when the two rotations have almost nothing in common.

### 10d. isActionAvailable() — When to Use and When Not To

`Faceroll.isActionAvailable("actionname")` checks whether the action's keybind slot has something on the action bar. This is your "do I even have this button?" check.

**USE it when:**
- The ability comes from a talent the spec might not have yet while leveling
- The macro uses `@Spell@` gating and might not have been created
- The ability is a later-level spell that won't be on the bar at low levels
- You're not already checking `s_` for this ability

**DON'T use it when:**
- You're already checking `s_spellname` — if `s_` returns false, the spell is either on cooldown or unavailable. The `s_` check is strictly more informative than `isActionAvailable`.
- The spell is a baseline ability every character of this class has by level 10
- The ability can only proc from a talent that defines the spec (e.g., if you're in the Shadow Priest spec file and checking Mind Blast, you definitely have Mind Blast)
- The ability is your filler spell — if the filler isn't available, something is very wrong

**The rule of thumb:** `isActionAvailable` = "is this button on my bar?" / `s_` = "is this button ready to press right now?" If you're checking `s_`, you don't also need `isActionAvailable`. If you're NOT tracking the spell with `s_` in the overlay but still want to conditionally use it, that's when `isActionAvailable` shines.

### 10e. Group Awareness

`state.group` is true when in a party or raid. Use it to adjust behavior:

**Don't self-heal in groups** (the healer handles it):

```lua
if not state.combat and not state.group and state.hp < 0.6 then
    return "healself"
end
```

**Skip maintenance that's wasteful solo:**

Some dots or debuffs are only worth applying in groups (long fights). Solo, mobs die too fast for the DoT to tick fully. Use `state.group` to gate these:

```lua
elseif state.group and not state.d_faeriefire then
    return "faeriefire"
```

**Solo pulling:**

Some specs want to pull with a ranged ability when solo but not in groups:

```lua
if not state.combat and not state.group and state.s_handofreckoning then
    return "handofreckoning"    -- solo pull with taunt
end
```

---

## 11. Researching a Spec's Priority List

When implementing a spec you're not deeply familiar with, research the WotLK rotation.

### Where to Search

Use web searches with these queries:
- `"wotlk classic [spec name] [class] pve rotation priority"` — e.g., "wotlk classic retribution paladin pve rotation priority"
- `"wotlk classic [spec] [class] dps guide"` — for DPS specs
- `"wotlk classic [spec] [class] tank guide rotation"` — for tank specs

Best sources:
- **Icy Veins** (icy-veins.com) — structured guides with explicit priority lists
- **Warcraft Tavern** (warcrafttavern.com) — detailed PvE rotation breakdowns
- **Wowhead** (wowhead.com) — community guides with comments

### What to Extract

From each guide, identify:

1. **Self-buffs to maintain** — things that should always be active (seals, auras, shields, weapon enchants). These go in the preamble.
2. **ST priority list** — the numbered or described priority for single-target damage. This becomes your `if/elseif` chain.
3. **AOE priority list** — often just 1-2 abilities (Blizzard, Fan of Knives, Consecration). This becomes your `aoe` branch.
4. **Resource thresholds** — when to spend combo points, when to dump rage, mana management breakpoints.
5. **Proc reactions** — abilities that light up when a proc occurs (Missile Barrage → Arcane Missiles, Art of War → Exorcism). Track the proc as a `b_` buff.
6. **Cooldown usage** — offensive cooldowns and when to pop them. Track with `s_`.
7. **DoTs to maintain** — which debuffs to keep on the target. Track with `d_`.
8. **Big cooldowns (1 minute+)** — abilities like Starfall, Force of Nature (Treants), Metamorphosis, etc. These are often things the player prefers to press manually at the right moment. **Ask the user** how they want each big cooldown handled: fully automatic in the priority list, manual (left out of calcAction entirely), or gated behind a `/fro` burst option toggle. Don't assume — different players have strong preferences here.
9. **Single-target party debuffs** — abilities like Faerie Fire, Sunder Armor, or Curse of Elements that benefit the group but cost a GCD. **Ask the user** whether they want these applied automatically in single-target, AOE, both, or neither. These are often worth maintaining in groups but wasteful solo on fast-dying mobs.
10. **Out-of-combat self-healing** — if the spec has healing spells, **ask the user** whether they want automatic self-healing outside of combat when solo. If yes, offer a choice: a deadzone'd cast-time heal (e.g., Healing Touch, Holy Light) for bigger heals, or an instant-cast HoT (e.g., Rejuvenation, Riptide) for convenience — if the spec offers both options.
11. **Utility macros** — look for common quality-of-life macros that guides recommend for the spec: form/stance swapping before casting, dismount macros, stealth-with-form-swap, travel form, etc. **Offer these to the user** — they're convenient but some players already have their own. These don't need actions or calcAction logic; they just live in `spec.macros` so `/frsetup` creates them. See "Utility Macros" in Section 4.

### Documenting Omissions

When a spell or ability is intentionally left out of the rotation (because the user chose manual control, or it was considered and rejected), **add a comment in the spec file** explaining the decision. This prevents future audits from flagging known omissions as bugs.

Place these comments in the most relevant section — near the macros if the spell has no macro, or near the calcAction logic where it would otherwise appear:

```lua
-- Starfall: manually controlled
-- Force of Nature (Treants): manually controlled
-- Faerie Fire: not automated
-- Self-healing: not automated
```

Write comments as terse, first-person statements of intent — as if the spec owner wrote them. Say `-- Starfall: manually controlled`, not `-- Starfall: user prefers manual control, not automated`. This applies to all comments in a spec file, not just omissions.

### What to Identify About Each Spell

For every spell in the rotation, determine:

- **Baseline or talented?** Baseline spells are available to all characters of the class. Talented spells need `isActionAvailable()` gating for leveling.
- **Instant or casted?** Casted spells may need a deadzone if you track their DoT/effect separately.
- **Melee or ranged?** Melee abilities might need `state.melee` checks.
- **On-next-hit?** Abilities like Maul and Heroic Strike need the `!` macro syntax.
- **Ground-targeted?** Blizzard, Rain of Fire, etc. need `.cast @@ID@@` macros.
- **Channeled?** If a spell is channeled, every other spell that can be recommended in the same mode needs a `[nochanneling]` guard in its macro to avoid interrupting the channel (see "Channel Guard" in Section 4). Exception: spells that *should* interrupt the channel (like a high-priority interrupt).
- **Close-range AOE in a ranged spec?** Some ranged specs have melee-range AOE abilities (e.g., Typhoon for Balance Druid, Blast Wave for Fire Mage). For primarily ranged specs, **ask the user** whether they want close-range AOE included in the rotation, and if so, whether it should be gated behind `state.melee`. Don't assume a ranged spec wants to run into melee for AOE.

### Translating Priority to Code

A guide might say: "Keep Slice and Dice up > Rupture at 5 CP > Eviscerate at 5 CP > Sinister Strike"

This translates directly:

```lua
if not state.b_slice and state.combopoints >= 2 then
    return "slice"
elseif not state.d_rupture and state.combopoints >= 5 then
    return "rupture"
elseif state.combopoints >= 5 then
    return "eviscerate"
else
    return "sinisterstrike"
end
```

Each priority becomes an `elseif`. The condition is: "should I do this right now?" If yes, return it. If no, fall through to the next priority.

### Leveling Gracefully

The guides describe max-level rotations, but your spec needs to work from level 10. This is handled automatically:

- Spells the character doesn't know yet won't be macro'd (`@Spell@` fails)
- Actions without macros/spells on the bar return `false` from `isActionAvailable`
- State tracked with `s_` returns `false` for spells not yet learned
- DoTs tracked with `d_` return `false` if the spell hasn't been applied

The max-level rotation naturally degrades at lower levels. A level 20 Rogue without Fan of Knives will simply skip that `elseif` and fall through to Sinister Strike. No level checks needed.

---

## 12. Annotated Example

Here is a complete teaching spec. It shows a hypothetical melee/caster hybrid to demonstrate all major patterns. Read the comments carefully — they explain every design decision.

```lua
-----------------------------------------------------------------------------------------
-- Nostalgia Retribution Paladin (3)
--
-- This is a teaching example showing all the key patterns.

if Faceroll == nil then
    _, Faceroll = ...
end

-- "RET" is the short name, "ffffaa" is a pale gold, "PALADIN-3" is tree 3
local spec = Faceroll.createSpec("RET", "ffffaa", "PALADIN-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)
--
-- These are created by /frsetup. The @spell@ gates ensure macros only exist
-- if the character knows the spell. This is how leveling "just works".

spec.macros = {

-- Basic auto-attack. Every ret paladin has this.
["Attack"] = [[
/startAttack
]],

-- Crusader Strike might not be trained yet at low levels.
-- @Crusader Strike@ gates it — no spell, no macro, no bar slot.
["CS"] = [[
#showtooltip
/cast @Crusader Strike@
/startAttack
]],

-- Consecration is ground-targeted on this server, needs .cast with spell ID
["Consecration"] = [[
#showtooltip Consecration
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Consecration@@
]],

}

-----------------------------------------------------------------------------------------
-- States
--
-- The overlay both configures the debug display AND auto-populates state.
-- Headers organize the overlay visually.

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_seal",          "Seal of Command" },       -- auto: is Seal of Command active?

    "- Procs -",
    { "b_artofwar",      "The Art of War" },        -- auto: did Art of War proc?

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },    -- auto: is Judgement off cooldown?
    { "s_cs",             "Crusader Strike" },       -- auto: is CS off cooldown?
    { "s_ds",             "Divine Storm" },          -- auto: is DS off cooldown?
    { "s_consecration",   "Consecration" },          -- auto: is Consecration off cooldown?
    { "s_exorcism",       "Exorcism" },              -- auto: is Exorcism off cooldown?
    { "s_hofreckoning",   "Hand of Reckoning" },     -- auto: is taunt off cooldown?
})
-- The deadzone on "healself" below auto-appends "- Deadzones -" / "z_healself" to this overlay.

-- (No spec.calcState needed — the heal deadzone is declared on the action itself.)

-----------------------------------------------------------------------------------------
-- Actions
--
-- Order = keybind slot order. Most-pressed first.
-- "attack" is the filler so it goes first.

spec.actions = {
    { "attack",         macro = "Attack" },         -- slot 1: auto attack
    { "cs",             macro = "CS" },             -- slot 2: Crusader Strike
    { "judgement",      spell = "Judgement of Light" },
    { "ds",             spell = "Divine Storm" },
    { "exorcism",       spell = "Exorcism" },
    { "consecration",   macro = "Consecration" },
    { "hofreckoning",   spell = "Hand of Reckoning" },
    { "healself",       spell = "Holy Light", deadzone = true },  -- exposes state.z_healself
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    ---------------------------------------------------------------
    -- Preamble: self-prep when not targeting an enemy
    ---------------------------------------------------------------

    -- Keep seal up at all times (before or during combat)
    if not state.b_seal and Faceroll.isActionAvailable("judgement") then
        -- We don't have a "seal" action — but this signals the player needs to seal up.
        -- In practice you'd add a seal action. This is just showing the pattern.
    end

    -- Self-heal when solo and low HP
    if not state.combat and not state.group and state.hp < 0.75 and not state.z_healself then
        return "healself"

    ---------------------------------------------------------------
    -- Priority list: combat decisions
    ---------------------------------------------------------------
    elseif state.targetingenemy then

        -- Solo pulling: use taunt to pull from range
        if not state.combat and not state.group and state.s_hofreckoning then
            return "hofreckoning"

        -- Art of War proc: instant Exorcism, use it before it fades
        -- No isActionAvailable needed — b_artofwar can only proc if we have the talent,
        -- and having the talent means we have Exorcism.
        elseif state.b_artofwar and state.s_exorcism then
            return "exorcism"

        -- Judgement on cooldown (high priority rotational ability)
        -- Using s_judgement means we know it exists AND is ready. No isActionAvailable needed.
        elseif state.s_judgement then
            return "judgement"

        -- Crusader Strike on cooldown
        -- Using s_cs. No isActionAvailable needed.
        elseif state.s_cs then
            return "cs"

        -- Divine Storm on cooldown (talented, but s_ handles availability)
        elseif state.s_ds then
            return "ds"

        -- Consecration in AOE mode
        -- isActionAvailable IS needed here because we're not tracking s_consecration
        -- for the decision (we always want to check it in AOE), and the .cast macro
        -- might not exist at low levels.
        elseif aoe and state.s_consecration then
            return "consecration"

        -- Filler: auto-attack
        else
            return "attack"
        end
    end
end
```

### What This Example Demonstrates

- **Preamble pattern**: self-heal when solo, before targeting check
- **isActionAvailable reasoning**: not needed when `s_` is already checked, needed for gated macros
- **Deadzone**: prevents heal spam
- **Group awareness**: no self-heal in groups, solo pulling
- **Proc reaction**: Art of War → Exorcism, high in the priority list
- **AOE branching**: inline `aoe and` check for Consecration
- **Macro patterns**: Attack, @-gated CS, @@-gated ground target Consecration
- **No level checks**: everything degrades gracefully via the @-gate → isActionAvailable chain

---

## 13. Existing Files to Study

Read these for real-world patterns at different complexity levels:

| File | What It Shows |
|------|--------------|
| `Nostalgia/SpecDruid2Feral.lua` | Most complex: options/radios, form switching, stealth openers, combo points, conditional state per form, bear vs cat branching |
| `Nostalgia/SpecMage1Arcane.lua` | Caster: deadzone on Arcane Missiles, debuff stack tracking, cast-bar reading, proc management (Missile Barrage), mana thresholds |
| `Nostalgia/SpecShaman2Enhancement.lua` | Hybrid melee/caster: totem tracking, self-heal deadzone, target HP percentage, interrupt priority |
| `Nostalgia/SpecRogue2Combat.lua` | Melee: stealth opener (Garrote), combo point spenders, buff maintenance (Slice and Dice), interrupt |
| `Nostalgia/SpecPaladin3Retribution.lua` | Simple melee: heal deadzone, solo pull with taunt, judgement priority, minimal overlay |
| `Nostalgia/SpecPriest3Shadow.lua` | Multi-DoT caster: enemy grid tracking, deadzone on VT, DoT priority chain |

---

## 14. Style Guide

### Formatting

- Use `-----------------------------------------------------------------------------------------` as section separators
- Section comment pattern: `-- Nostalgia [Spec] [Class] ([N])` for the header
- `-- Macros (/frm)`, `-- States`, `-- Actions` as section labels
- Consistent `elseif` indentation — each condition at the same level
- One blank line between the macro closing `]]` and the next macro's `["Name"]`
- Use `[target=player]` for self-cast macros, not `[@player]` — the `@` conflicts with Faceroll's `@Spell@` gate parsing

### Naming

- Overlay state names should be human-readable: `b_slice` not `b_snd`, `d_rupture` not `d_rup`
- Action names should be lowercase, no spaces: `"sinisterstrike"`, `"fanofknives"`, `"mindblast"`
- Macro names should be short but recognizable: `"SS"`, `"CS"`, `"Blast"`, `"Attack"`

### Comments

- Don't over-comment. The overlay + calcAction structure is self-documenting.
- Do comment non-obvious decisions: why you're checking `not aoe` somewhere, why a certain priority is ordered a certain way.
- Use `-- commented out code` sparingly for abilities you might want to enable later.

### Overlay Organization

Group related tracking together with headers:

```lua
spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_buff1", "Buff One" },
    { "b_buff2", "Buff Two" },

    "- Debuffs -",
    { "d_dot1", "DoT One" },

    "- Procs -",
    { "b_proc1", "Proc Name" },

    "- Spells -",
    { "s_spell1", "Spell One" },
    { "s_spell2", "Spell Two" },

    "- Custom -",
    "manualstate1",
    "manualstate2",
})
```

---

## 15. API Quick Reference

### Spec Lifecycle

| Function | Description |
|----------|-------------|
| `Faceroll.createSpec(name, color, specKey)` | Create a spec. Returns spec table. |
| `Faceroll.aliasSpec(spec, key)` | Register an alternate spec key (rarely needed now that spec 0 files exist). |
| `Faceroll.createOverlay(entries)` | Build overlay table from entries. |
| `Faceroll.enemyGridTrack(spec, spell, shortName, color)` | Register a DoT for multi-target tracking. |

### State Queries

| Function | Returns | Description |
|----------|---------|-------------|
| `Faceroll.isSpellAvailable(name)` | bool | Spell is usable and off cooldown (CD < 1.5s) |
| `Faceroll.isBuffActive(name)` | bool | Buff is active on player |
| `Faceroll.getBuff(name)` | table or nil | `{duration, stacks, expirationTime}` |
| `Faceroll.getBuffStacks(name)` | number | Stack count of buff |
| `Faceroll.getBuffRemaining(name)` | number | Seconds remaining on buff |
| `Faceroll.getDot(name)` | table or nil | `{duration, stacks, expirationTime}` on target |
| `Faceroll.getDotRemainingNorm(name)` | float | Normalized remaining (0.0-1.0), -1 if missing |
| `Faceroll.isDotActive(name)` | bool | DoT is on target |
| `Faceroll.getDotStacks(name)` | number | Stack count of DoT on target |
| `Faceroll.getDebuff(name)` | table or nil | `{duration, stacks, expirationTime}` debuff on player |
| `Faceroll.isActionAvailable(action)` | bool | Action's bar slot has something in it |
| `Faceroll.isTotemActive(name)` | bool | Totem with this substring is active |
| `Faceroll.isSpellQueued(name)` | bool | On-next-hit spell is queued |
| `Faceroll.hasManaForSpell(name)` | bool | Player has enough mana for spell |
| `Faceroll.getSpellCooldown(name)` | number | Seconds remaining on cooldown |
| `Faceroll.getSpellCharges(name)` | (cur, max) | Current and max charges |
| `Faceroll.inShapeshiftForm(name)` | bool | In named shapeshift form |

### Deadzone

Prefer the `deadzone = true` action property — see Section 6 ("Deadzones"). The low-level API below is only needed when you want to drive a deadzone manually from `calcState`.

| Function | Returns | Description |
|----------|---------|-------------|
| `Faceroll.deadzoneCreate(spell, castThreshold, duration)` | deadzone | Create a deadzone tracker |
| `Faceroll.deadzoneUpdate(deadzone)` | bool | Update and return if active |
| `Faceroll.deadzoneActive(deadzone)` | bool | Check if currently in deadzone |

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `Faceroll.MODE_ST` | 1 | Single-target mode |
| `Faceroll.MODE_AOE` | 2 | Area-of-effect mode |

### Slash Commands (Player Reference)

| Command | Description |
|---------|-------------|
| `/frsetup` | Full setup: create macros, place actions, rebuild keys |
| `/frm` | Create/update macros only |
| `/frb` | Place actions on bar only |
| `/fra` | Toggle Faceroll on/off |
| `/frd` | Cycle debug overlay (off → minimal → full) |
| `/fro name` | Toggle option |
| `/frr group` | Cycle radio group |
| `/frstop` | Temporarily deactivate (breaks stuck macro loops) |
| `/frk` | Dump keybinds |
