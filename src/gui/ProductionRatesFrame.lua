local DataGrid = KuxCoreLib.DataGrid

---@class ProductionRatesFrame
ProductionRatesFrame = {}

---@class this
this = {}
ProductionRatesFrame.api = this
ProductionRatesFrame.components = require("gui/Components") --[[@as ProductionRatesFrame.Components]]

local ElementBuilder = KuxCoreLib.GuiBuilder.ElementBuilder
local GuiElementCache = KuxCoreLib.GuiElementCache

local common_utils = require("util/common")
local SettingsView = require("gui/SettingsView") --[[@as SettingsView]]
SettingsView["ProductionRatesFrame"] = ProductionRatesFrame -- cross reference!
Storage["ProductionRatesFrame"] = ProductionRatesFrame	 -- cross reference!

local toSignal = common_utils.toSignal
local format_number = common_utils.format_number
local get_item_flow_rate = common_utils.get_item_flow_rate

local _columns = 2

--[[
	.screen
	["Kux-ProductionRates_ui_frame_outer_1"]
	["Kux-ProductionRates_ui_frame_inner"]
	["Kux-ProductionRates_ui_frame_inner_flow"]
	["Kux-ProductionRates_ui_table_inner"]
	["Kux-ProductionRates_slot_rate_container_outer_1"]
	["Kux-ProductionRates_slot_rate_container_1"]
	]]

local function getElement(root,...)
	local element =
		root.__object_name=="LuaGuiElement" and root or
		this.get_slot_container(root[1], root[2]) or
		error("Invalid Argument. 'root' must be a LuaGuiElement or a table with player and instance.")
	local path=""
	for _,name in pairs({...}) do
		path = path.."/"..name
		element = element[mod.prefix..name] or element[name] or error("Element not found: "..path)
		if not element then return nil end
	end
	return element
end


---@param player LuaPlayer
---@param instance uint
function this.add_gui_layout(player, instance)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	assert(type(instance)=="number", "Invalid Argument. 'instance' must be a positive integer.")
	trace("add_gui_layout "..player.name)

	--#region ElementBuilder
	local eb = ElementBuilder or error("Invalid state")
	local frame = eb.frame
	local flow = eb.flow
	local table = eb.table
	local label = eb.label
	local textfield = eb.textfield
	local button = eb.button
	--#endregion ElementBuilder

	local gui = this.get_gui_base(player)
	local orientation = Storage.get(player, instance).gui_orientation

	local outerFrame = gui[mod.prefix.."ui_frame_outer_"..instance]
	if(outerFrame) then outerFrame.destroy() end

	local viewStorage = ViewStorage.get(player, instance)

	local table_column_count = 2 * viewStorage.column_count
	if orientation == mod.defines.gui.orientation.horizontal then
		table_column_count = viewStorage.slot_count
	end

	local c = ProductionRatesFrame.components

	local view = ElementBuilder.createView(gui,
		frame{mod.prefix.."ui_frame_outer_"..instance,direction = "vertical", style = "quick_bar_window_frame", {
			c.titlebar{{
				c.controlBar(viewStorage)
			}},
			frame{mod.prefix.."ui_frame_inner",	style = "quick_bar_inner_panel",{
				flow{mod.prefix.."ui_frame_inner_flow",	direction = "vertical",{
					table{mod.prefix.."ui_table_inner",
						column_count = table_column_count,
						draw_vertical_lines = false,
						draw_horizontal_lines = true,
						draw_horizontal_line_after_headers = false,
						style = "slot_table",
						vertical_spacing = 3
					},
					--c.pageBar(viewStorage)
				}}
			}}
		}}
	)
	viewStorage.elements = GuiElementCache.new(view)

	-- frame = gui.add {
	-- 	type = "frame",
	-- 	name = mod.prefix.."ui_frame_outer_"..instance,
	-- 	direction = "vertical",
	-- 	style = "quick_bar_window_frame",
	-- }
	-- local titlebar = ProductionRatesFrame.components.titlebar(frame)
	-- ProductionRatesFrame.components.add_controlBar(titlebar, viewStorage)

	-- local frameInner = frame.add{
	-- 	type = "frame",
	-- 	name = mod.prefix.."ui_frame_inner",
	-- 	style = "quick_bar_inner_panel"
	-- }

	-- local flow = frameInner.add{
	-- 	type = "flow",
	-- 	name = mod.prefix.."ui_frame_inner_flow",
	-- 	direction = "vertical",
	-- }

	-- local table = flow.add{
	-- 	type = "table",
	-- 	name = mod.prefix.."ui_table_inner",
	-- 	column_count = table_column_count,
	-- 	draw_vertical_lines = false,
	-- 	draw_horizontal_lines = true,
	-- 	draw_horizontal_line_after_headers = false,
	-- 	style = "slot_table"
	-- }
	-- table.style.vertical_spacing = 3
	--ProductionRatesFrame.components.add_page_controlBar(flow, viewStorage)

	this.set_precision_string(player, instance, viewStorage.rate_precision)
end

---@param player LuaPlayer
---@param instance uint
---@param precision defines.flow_precision_index
function this.set_precision_string(player, instance, precision)
	assert(player, "Invalid Argument. 'player' must not be nil.")
    local container = this.get_ui_frame(player, instance) or error("Could not get ui frame")
    local precision_string = ""

    if precision == defines.flow_precision_index.five_seconds then
        precision_string = "5s"
    elseif precision == defines.flow_precision_index.one_minute then
        precision_string = "1m"
    elseif precision == defines.flow_precision_index.ten_minutes then
        precision_string = "10m"
    elseif precision == defines.flow_precision_index.one_hour then
        precision_string = "1h"
    elseif precision == defines.flow_precision_index.ten_hours then
        precision_string = "10h"
    end

    container[mod.prefix.."ui_titlebar"][mod.prefix.."ui_titlebar_flow"][mod.prefix.."ui_titlebar_precision"].caption = precision_string
end

ProductionRatesFrame.set_precision_string = this.set_precision_string -- called by Storage

---@param player LuaPlayer
---@param instance uint
function this.add_slots(player, instance)
	trace("add_slots "..player.name)

	local slot_count = Storage.get(player, instance).slot_count
	local container = this.get_slot_container(player, instance) or error("Slot container not found")
	container.clear()

	for i = 1, slot_count, 1 do
		ProductionRatesFrame.components.add_slot(container, mod.prefix.."slot_" .. i)
		local display_mode = Storage.get(player, instance).display_mode
		if display_mode == mod.defines.gui.display_mode.totals then
			ProductionRatesFrame.components.add_totalsLabels(container, i)
		elseif display_mode == mod.defines.gui.display_mode.diff then
			ProductionRatesFrame.components.add_differenceLabel(container, i)
		end
	end
end

---@param player LuaPlayer
---@param instance uint
function this.initialize_player_gui(player, instance)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	assert(type(instance)=="number", "Invalid Argument. 'instance' must be a positive integer.")
	trace("initialize_player_gui "..player.name)

	local isEnabled = Settings[player.index].enabled
	if not isEnabled then trace.append("  not enabled") return end
	this.add_gui_layout(player, instance)
	this.add_slots(player, instance)
end

---Get selected recipes from slot container
---@param player LuaPlayer
---@param slot_container LuaGuiElement
---@return string[]
function this.get_selected_recipes(player, slot_container)
	local instance = this.getInstanceId(slot_container) or 1
	local storage = ViewStorage.get(player, instance)
	local slot_count = storage.slot_count
	local selected_recipes = {}
	for i = 1, slot_count, 1
	do
		local value = nil
		if slot_container[mod.prefix.."slot_" .. i] ~= nil then
			value = slot_container[mod.prefix.."slot_" .. i].elem_value
			value = value and toSignal(value).name or nil
		end
		selected_recipes[i]=value
	end
	return selected_recipes
end

---Gets the content of all slots
---@param player LuaPlayer
---@param instance uint
---@return string[]?
function this.get_slots(player, instance, old_slots)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	local slot_count = Storage.get(player, instance).slot_count or 0
	local slots = {}
	local slot_container = this.get_slot_container(player, instance, old_slots)
	if not slot_container then return nil end
	for i = 1, slot_count, 1 do
		local slot = slot_container[mod.prefix.."slot_" .. i]
		table.insert(slots, (slot and slot.elem_value) and slot.elem_value.name or "")
	end
	return slots
end

---@param player LuaPlayer
---@param instance uint
---@param slots string[]
function this.set_slots(player, instance, slots)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	assert(slots, "Invalid Argument. 'slots' must not be nil.")
	local slot_count = Storage.get(player, instance).slot_count
	--assert(#slots == slot_count, "Invalid Argument. 'slots' must be a table with "..slot_count.." elements.")
	local slot_container = this.get_slot_container(player, instance) or error("Slot container not found")
	for i = 1, slot_count, 1 do
		if(i>#slots) then break end
		local slot = slot_container[mod.prefix.."slot_" .. i]
		slot.elem_value = slots[i]~="" and toSignal(slots[i]) or nil
	end
end

---Set selected recipes in slot container
---@param player LuaPlayer
---@param selected_recipes string[]
---@param slot_container LuaGuiElement
function this.set_selected_recipes(player, selected_recipes, slot_container)
	local instance = this.getInstanceId(slot_container) or 1
	local slot_count = Storage.get(player, instance).slot_count
	for i = 1, slot_count, 1
	do
		slot_container[mod.prefix.."slot_" .. i].elem_value = toSignal(selected_recipes[i])
	end
end

---@param player LuaPlayer
---@param instance uint
function this.destroy_gui(player, instance)
	instance = instance or 1
	trace("destroy_gui "..player.name .. " instance="..instance)

	local function destroi(ui_frame_outer)
		if player.gui.top[ui_frame_outer] ~= nil then
			player.gui.top[ui_frame_outer].destroy()
		end
		if player.gui.left[ui_frame_outer] ~= nil then
			player.gui.left[ui_frame_outer].destroy()
		end
		if player.gui.screen[ui_frame_outer] ~= nil then
			player.gui.screen[ui_frame_outer].destroy()
		end
		if player.gui.center[ui_frame_outer] ~= nil then
			player.gui.center[ui_frame_outer].destroy()
		end
		if player.gui.goal[ui_frame_outer] ~= nil then
			player.gui.goal[ui_frame_outer].destroy()
		end
	end

	local ui_frame_outer = mod.prefix.."ui_frame_outer"
	destroi(ui_frame_outer)
	destroi(ui_frame_outer.."_"..instance)

	trace.append("<<destroy_gui")
end


---@param player LuaPlayer
---@param instance uint
function this.refresh_gui(player, instance)
	instance = instance or 1
	trace("refresh_gui "..player.name.." instance="..instance)
	assert(Settings~=nil, "Settings not initialized")
	local isEnabled = Settings[player.index].enabled
	if not isEnabled then return end

	local storage = Storage.get(player, instance)
	if(not storage.pages or #storage.pages==0) then
		local empty = {}
		for i=1, storage.slot_count or 0, 1 do table.insert(empty, "") end
		storage.pages = {empty}
		storage.page = 1
	end

	local view = this.get_ui_frame(player, instance)
	if(view) then
	 	storage.location = view.location
		storage.pages[storage.page] = this.get_slots(player, instance)
	end

	this.destroy_gui(player, instance)
	this.initialize_player_gui(player, instance)

	view = this.get_ui_frame(player, instance) or error("ui frame not found")
	view.location = storage.location or {x = 50, y = 50}
	this.set_slots(player,instance, storage.pages[storage.page])
end

function this.get_gui_base(player)
    return player.gui.screen
end

--- Gets top level UI frame element
---@param player LuaPlayer
---@param instance uint
---@param old_single_instance boolean? if true, returns the old single instance container
---@return LuaGuiElement?
function this.get_ui_frame(player, instance, old_single_instance)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	assert(type(instance)=="number", "Invalid Argument. 'instance' must be a positive integer.")
	local gui = this.get_gui_base(player)
	if(old_single_instance) then
		return gui[mod.prefix.."ui_frame_outer"]
	else
		return gui[mod.prefix.."ui_frame_outer_"..instance]
	end
end

--- Get UI slot container element
---@param player LuaPlayer
---@param instance uint
---@param old_single_instance boolean? if true, returns the old single instance container
---@return LuaGuiElement?
function this.get_slot_container(player, instance, old_single_instance)
	local outer = this.get_ui_frame(player, instance, old_single_instance)
    if outer == nil then return nil end
    local inner = outer[mod.prefix.."ui_frame_inner"]
	if not inner then return nil end
    return inner[mod.prefix.."ui_frame_inner_flow"][mod.prefix.."ui_table_inner"] or nil
end

--- Get UI slot container element
---@param player LuaPlayer
---@param instance uint
---@param index number
---@return LuaGuiElement?
function this.get_slot_label_container(player, instance, index)
    local slot_container = this.get_slot_container(player, instance)
    if not slot_container then return nil end
    local slot_label_container_outer = slot_container[mod.prefix.."slot_rate_container_outer_" .. index]
    if not slot_label_container_outer then return nil end
    if not slot_label_container_outer[mod.prefix.."slot_rate_container_" .. index] then return nil end
    return slot_label_container_outer[mod.prefix.."slot_rate_container_" .. index]
end

function this.is_supported_element(element)
	return element.name:match(mod.prefix_pattern) ~= nil
end

function this.is_ui_frame_outer(element)
	return element.name:match(mod.prefix_pattern.."ui_frame_outer_(%d+)") ~= nil
end

function this.is_slot_table_switch(element)
	return element.name == mod.prefix.."ui_slot_table_switch"
end

function this.is_orientation_switch(element)
	return element.name == mod.prefix.."ui_orientation_switch"
end

function this.is_inc_slots_button(element)
	return element.name == mod.prefix.."ui_inc_slots_button"
end

function this.is_dec_slots_button(element)
	return element.name == mod.prefix.."ui_dec_slots_button"
end

function this.is_display_mode_toggle_button(element)
	return element.name == mod.prefix.."display_mode_toggle_button"
end

function this.is_toggle_precision_button(element)
	return element.name == mod.prefix.."ui_toggle_precision_button"
end

function this.is_slot_rate_container_or_child(element)
	if(element.name:match(mod.prefix_pattern.."slot_rate_container_outer_%d+")) then return true end
	if(element.name:match(mod.prefix_pattern.."slot_rate_container_%d+")) then return true end
	if(element.name:match(mod.prefix_pattern.."slot_rate_output_%d+")) then return true end
	if(element.name:match(mod.prefix_pattern.."slot_rate_input_%d+")) then return true end
	if(element.name:match(mod.prefix_pattern.."slot_rate_difference_%d+")) then return true end
	return false
end

---@param arg EventData.on_gui_click|LuaGuiElement
---@return number?
function this.getInstanceId(arg)
	assert(type(arg)=="table", "Invalid Argument. 'arg' must not be "..type(arg)..".")
	local element =
		arg["object_name"]=="LuaGuiElement" and arg or  -- LuaGuiElement
		arg.element or									-- EventData.on_gui_click
		error("Invalid Argument. 'element' not specified")
	---@cast element LuaGuiElement
	while element do
		local match = element.name:match(mod.prefix_pattern.."ui_frame_outer_(%d+)")
		if(match) then return tonumber(match) end
		element = element.parent
	end
	return nil
end

-- #region Event-Handlers -------------------------------------------------------------------------

---@class ProductionsRatesFrame.GuiClickEventData : EventData.on_gui_click
---@field player LuaPlayer
---@field instance uint

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_slot_table_switch_clicked(e)
	local slot_container = this.get_slot_container(e.player, e.instance) or error("Slot container not found")
	slot_container.visible = slot_container and not slot_container.visible
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_orientation_switch_clicked(e)
	local viewStorage = ViewStorage.get(e.player, e.instance)
	local current_orientation = viewStorage.gui_orientation
	viewStorage.gui_orientation =
		current_orientation == mod.defines.gui.orientation.horizontal and mod.defines.gui.orientation.vertical or
		mod.defines.gui.orientation.horizontal
	this.refresh_gui(e.player, e.instance)
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_inc_slots_button_clicked(e)
	ViewStorage.get(e.player,e.instance):increment_slots()
	this.refresh_gui(e.player, e.instance)
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_dec_slots_button_clicked(e)
	ViewStorage.get(e.player,e.instance):decrement_slots()
	this.refresh_gui(e.player, e.instance)
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_toggle_precision_button_clicked(e)
	Storage.get(e.player, e.instance):toggle_rate_precision()
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_toggle_display_mode_button_clicked(e)
	Storage.get(e.player, e.instance):toggle_display_mode()
	this.refresh_gui(e.player, e.instance)
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_toggle_autohide_button_clicked(e)
	Storage.get(e.player, e.instance):toggle_autohide_mode()
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function on_slot_rate_container_clicked(e)
	local modifiers_display = (e.shift and "Shift+" or "")..(e.control and "Ctrl+" or "")..(e.alt and "Alt+" or "")..
		(e.button == defines.mouse_button_type.left and "Left" or
		e.button == defines.mouse_button_type.right	and "Right" or
		e.button == defines.mouse_button_type.middle and "Middle" or
		"None/Unknown")
	--[[TRACE]]trace("on_slot_rate_container_clicked "..modifiers_display.." "..tostring(e.element.name))
	local element = e.element
	local index = tonumber(element.name:match("_(%d+)$"))
	if not index then trace.exit("index not found") return end
	if(modifiers_display=="Ctrl+Right") then
		local grid = DataGrid.fromArray(this.get_slots(e.player, e.instance),2)
		grid:removeRowByIndex(index)
		ViewStorage.get(e.player, e.instance):decrement_slots()
		this.set_slots(e.player, e.instance, grid:toArray(""))
		this.refresh_gui(e.player, e.instance)
	elseif(modifiers_display=="Ctrl+Left") then
		local grid = DataGrid.fromArray(this.get_slots(e.player, e.instance),2)
		grid:insertRowByIndex(index)
		ViewStorage.get(e.player, e.instance):increment_slots()
		this.refresh_gui(e.player, e.instance)
		this.set_slots(e.player, e.instance, grid:toArray(""))
	end
end

---@param e ProductionsRatesFrame.GuiClickEventData
local function ui_open_settings_button_clicked(e)
	SettingsView.show(e.player, e.instance)
end

---@param e EventData.on_gui_click
---@return ProductionsRatesFrame.GuiClickEventData
local function new_GuiClickEventData(e)
	---@cast e ProductionsRatesFrame.GuiClickEventData
	e.player   = game.get_player(e.player_index) or error("Player not found")
	e.instance = this.getInstanceId(e) or error("Instance not found")
	return e
end

---Event handler for gui click events
---@param e EventData.on_gui_click
local function on_gui_click(e)
	if(not e.element or not e.element.valid) then return end
	local modifiers_display = (e.shift and "Shift+" or "")..(e.control and "Ctrl+" or "")..(e.alt and "Alt+" or "")..
		(e.button == defines.mouse_button_type.left and "Left" or
		e.button == defines.mouse_button_type.right	and "Right" or
		e.button == defines.mouse_button_type.middle and "Middle" or
		"None/Unknown")
	trace("gui.on_gui_click "..modifiers_display.." "..tostring(e.element.name))
	local element = e.element
	if not this.is_supported_element(element) then return end
	if this.is_slot_table_switch(element) then on_slot_table_switch_clicked(new_GuiClickEventData(e))
	elseif this.is_orientation_switch(element) then on_orientation_switch_clicked(new_GuiClickEventData(e))
	elseif this.is_inc_slots_button(element) then on_inc_slots_button_clicked(new_GuiClickEventData(e))
	elseif this.is_dec_slots_button(element) then on_dec_slots_button_clicked(new_GuiClickEventData(e))
	elseif this.is_toggle_precision_button(element) then on_toggle_precision_button_clicked(new_GuiClickEventData(e))
	elseif this.is_display_mode_toggle_button(element) then on_toggle_display_mode_button_clicked(new_GuiClickEventData(e))
	elseif element.name == mod.prefix.."ui_toggle_autohide_button" then on_toggle_autohide_button_clicked(new_GuiClickEventData(e))
	elseif this.is_slot_rate_container_or_child(element) then on_slot_rate_container_clicked(new_GuiClickEventData(e))
	elseif element.name == mod.prefix.."ui_open_settings_button" then ui_open_settings_button_clicked(new_GuiClickEventData(e))
	end
end

Events.on_event(defines.events.on_gui_click, on_gui_click)
-- #endregion Event-Handlers

ProductionRatesFrame.get_slot_container = this.get_slot_container

---@param player LuaPlayer
---@param instance uint
---@param index uint
function this.update_production_totals(player, instance, index)
    local container = this.get_slot_container(player, instance)
    if not container then return end
    local slot_label_container = this.get_slot_label_container(player, instance, index)
    if not slot_label_container then return end
    local slot = container[mod.prefix.."slot_" .. index] or error("Slot not found")
    local item_name = slot.elem_value

    if not item_name then
        slot_label_container[mod.prefix.."slot_rate_output_" .. index].caption = ""
        slot_label_container[mod.prefix.."slot_rate_input_" .. index].caption = ""
        return
    end

    local precision = Storage.get(player, instance).rate_precision
    local output_rate = get_item_flow_rate(player, item_name, precision).output
    local input_rate = get_item_flow_rate(player, item_name, precision).input
    slot_label_container[mod.prefix.."slot_rate_output_" .. index].caption = "+"..format_number(output_rate)
    slot_label_container[mod.prefix.."slot_rate_input_" .. index].caption = "-"..format_number(input_rate)
end

---@param player LuaPlayer
---@param instance uint
function this.update_production_rates(player, instance)
    local slot_count = Storage.get(player, instance).slot_count
    local display_mode = Storage.get(player, instance).display_mode

    for i = 1, slot_count, 1 do
        if display_mode == mod.defines.gui.display_mode.totals then
            this.update_production_totals(player, instance, i)
        end

        if display_mode == mod.defines.gui.display_mode.diff then
            this.update_production_diffs(player, instance, i)
        end
    end
end

---@param player LuaPlayer
---@param instance uint
---@param index uint
function this.update_production_diffs(player, instance, index)
    local container = this.get_slot_container(player, instance)
	if not container then return end
    local slot_label_container = this.get_slot_label_container(player, instance, index)
    if not slot_label_container then return end
    local slot = container[mod.prefix.."slot_" .. index] or error("Slot not found")
    local item_name = slot.elem_value
    if not item_name then
        slot_label_container[mod.prefix.."slot_rate_difference_" .. index].caption = ""
        return
    end
    local precision = Storage.get(player, instance).rate_precision
    local output_rate = get_item_flow_rate(player, item_name, precision).output
    local input_rate = get_item_flow_rate(player, item_name, precision).input
    local difference = output_rate - input_rate
    local prefix = "+"
    local font_color = {r = 0.3, g = 1, b = 0.3}
    if difference < 0 then
        prefix = ""
        font_color = {r = 1, g = 0.3, b = 0.3}
    end
    slot_label_container[mod.prefix.."slot_rate_difference_" .. index].caption = prefix .. format_number(difference)
    slot_label_container[mod.prefix.."slot_rate_difference_" .. index].style.font_color = font_color
end

function this.create_instance(player)
	local root = Storage.getRoot(player)
	root:add_instance()
	this.refresh_gui(player, root.instances_count)
end


---@param player LuaPlayer
---@param instance uint
function this.delete_instance(player, instance)
	local rootStorage = Storage.getRoot(player)
	for i = instance+1, rootStorage.instances_count, 1 do
		local storage = Storage.get(player, i)
		storage:update_page()
		local frame = this.get_ui_frame(player, i) or error("ui frame not found")
		storage.location = frame.location
		storage.visible = frame.visible
	end
	for i = instance, rootStorage.instances_count, 1 do
		this.destroy_gui(player, i)
	end
	rootStorage:remove_instance(instance)
	this.refresh_gui(player, rootStorage.instances_count)
end

-- #region Game Events ----------------------------------------------------------------------------

local function on_player_joined_game(e)
	local player = game.get_player(e.player_index) or error("Player not found")
	-- ProductionRatesFrame.api.refresh_gui(player)
end


---@param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
	trace("on_runtime_mod_setting_changed")
	if not e.setting:match(mod.prefix_pattern) then return end
	if e.setting ~= mod.prefix.."enabled" then return end

	local player = game.get_player(e.player_index) or error("Player not found")
	local isEnabled = Settings[e.player_index].enabled
	local playerStorage = PlayerStorage.get(player)
	for instance = 1, playerStorage.instances_count, 1 do
		if not isEnabled then this.destroy_gui(player, instance)
		else ProductionRatesFrame.api.refresh_gui(player, instance)
		end
	end
end

local function on_loaded()
	for _, player in pairs(game.players) do
		if(not player.connected) then goto next end
		local playerStorage = PlayerStorage.get(player)
		if playerStorage.version ~= PlayerStorage.version then
			for instance = 1, playerStorage.instances_count, 1 do
				if(instance == 1 and playerStorage.instances_count == 1) then
					local viewStorage = ViewStorage.get(player, instance)
					if(viewStorage.pages==nil or #viewStorage.pages==0) then
						local slots = this.get_slots(player, 1, true) -- read ols slots from single instance
						if(slots) then
							viewStorage.pages = {slots}
							viewStorage.page = 1
						else
							local empty = {}
							for i=1, viewStorage.slot_count or 0, 1 do table.insert(empty, "") end
							viewStorage.pages = {empty}
							viewStorage.page = 1
						end
					end
					local ui_frame = this.get_ui_frame(player, 1, true)
					if(ui_frame) then
						viewStorage.location = ui_frame.location
						viewStorage.visible = ui_frame.visible
					end
				end
				this.refresh_gui(player, instance)
			end
			playerStorage.version = PlayerStorage.version
		end
		::next::
	end
end

local function on_player_created(e)
	local player = game.get_player(e.player_index) or error("Player not found")
	this.initialize_player_gui(player, 1)
	player.print({mod.loc.."print-init"})
end

local function on_tick_60(event)
	for _, player in pairs(game.players) do
		if not Settings[player].enabled then return end
		for instance = 1, Storage.getRoot(player).instances_count do
			this.update_production_rates(player, instance)
		end
	end
end

local function on_configuration_changed()

end

Events.on_init(function ()
	for _, player in pairs(game.players) do
		this.initialize_player_gui(player,1)
	end
end)


Events.on_loaded(on_loaded)
Events.on_event(defines.events.on_player_created, on_player_created)
Events.on_nth_tick(60, on_tick_60)
Events.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
Events.on_configuration_changed(on_configuration_changed)
--#endregion Game Events

commands.add_command("kpr-add-instance", nil, function (e)
	local player = game.get_player(e.player_index); if not player then return end
	this.create_instance(player)
end)

return ProductionRatesFrame