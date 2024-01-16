
---@class SettingsView
---@field ProductionRatesFrame ProductionRatesFrame
local SettingsView = {}

SettingsView.ProductionRatesFrame=nil

local GuiBuilder      = KuxCoreLib.GuiBuilder or error("Invalid state")
local Colors          = KuxCoreLib.Colors or error("Invalid state")
local GuiHelper       = KuxCoreLib.GuiHelper or error("Invalid state")
local GuiElementCache = KuxCoreLib.GuiElementCache or error("Invalid state")

local _name = mod.prefix.."SettingsView"
local _anchor = "screen"

---@class SettingsViewStorage
---@field player LuaPlayer
---@field instance uint? The instance id of the ProductionRatesFrame this view is for.
---@field elements KuxCoreLib.GuiElementCache.Instance A dicionary of all elements of this view.
local SettingsViewStorage = {}

---@param player LuaPlayer
---@return LuaGuiElement?
local function getRoot(player)
	return player.gui[_anchor][_name] --or error("Root element not found: ")
end

---@param player LuaPlayer
---@return SettingsViewStorage
function SettingsViewStorage.get(player)
	local playerStorage = PlayerStorage.get(player)
	playerStorage.SettingsView = playerStorage.SettingsView or {}
	local storage = playerStorage.SettingsView
	storage.player = player
	-- prep_elements(storage) -- do this later. gui is not yet created possibly
	return storage
end

local this = {}

--- Initializes the elements cache for the given player if neccessary.
---@param storage SettingsViewStorage
local function prep_elements(storage)
	-- initialize elements cache
	if(not storage.elements or (storage.elements.__count or 0)==0) then
		local root = getRoot(storage.player) or error("Root element not found")
		storage.elements = GuiElementCache.new(root)
	end
end

local function getElement(root,...)
	assert(root, "Invalid Argument. 'root' must not be nil.")
	local element
	if(root.object_name=="LuaGuiElement") then element = root
	elseif(root.object_name=="LuaPlayer") then element = getRoot(root) or error("Root element not found.")
	else error("Invalid Argument. 'root' must be a LuaGuiElement or LuaPlayer.")
	end
	local path=""
	for _,name in pairs({...}) do
		path = path.."/"..name
		element = element[_name.."_"..name] or element[name] or error("Element not found: "..root.name..path)
		if not element then return nil end
		if(type(element)~="table" or element.object_name~="LuaGuiElement") then error("Fragment is not a LuaGuiElement. path: "..root.name..path) end
	end
	return element
end

---
---@param player LuaPlayer
---@param elementName string
---@return LuaGuiElement?
local function getElementByName(player, elementName)
	--[[TRACE]]trace("SettingsView.getElementByName "..player.name.." "..elementName)
	local storage = SettingsViewStorage.get(player)
	prep_elements(storage)
	local element = GuiElementCache.getElementByName(player, elementName, storage.elements, _name.."_")
	return element
end

local ElementBuilder = GuiBuilder.ElementBuilder or error("Invalid state")
local eb = ElementBuilder or error("Invalid state")
local frame = eb.frame
local flow = eb.flow
local table = eb.table
local textfield = eb.textfield
local button = eb.button
local dropdown = eb.dropdown

local function loc(key)
	if(type(key)=="table") then return key end
	return {mod.loc..key}
end

local propertyLabel = function(args)
	args[2] = {"",loc(args[1]),": "}
	args[1] = nil
	return eb.label(args)
end

---@param player LuaPlayer
function this.initialize(player)
	assert(player, "Invalid Argument. 'player' must not be nil.")
	trace("SettingsView.initialize "..player.name)
	local playerStorage = PlayerStorage.get(player)
	local settingsViewStorage = SettingsViewStorage.get(player)
	this.destroy(player)
	local anchor = player.gui[_anchor] ---@type LuaGuiElement
	local pfx = _name.."_"
	--TODO: localized captions
	local root = ElementBuilder.createView(anchor,
		frame{_name, "Settings", direction="vertical", {
			flow{"inner",nil,direction="vertical",{
				table{"content_table", column_count=2,{
					--propertyLabel{"Caption"},
					--textfield{pfx.."caption", width=120},
					propertyLabel{"Auto-Hide"},
					dropdown{pfx.."autohide_mode", "", text="", items={loc("off"), loc("on")}, selected_index=1},
					propertyLabel{"Columns"},
					flow{"column_count_flow", direction="horizontal",{
						textfield{pfx.."column_count", "", text="", numeric=true, allow_decimal=false, allow_negative=false, style={width=30}},
						button{pfx.."increment_column_count", "+", style = "frame_action_button", font_color=Colors.white},
						button{pfx.."decrement_column_count", "-", style = "frame_action_button", font_color=Colors.white}
					}},
					propertyLabel{"Rows"},
					flow{"row_count_flow", direction="horizontal",{
						textfield{pfx.."row_count", "", text="", numeric=true, allow_decimal=false, allow_negative=false, style={width=30}},
						button{pfx.."increment_row_count", "+", style = "frame_action_button", font_color=Colors.white},
						button{pfx.."decrement_row_count", "-", style = "frame_action_button", font_color=Colors.white}
					}},
					-- label{nil, "Orientation: "},
					-- dropdown{_name.."_orientation", "", text="", items={"horizontal", "vertical"}, selected_index=2},
					propertyLabel{"Instance"},
					flow{"instance_flow", direction="horizontal",{
						button{pfx.."create_instance_button", loc("Create"), width=60, padding={0,0,0,0}, style="green_button", tooltip=""},
						button{pfx.."delete_instance_button", loc("Delete"), width=60, padding={0,3,0,3}, style="red_button", tooltip=""}
					}},
					table {}
				}},
				flow{direction="horizontal", margin={10,0,0,0},{
					button{pfx.."cancel-button", loc("Cancel"), style="back_button", tooltip=""},
					button{pfx.."apply-button", loc("Apply"), style="confirm_button", tooltip=""}
				}}
			}}
		}}
	)
	root.visible = false
	playerStorage.SettingsView.elements = GuiElementCache.new(root)
	trace.exit("<"..root.type.." name=\""..root.name.."\"/>")
	return root
end

---Hides the view for the given player.
---@param player LuaPlayer
function this.hide(player)
	--[[TRACE]]trace("SettingsView.hide "..player.name)
	local root = getRoot(player)
	if root == nil then return end
	root.visible = false
	local view_storage = SettingsViewStorage.get(player)
	view_storage.instance = nil
	player.opened = nil
	trace.append("  location: "..serpent.line(root.location).." visible: "..tostring(root.visible))
end

---Destroys the view for the given player(s).
---@param player LuaPlayer|LuaPlayer[]
function this.destroy(player)
	if(player.object_name == "LuaPlayer") then
		local root = getRoot(player)
		if root ~= nil then root.destroy() end
		local settingsViewStorage = SettingsViewStorage.get(player)
		settingsViewStorage.elements = {} --TODO: use elements:clear()
		settingsViewStorage.instance = nil
	else
		for _,p in pairs(player) do this.destroy(p) end
	end
end

---@param player LuaPlayer
---@param instance uint
function this.show(player, instance)
	--[[TRACE]]trace("SettingsView.show "..player.name.." "..instance)
	-- local root = getRoot(player)
	-- if root == nil then root = this.initialize(player) end
	local root = this.initialize(player) --TODO: remove in final version
	trace.append("  root: "..trace.block(root))

	root.visible = true
	local view_storage = SettingsViewStorage.get(player)
	view_storage.instance = instance
	local storage = Storage.get(player, instance)
	getElement(root,"inner", "content_table", "column_count_flow", "column_count").text = tostring(storage.column_count)
	getElement(root,"inner", "content_table", "row_count_flow", "row_count").text = tostring(storage.slot_count / storage.column_count)
	getElement(root,"inner", "content_table", "autohide_mode").selected_index = storage.autohide_mode == "on" and 2 or 1
	root.location = ProductionRatesFrame.api.get_ui_frame(player,instance).location
	root.bring_to_front()
	player.opened = root
end

local function increment_textfield(textfield, increment, min, max)
	local value = tonumber(textfield.text)
	if(value == nil) then value = 1 end
	value = value + (increment or 1)
	if(min ~= nil and value < min) then value = min end
	if(max ~= nil and value > max) then value = max end
	textfield.text = tostring(value)
end

---@param e SettingsView.GuiClickEventData
local function on_increment_column_count_clicked(e)
	-- local elmt = getElement(getRoot(e.player),"inner", "content_table", "column_count_flow", "column_count") or error("Element not found")
	local elmt = getElementByName(e.player, "column_count") or error("Element not found")
	increment_textfield(elmt, 1, 1, 50)
end

---@param e SettingsView.GuiClickEventData
local function on_decrement_column_count_clicked(e)
	-- local elmt = getElement(getRoot(e.player),"inner", "content_table", "column_count_flow", "column_count") or error("Element not found")
	local elmt = getElementByName(e.player, "column_count") or error("Element not found")
	increment_textfield(elmt, -1, 1, 50)
end

---@param e SettingsView.GuiClickEventData
local function on_increment_row_count_clicked(e)
	local elmt = getElement(getRoot(e.player),"inner", "content_table", "row_count_flow", "row_count") or error("Element not found")
	increment_textfield(elmt, 1, 1, 50)
end

---@param e SettingsView.GuiClickEventData
local function on_decrement_row_count_clicked(e)
	local elmt = getElement(getRoot(e.player),"inner", "content_table", "row_count_flow", "row_count") or error("Element not found")
	increment_textfield(elmt, -1, 1, 50)
end

---@param e SettingsView.GuiClickEventData
local function on_delete_instance_clicked(e)
	if(e.instance==1) then e.player.print("This instance cannot be deleted!"); return end
	this.destroy(e.player)
	ProductionRatesFrame.api.delete_instance(e.player, e.instance)
end

---@param e SettingsView.GuiClickEventData
local function on_create_instance_clicked(e)
	ProductionRatesFrame.api.create_instance(e.player)
end

---@param e SettingsView.GuiClickEventData
local function on_apply_clicked(e)
	--[[TRACE]]trace("SettingsView.on_apply_clicked "..e.player.name.." "..e.instance)
	-- local min_speed = tonumber(root.inner.content_table.min_speed.text)
	-- if min_speed ~= nil then
	-- 	Storage.get(player, instance).min_speed = min_speed
	-- end
	local storage = ViewStorage.get(e.player, e.instance)
	local root = getRoot(e.player)
	storage.column_count = tonumber(getElement(root,"inner", "content_table", "column_count_flow", "column_count").text) or 2
	local row_count = tonumber(getElement(root,"inner", "content_table", "row_count_flow", "row_count").text) or 1
	storage.slot_count = storage.column_count * row_count
	local autohide_mode = { mod.defines.gui.autohide_mode.off, mod.defines.gui.autohide_mode.on}
	storage.autohide_mode = autohide_mode[getElementByName(e.player, "autohide_mode").selected_index]
	this.hide(e.player)
	ProductionRatesFrame.api.refresh_gui(e.player, e.instance)
	--[[TRACE]]trace.append("ViewStorage ("..e.instance.."): "..serpent.block(storage))
end

local function on_cancel_clicked(e)
	--[[TRACE]]trace("SettingsView.on_cancel_clicked "..e.player.name.." "..e.instance)
	local player = game.players[e.player_index]
 	this.hide(player)
end

---@class SettingsView.GuiClickEventData : EventData.on_gui_click
---@field player LuaPlayer
---@field instance uint

---@param e EventData.on_gui_click
---@return SettingsView.GuiClickEventData
local function new_GuiClickEventData(e)
	---@cast e SettingsView.GuiClickEventData
	e.player = game.get_player(e.player_index) or error("Invalid state")
	local view_storage = SettingsViewStorage.get(e.player)
	e.instance = view_storage.instance
	return e
end

local function on_gui_click(e)
	local prep = new_GuiClickEventData
	local pfx = _name.."_"
	if(not e.element or not e.element.valid) then return end
	if     e.element.name == pfx.."apply-button" then on_apply_clicked(prep(e))
	elseif e.element.name == pfx.."cancel-button" then on_cancel_clicked(prep(e))
	elseif e.element.name == pfx.."create_instance_button" then on_create_instance_clicked(prep(e))
	elseif e.element.name == pfx.."delete_instance_button" then on_delete_instance_clicked(prep(e))
	elseif e.element.name == pfx.."increment_column_count" then on_increment_column_count_clicked(prep(e))
	elseif e.element.name == pfx.."decrement_column_count" then on_decrement_column_count_clicked(prep(e))
	elseif e.element.name == pfx.."increment_row_count" then on_increment_row_count_clicked(prep(e))
	elseif e.element.name == pfx.."decrement_row_count" then on_decrement_row_count_clicked(prep(e))
	end
end

Events.on_event(defines.events.on_gui_click, on_gui_click)

Events.on_event(defines.events.on_gui_closed, function(e)
	if e.element and e.element.valid and e.element.name == _name then
		e = new_GuiClickEventData(e)
		if(e.instance==nil) then return end --already closed internally
		--[[TRACE]]trace("SettingsView.on_gui_closed "..e.player.name.." "..tostring(e.instance))
		on_apply_clicked(e)
	end
end)

SettingsView.initialize = this.initialize
SettingsView.destroy = this.destroy
SettingsView.show = this.show
SettingsView.hide = this.hide



return SettingsView
