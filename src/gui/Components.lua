local GuiBuilder = KuxCoreLib.GuiBuilder or error("Invalid state")
local Colors = KuxCoreLib.Colors or error("Invalid state")

---@class ProductionRatesFrame.Components
local Components = {}

--#region local ElementBuilder
local ElementBuilder = GuiBuilder.ElementBuilder or error("Invalid state")
local eb = ElementBuilder or error("Invalid state")
local frame = eb.frame
local flow = eb.flow
local table = eb.table
local label = eb.label
local textfield = eb.textfield
local button = eb.button
local dropdown = eb.dropdown
local emptywidget = eb.emptywidget
--#endregion local ElementBuilder

local function add_titlebar(container)
	local titlebar = ElementBuilder.create(container,
		flow{mod.prefix.."ui_titlebar",	direction = "vertical", drag_target = container, {
			flow{mod.prefix.."ui_titlebar_flow", direction = "horizontal", ignored_by_interaction = true, {
				label{mod.prefix.."ui_titlebar_label", {mod.loc.."titlebar"}, style = "caption_label", ignored_by_interaction = true},
				emptywidget{style={horizontally_stretchable=true}},
				label{mod.prefix.."ui_titlebar_precision","", ignored_by_interaction = true}
			}},
			emptywidget{style={width=20}}
		}}
	)
    return titlebar
end

local function table_merge(t1,t2)
	local t ={}
	for _,v in ipairs(t1) do _G.table.insert(t,v) end
	for _,v in ipairs(t2) do _G.table.insert(t,v) end
	return t
end

function Components.titlebar(args)
	local children = args~=nil and (args[1] or args.children)
	ElementBuilder.validateChildren(children)
	trace("Components.titlebar children: ", #children)

	return flow{mod.prefix.."ui_titlebar",	direction = "vertical", drag_target = "%parent%", {
		flow{mod.prefix.."ui_titlebar_flow", direction = "horizontal", ignored_by_interaction = true, {
			label{mod.prefix.."ui_titlebar_label", {mod.loc.."titlebar"}, style = "caption_label", ignored_by_interaction = true},
			emptywidget{style={horizontally_stretchable=true}},
			label{mod.prefix.."ui_titlebar_precision","", ignored_by_interaction = true}
		}},
		emptywidget{style={width=20}},
		children
	}}
end

function Components.add_actionButton(container, name, caption, tooltip)
    return ElementBuilder.create(container,
		button{name, caption, tooltip = tooltip, style = "frame_action_button", font_color=Colors.white}
	)
end

function Components.actionButton(name, caption, tooltip)
	return button{name, caption, tooltip = tooltip, style = "frame_action_button", font_color=Colors.white}
end

---@param container LuaGuiElement
---@param viewStorage ViewStorage
function Components.add_pageDisplay(container, viewStorage)
    return ElementBuilder.create(container,
		flow{{
			label{"page", viewStorage.page or 1},
			label{nil,"/"},
			label{"page_count", viewStorage.pages and #viewStorage.pages or 1}
		}}
	)
end

---@param container LuaGuiElement
---@param viewStorage ViewStorage
function Components.add_displayModeButton2(container, viewStorage)
	local displayMode = viewStorage.display_mode
	local name = mod.prefix.."display_mode_toggle_button"
	local displayModeButtonTooltip = {mod.loc.."display-mode-button-label-difference"}
    local displayModeButtonCaption = "◒"
    if displayMode == mod.defines.gui.display_mode.diff then
        displayModeButtonTooltip = {mod.loc.."display-mode-button-label-totals"}
        displayModeButtonCaption = "○"
    end
	return Components.add_actionButton(container, name, displayModeButtonCaption, displayModeButtonTooltip)
end

local function add_controlBar(container, viewStorage)
	assert(container, "Invalid Argument. 'container' must not be nil.")
	assert(viewStorage, "Invalid Argument. 'viewStorage' must not be nil.")

	local control_bar_container = container.add {
		type = "flow",
		direction = "vertical",
	}
	control_bar_container.style.bottom_margin = 8

	if(viewStorage.column_count>=2) then
		local control_bar = control_bar_container.add {
			type = "flow",
			direction = "horizontal",
		}
		-- ⚫ 🗜 👁️‍🗨️ ◉ ▽ ▲ ○◒
		Components.add_actionButton(control_bar, mod.prefix.."ui_slot_table_switch", "▲", {mod.loc.."visibility-toggle-tooltip"})
		--Components.actionButton(control_bar, mod.prefix.."ui_toggle_autohide_button", "◉", {mod.loc.."toggle-autohide-tooltip"})
		--Components.actionButton(control_bar, mod.prefix.."ui_inc_slots_button", "+", {mod.loc.."inc-slots-button"})
		--Components.actionButton(control_bar, mod.prefix.."ui_dec_slots_button", "-", {mod.loc.."dec-slots-button"})
		Components.add_actionButton(control_bar, mod.prefix.."ui_toggle_precision_button", "◴", {mod.loc.."toggle-time-period-tooltip"})
		Components.add_displayModeButton2(control_bar, viewStorage)
		Components.add_actionButton(control_bar, mod.prefix.."ui_open_settings_button", "⚙", {mod.loc.."open-settings-button-tooltip"})

		-- --local control_bar = control_bar_container.add {type = "flow",direction = "horizontal",}
		-- ElementBuilder.create(control_bar, emptywidget{horizontally_stretchable=true})
		-- Components.actionButton(control_bar, mod.prefix.."ui_prev_page_button", "◂", "Previous Page")
		-- Components.pageDisplay(control_bar, viewStorage)
		-- Components.actionButton(control_bar, mod.prefix.."ui_next_page_button", "▸", "Next Page")
	else
		local control_bar = control_bar_container.add {type = "flow",direction = "horizontal"}
		Components.add_actionButton(control_bar, mod.prefix.."ui_slot_table_switch", "▲", {mod.loc.."visibility-toggle-tooltip"})
		Components.add_actionButton(control_bar, mod.prefix.."ui_toggle_precision_button", "◴", {mod.loc.."toggle-time-period-tooltip"})
		Components.add_displayModeButton2(control_bar, viewStorage)
		Components.add_actionButton(control_bar, mod.prefix.."ui_open_settings_button", "⚙", {mod.loc.."open-settings-button-tooltip"})

		-- local control_bar = control_bar_container.add {type = "flow",direction = "horizontal"}
		-- --this.actionButton(control_bar, mod.prefix.."ui_toggle_autohide_button", "◉", {mod.loc.."toggle-autohide-tooltip"})
		-- Components.actionButton(control_bar, mod.prefix.."ui_inc_slots_button", "+", {mod.loc.."inc-slots-button"})
		-- Components.actionButton(control_bar, mod.prefix.."ui_dec_slots_button", "-", {mod.loc.."dec-slots-button"})
		-- Components.actionButton(control_bar, mod.prefix.."ui_prev_page_button", "◂", "Previous Page")
		-- Components.actionButton(control_bar, mod.prefix.."ui_next_page_button", "▸", "Next Page")
	end

	return control_bar_container
end

function Components.controlBar(viewStorage)
	assert(viewStorage, "Invalid Argument. 'viewStorage' must not be nil.")
	return function (container)
		return add_controlBar(container, viewStorage)
	end
end

local function add_pageBar(container, viewStorage)
	assert(container, "Invalid Argument. 'container' must not be nil.")

	local control_bar = ElementBuilder.create(container,
		flow{direction = "horizontal", top_margin = 8}
	)

	-- ElementBuilder.create(control_bar, emptywidget{horizontally_stretchable=true})
	Components.add_actionButton(control_bar, mod.prefix.."ui_prev_page_button", "◂", "Previous Page")
	Components.add_pageDisplay(control_bar, viewStorage)
	Components.add_actionButton(control_bar, mod.prefix.."ui_next_page_button", "▸", "Next Page")
	return control_bar
end

function Components.pageBar(viewStorage)
	assert(viewStorage, "Invalid Argument. 'viewStorage' must not be nil.")
	return function (container)
		return add_pageBar(container, viewStorage)
	end
end

function Components.add_slot(container, name)
    local slot = container.add {
        name = name,
        type = "choose-elem-button",
        elem_type = "signal",
        style = "quick_bar_slot_button",
    }

    slot.style.height = 42
    slot.style.width = 42
end

---Creates a container for a slot's labels
---@param container LuaGuiElement	The container to add the label container to
---@param index integer				The index of the slot
---@return LuaGuiElement	#		The label container
function Components.add_slotLabelContainer(container, index)
	local label_container_outer = ElementBuilder.create(container,
		flow{mod.prefix.."slot_rate_container_outer_" .. index, direction="horizontal", left_padding=0,
				right_padding=6, vertical_align="top", horizontal_align="right", minimal_width=73,{
			emptywidget{horizontally_stretchable=false},
			flow{mod.prefix.."slot_rate_container_" .. index, direction = "vertical"} --export--
		}}
	)

    return label_container_outer[mod.prefix.."slot_rate_container_" .. index]
end

function Components.add_totalsLabels(container, index)
    local label_container = Components.add_slotLabelContainer(container, index)

    local output = label_container.add {
        type = "label",
        name = mod.prefix.."slot_rate_output_" .. index,
        tooltip = {mod.loc.."output-caption"},
        style = "bold_label",
    }

    local input = label_container.add {
        type = "label",
        name = mod.prefix.."slot_rate_input_" .. index,
        tooltip = {mod.loc.."input-caption"},
        style = "bold_label",
    }

    output.style.font_color = {r = 0.3, g = 1, b = 0.3}
    input.style.font_color = {r = 1, g = 0.3, b = 0.3}
end

function Components.add_differenceLabel(container, index)
    local label_container = Components.add_slotLabelContainer(container, index)

    label_container.add {
        type = "label",
        name = mod.prefix.."slot_rate_difference_" .. index,
        tooltip = {mod.loc..'production-consumption-difference'},
        style = "bold_label",
    }
end

return Components
