local function hideOrNot(player)
	local detail_trace = true
	local TRACE_result = detail_trace and trace.append or function() end
	--[[TRACE]]trace("hideOrNot "..player.name)
	if not Settings[player].enabled then --[[TRACE trace.exit("views disabled in settings")]] return end

	local playerStorage = PlayerStorage.get(player)
	for instance = 1, (playerStorage.instances_count or 0), 1 do
		local frame = player.gui.screen[mod.prefix.."ui_frame_outer_"..instance]
		if(not frame) then goto end_instance end
		local viewStorage = ViewStorage.get(player, instance)
		local autohide = viewStorage.autohide_mode == mod.defines.gui.autohide_mode.on
		if(not autohide) then frame.visible=true; TRACE_result(instance.." visible, no auto hide"); goto end_instance end
		if player.selected ~= nil then frame.visible = false; TRACE_result(instance.." invisible, player select something"); goto end_instance end
		local c = player.render_mode == defines.render_mode.game
		if not c then frame.visible = false; TRACE_result(instance.." invisible, chart view"); goto end_instance end
		frame.visible=true
		TRACE_result(instance.." invisible, chart view")
		::end_instance::
	end
end

local function on_selected_entity_changed(e)
	local player = game.players[e.player_index]
	hideOrNot(player)
end

local function on_player_render_mode_changed(e)
	local player = game.get_player(e.player_index) if not player then return end
	hideOrNot(player)
end

local player_render_mode = {}

Events.on_nth_tick(10, function ()
	for _, player in pairs(game.players) do
		local stored_mode = player_render_mode[player.index]
		local currend_mode = player.render_mode
		if(stored_mode == nil or stored_mode ~=currend_mode) then
			player_render_mode[player.index] = currend_mode
			on_player_render_mode_changed({player_index = player.index, render_mode = currend_mode})
		end
	end
end)

Events.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)



