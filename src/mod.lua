KuxCoreLib = require("__Kux-CoreLib__/lib/init") --[[@as KuxCoreLib]]
ModInfo = KuxCoreLib.ModInfo

_G.trace = KuxCoreLib.Trace
trace.sign_color = trace.colors.blue
trace.text_color = trace.colors.lightblue
trace.background_color = trace.colors.gray_32

---@class mod
_G.mod = {
	name="Kux-ProductionRates",
	prefix="Kux-ProductionRates_",
	path="__Kux-ProductionRates__/",
	prefix_pattern="^Kux%-ProductionRates_",
	loc="Kux-ProductionRates.",

    version = 1,
    conf = {
        debug = false,
        log_prefix = "KPR",
        log_format = {
            comment = false,
            numformat = '%1.8g'
        },
    },
    defaults = {
        gui_orientation = "vertical",
        slot_count = 4,
		colum_count = 1,
        rate_precision = defines.flow_precision_index.ten_minutes,
        display_mode = "totals",
		autohide_mode = "off",
    },
    defines = {
        gui ={
            orientation = {
                vertical = "vertical",
                horizontal = "horizontal",
            },
            display_mode = {
                diff = "diff",
                totals = "totals",
            },
			autohide_mode = {
				off = "off",
				on = "on",
			}
        },
        max_slot_count = 32,
        min_slot_count = 1,
        number_format_suffix = {"K","M","B","T","q","Q","s","S","O","N","d","U","D"},
    },
}

Settings = require("modules/Settings")