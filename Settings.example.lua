if Faceroll == nil then
    _, Faceroll = ...
end

-----------------------------------------------------------------------------------------
-- Activated specs. Put your most commonly used specs closer to the top.

-- Ascension Main Specs
Faceroll.enableSpec("LOTA")

-- Ascension Alt Specs
Faceroll.enableSpec("CBF")
Faceroll.enableSpec("CS")
Faceroll.enableSpec("CI")
Faceroll.enableSpec("DA")
Faceroll.enableSpec("TS")
-- Faceroll.enableSpec("LS")
-- Faceroll.enableSpec("TV")
-- Faceroll.enableSpec("DG")
-- Faceroll.enableSpec("MOS")
-- Faceroll.enableSpec("DR")
-- Faceroll.enableSpec("EVO")
-- Faceroll.enableSpec("ATW")
-- Faceroll.enableSpec("CBF")
-- Faceroll.enableSpec("APB")
-- Faceroll.enableSpec("LUC")

-- Classic
Faceroll.enableSpec("CM")
Faceroll.enableSpec("CW")
Faceroll.enableSpec("CP")
Faceroll.enableSpec("CR")

-- Retail
-- Faceroll.enableSpec("VDH")
-- Faceroll.enableSpec("HDH")
-- Faceroll.enableSpec("DW")
-- Faceroll.enableSpec("PAL")
-- Faceroll.enableSpec("FDK")
-- Faceroll.enableSpec("AM")
-- Faceroll.enableSpec("BM")
-- Faceroll.enableSpec("MM")
-- Faceroll.enableSpec("SV")
-- Faceroll.enableSpec("RET")
-- Faceroll.enableSpec("PP")
-- Faceroll.enableSpec("HP")
-- Faceroll.enableSpec("SUB")
-- Faceroll.enableSpec("CD")
-- Faceroll.enableSpec("DB")
-- Faceroll.enableSpec("OWL")

-----------------------------------------------------------------------------------------
-- Keybinds

-- The default action bars for a spec's listed actions (in order). Unless an
-- explicit keybind is set for a named action (see below), they will be bound to
-- the order provided below, and printed when ActMain runs (wabits console or
-- hammerspoon console).
Faceroll.keys[1] = "7"
Faceroll.keys[2] = "8"
Faceroll.keys[3] = "9"
Faceroll.keys[4] = "0"
Faceroll.keys[5] = "-"
Faceroll.keys[6] = "="
Faceroll.keys[7] = "f7"
Faceroll.keys[8] = "f8"
Faceroll.keys[9] = "f9"
Faceroll.keys[10] = "f10"
Faceroll.keys[11] = "f11"
Faceroll.keys[12] = "f12"
Faceroll.keys[13] = "pad7"
Faceroll.keys[14] = "pad8"
Faceroll.keys[15] = "pad4"
Faceroll.keys[16] = "pad5"

-- Any individual action's keybind can be set/overridden like this:
-- Faceroll.keys["bestialwrath"] = "1"

-- The keybind which toggles whether Faceroll is active or not
Faceroll.keys["toggle1"] = "f5"
Faceroll.keys["toggle2"] = "gamepad_middle_button"

-- Keybinds to enable ST or AOE mode
Faceroll.keys["mode_st1"] = "q"
Faceroll.keys["mode_st2"] = "gamepad_left"
Faceroll.keys["mode_aoe1"] = "e"
Faceroll.keys["mode_aoe2"] = "gamepad_right"
Faceroll.keys["reset1"] = "gamepad_down"

-- Keybinds which map to the macros "/fr ST" and "/fr AE"
Faceroll.keys["signal_st"] = "pad9"
Faceroll.keys["signal_aoe"] = "pad6"

-- Keybinds which map to the macros "/fron" and "/froff"
Faceroll.keys["fron"] = "["
Faceroll.keys["froff"] = "]"

-----------------------------------------------------------------------------------------
-- Element positioning

-- The little "OFF" / "SV" spec text
Faceroll.enabledFrameAnchor = "BOTTOMLEFT"
Faceroll.enabledFrameX = 470
Faceroll.enabledFrameY = 70
Faceroll.enabledFrameFontSize = 18

-- The list of active options
Faceroll.optionsFrameAnchor = "BOTTOMLEFT"
Faceroll.optionsFrameX = 470
Faceroll.optionsFrameY = 100
Faceroll.optionsFrameFontSize = 10
Faceroll.optionsFrameColor = "ffffaa"
Faceroll.optionsFrameShowAll = false

-- The text in the center of the screen saying "FR AE", etc
Faceroll.activeFrameAnchor = "CENTER"
Faceroll.activeFrameX = 0
Faceroll.activeFrameY = -185
Faceroll.activeFrameFontSize = 24
Faceroll.activeFrameColor = "F5FF9D"

-- The bits panel. This must correspond to the run_wabits* script's crop you use.
-- If you use this, debug the wabits side with the PNG invocation of the script to
-- verify you're capturing the whole panel and nothing but the panel.
Faceroll.bitsPanelAnchor = "TOPRIGHT"
Faceroll.bitsPanelX = -165
Faceroll.bitsPanelY = -5

-----------------------------------------------------------------------------------------
-- Enable debug output / dashboards

Faceroll.debug = Faceroll.DEBUG_OFF
