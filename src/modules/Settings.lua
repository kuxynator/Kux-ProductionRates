---@class PlayerSettings
---@field enabled boolean

---@class Settings
_G.Settings = {}

---@class Settings.this
local this = {
	players = {},
}

if(ModInfo.current_stage=="settings") then goto settings end
if(ModInfo.current_stage:match("^data")) then goto data end
if(ModInfo.current_stage=="control") then goto control end
goto exit
---------------------------------------------------------------------------------------------------
::settings::
---------------------------------------------------------------------------------------------------
trace("Settings: settings stage")
data:extend({
	{
		name=mod.prefix.."enable",
		type="bool-setting",
		setting_type="runtime-per-user",
		default_value=true,
	},
})

 goto exit
---------------------------------------------------------------------------------------------------
::data::
---------------------------------------------------------------------------------------------------
trace("Settings: data stage")
goto exit
---------------------------------------------------------------------------------------------------
::control::
---------------------------------------------------------------------------------------------------
trace("Settings: control stage")
Events = KuxCoreLib.Events

---@param player LuaPlayer
---@return PlayerSettings
local function get(self, player)
	player =
		(type(player)=="table" and player.object_name=="LuaPlayer") and player or
		(type(player)=="number") and game.get_player(player) or
		(type(player)=="string") and game.get_player(player) or
		error("Property not exists and player not found. ")
	--trace("Settings.get "..player.name)
	this.players[player.index] = this.players[player.index] or this.load_player_settings(player)
	return this.players[player.index]
end

---@param player LuaPlayer|uint
---@return PlayerSettings
function this.load_player_settings(player)
	if(type(player)=="number") then player = game.get_player(player) or error("Player not found") end
	this.players[player.index] = this.players[player.index] or {}
	local player_settings = this.players[player.index]
	player_settings.enabled = player.mod_settings[mod.prefix.."enable"].value
	return player_settings
end

function Settings.load()
	trace("Settings.load")
	if(game) then
		trace.append("Settings.load players")
		for name, player in pairs(game.players) do
			this.load_player_settings(player)
		end
	end
end

Events.on_init(Settings.load)
Events.on_load(Settings.load)
Events.on_event(defines.events.on_runtime_mod_setting_changed, Settings.load)
Events.on_event(defines.events.on_player_created, function (e)
	this.load_player_settings(e.player_index)
end)
setmetatable(Settings, {__index = get})
if(true) then return Settings end
goto exit
---------------------------------------------------------------------------------------------------
::exit::