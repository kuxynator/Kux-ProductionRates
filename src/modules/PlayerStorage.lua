---@class PlayerStorage
---@field private _player LuaPlayer
---@field version uint
---@field instances ViewStorage[]
---@field SettingsView SettingsViewStorage
PlayerStorage = {
	---@type LuaPlayer
	_player = nil,
	version = 2,
	instances = {}
}

local PlayerStorage_MT={__index = PlayerStorage}

---Gets the root storage table for the given player.
---@param player LuaPlayer|uint|string
---@return PlayerStorage
 function PlayerStorage.get(player)
	assert(player~=nil, "Invalid Argument. 'player' must not be nil.")
	player =
		(type(player)=="table" and player.object_name=="LuaPlayer") and player or
		(type(player)=="number") and game.get_player(player) or
		(type(player)=="string") and game.get_player(player) or
		error("Property not exists and player not found. ")
	--trace("Storage.get "..serpent.line(player.name))
	---@cast player LuaPlayer
	if not global.mod.players then global.mod.players = {} end
    global.mod.players[player.name] = global.mod.players[player.name] or {}
	local playerStorage = global.mod.players[player.name]
	if(not getmetatable(playerStorage)) then -- metatables not stored in global
		--[[TRACE]]trace.append("  re-init PlayerStorage "..player.name)
		playerStorage._player = player
		setmetatable(playerStorage, PlayerStorage_MT)
	end

	-- migration => 2.2.0
	if(playerStorage.instances==nil or (playerStorage.instances_count or 0)<1) then
		--[[TRACE]]trace.append("  migrate single instance")
		playerStorage.instances={
			ViewStorage.new(player, 1)
		}
		playerStorage.instances_count = 1

		playerStorage.instances[1].gui_orientation = playerStorage.gui_orientation
		playerStorage.instances[1].column_count    = playerStorage.column_count or 2
		playerStorage.instances[1].slot_count      = playerStorage.slot_count
		playerStorage.instances[1].rate_precision  = playerStorage.rate_precision
		playerStorage.instances[1].display_mode    = playerStorage.display_mode
		playerStorage.instances[1].autohide_mode   = playerStorage.autohide_mode

		playerStorage.column_count = nil
		playerStorage.slot_count = nil
		playerStorage.gui_orientation = nil
		playerStorage.rate_precision = nil
		playerStorage.display_mode = nil
	end

	return playerStorage
end

---@param self PlayerStorage
---@return ViewStorage
function PlayerStorage:add_instance()
	self.instances_count = self.instances_count + 1
	local instance = ViewStorage.new(self._player, self.instances_count)
	self.instances[self.instances_count] = instance
	return instance
end

---@param self PlayerStorage
function PlayerStorage:remove_instance(instance)
	for i = instance+1, self.instances_count, 1 do
		local storage = Storage.get(self._player, i)
		storage.instance = i - 1
	end
	self.instances_count = self.instances_count - 1
	table.remove(self.instances, instance)
end
