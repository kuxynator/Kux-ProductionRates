---@class Storage
Storage = {}

require "modules/ViewStorage"
require "modules/PlayerStorage"

---@class Storage.this
local this = {}

---Gets the root storage table for the given player.
---@param player LuaPlayer|uint|string
---@return PlayerStorage
function Storage.getRoot(player) return PlayerStorage.get(player) end

---Gets the storage table for the given view instance.
---@param player LuaPlayer
---@param instance uint
---@return ViewStorage
function Storage.get(player, instance) return ViewStorage.get(player, instance) end

Events.on_init(function ()
	global.mod = {}
	global.mod.players = {}

	for _, player in pairs(game.players) do
		
	end
end)

Events.on_configuration_changed(function ()
	global.mod = global.mod or {}
	global.mod.players = global.mod.players or {}

	for _, player in pairs(game.players) do
		
	end
end)

return Storage