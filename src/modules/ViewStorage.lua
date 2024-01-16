-- require "PlayerStorage"
-- require "ProductionRatesFrame"

---@class ViewStorage
---@field _player LuaPlayer
---@field instance uint current instance index
---@field gui_orientation string mod.defines.gui.display_mode
---@field column_count uint
---@field slot_count uint
---@field rate_precision integer
---@field display_mode string
---@field autohide_mode string
---@field pages string[][]
---@field page uint current page index
---@field location GuiLocation frame location
---@field visible boolean frame visibility
---@field elements KuxCoreLib.GuiElementCache.Instance
ViewStorage = {
	---@diagnostic disable-next-line: assign-type-mismatch
	_player         = nil,
	instance        = 1,
	gui_orientation = mod.defaults.gui_orientation,
	column_count    = 2,
	slot_count      = mod.defaults.slot_count,
	rate_precision  = mod.defaults.rate_precision,
	display_mode	= mod.defaults.display_mode,
	autohide_mode	= mod.defaults.autohide_mode,
	--elements = ,
}

local ViewStorage_MT={__index = ViewStorage}

local GuiElementCache = KuxCoreLib.GuiElementCache

---Gets the storage table for the given player.
---@param player LuaPlayer
---@param instance uint
---@return ViewStorage
function ViewStorage.get(player, instance)
	assert(player~=nil, "Invalid Argument. 'player' must not be nil.")
	assert(type(instance)=="number", "Invalid Argument. 'instance' must be a positive integer.")
	local playerStorage = PlayerStorage.get(player)
	local viewStorage = playerStorage.instances[instance]

	if(not getmetatable(viewStorage)) then -- metatables not stored in global
		--[[TRACE]]--trace.append("  re-init PlayerStorage "..player.name)
		viewStorage._player = player
		setmetatable(viewStorage, ViewStorage_MT)
	end

    return viewStorage
end

---@param player LuaPlayer
---@param instance uint
---@return ViewStorage
ViewStorage.new = function (player, instance)
	local self = setmetatable(
		{
			_player = player,
			instance = instance,
			gui_orientation = mod.defaults.gui_orientation,
			colum_count = mod.defaults.colum_count,
			slot_count = mod.defaults.slot_count,
			rate_precision = mod.defaults.rate_precision,
			-- elements = nil -- initialized later
	}, ViewStorage_MT)
	return self
end

function ViewStorage:toggle_display_mode()
	if not self.display_mode then self.display_mode = mod.defaults.display_mode end
	if self.display_mode == mod.defines.gui.display_mode.totals then
		self.display_mode = mod.defines.gui.display_mode.diff
	elseif self.display_mode == mod.defines.gui.display_mode.diff then
		self.display_mode = mod.defines.gui.display_mode.totals
	end
	ProductionRatesFrame.api.refresh_gui(self._player, self.instance) --TODO: remove
end

function ViewStorage:toggle_autohide_mode()
	if not self.autohide_mode then self.autohide_mode = mod.defaults.autohide_mode end
	if self.autohide_mode == mod.defines.gui.autohide_mode.on then
		self.autohide_mode = mod.defines.gui.autohide_mode.off
	elseif self.autohide_mode == mod.defines.gui.autohide_mode.off then
		self.autohide_mode = mod.defines.gui.autohide_mode.on
	end
	ProductionRatesFrame.api.refresh_gui(self._player, self.instance) --TODO: remove
end

function ViewStorage:toggle_rate_precision()
    local current_rate_precision = self.rate_precision
    local new_rate_precision = current_rate_precision

    if current_rate_precision == defines.flow_precision_index.five_seconds then
        new_rate_precision = defines.flow_precision_index.one_minute
    elseif current_rate_precision == defines.flow_precision_index.one_minute then
        new_rate_precision = defines.flow_precision_index.ten_minutes
    elseif current_rate_precision == defines.flow_precision_index.ten_minutes then
        new_rate_precision = defines.flow_precision_index.one_hour
    elseif current_rate_precision == defines.flow_precision_index.one_hour then
        new_rate_precision = defines.flow_precision_index.ten_hours
    elseif current_rate_precision == defines.flow_precision_index.ten_hours then
        new_rate_precision = defines.flow_precision_index.five_seconds
    end
    self.rate_precision = new_rate_precision
    ProductionRatesFrame.set_precision_string(self._player,self.instance, new_rate_precision) --TODO: remove
end

function ViewStorage:update_page()
	local slots = ProductionRatesFrame.api.get_slots(self._player, self.instance)
	if(not self.pages or #self.pages==0 ) then
		self.pages = self.pages or {}
		table.insert(self.pages, slots)
		self.page=1
	else
		self.pages[self.page] = slots
	end
end

function ViewStorage:increment_slots()
	local current_slot_count = self.slot_count
	local new_slot_count = current_slot_count + self.column_count
	if new_slot_count > mod.defines.max_slot_count then return end
	self.slot_count = new_slot_count
end

function ViewStorage:decrement_slots()
	local current_slot_count = self.slot_count
	local new_slot_count = current_slot_count - self.column_count
	if new_slot_count < mod.defines.min_slot_count then return end
	self.slot_count = new_slot_count
end