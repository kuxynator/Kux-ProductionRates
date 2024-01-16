---@class common_utils
local this = {}

function this.toSignal(name)
	if(type(name) == "string") then
		local signal = {
			type =
				game.item_prototypes[name] and "item" or
				game.fluid_prototypes[name] and "fluid" or
				"virtual",
			name = name
		}
		return signal
	end
	return name
end

function this.format_number(originalNumber)
    local isNumberNegative = originalNumber < 0
    local number = originalNumber
    if isNumberNegative then number = number * -1 end
	if number < 1000 then return tostring(originalNumber) end

    local num = number
    local suffix = ""

    if num > 1000.0 then num = num / 1000.0 suffix = "K" end
    if num > 1000.0 then num = num / 1000.0 suffix = "M" end
    if num > 1000.0 then num = num / 1000.0 suffix = "G" end
    if num > 1000.0 then num = num / 1000.0 suffix = "T" end
	if num > 1000.0 then num = num / 1000.0 suffix = "E" end

    if isNumberNegative then num = num * -1 end

    return string.format("%.2f", num) .. suffix
end

function this.get_item_flow_rate(player, item, precision)
	if(type(item) == "table") then -- SignalID
		if(item.type == "item") then
			local rate_output = player.force.item_production_statistics.get_flow_count{
				name = item.name,
				input = true,
				precision_index = precision,
				count = true
			}
			local rate_input = player.force.item_production_statistics.get_flow_count{
				name = item.name,
				input = false,
				precision_index = precision,
				count = true
			}
			return {
				input = rate_input,
				output = rate_output,
			}
		elseif(item.type == "fluid") then
			local rate_output = player.force.fluid_production_statistics.get_flow_count{
				name = item.name,
				input = true,
				precision_index = precision,
				count = true
			}
			local rate_input = player.force.fluid_production_statistics.get_flow_count{
				name = item.name,
				input = false,
				precision_index = precision,
				count = true
			}
			return {
				input = rate_input,
				output = rate_output,
			}
		else
			return {input = 0, output = 0}
		end
	end

    local rate_output = player.force.item_production_statistics.get_flow_count{
        name = item,
        input = true,
        precision_index = precision,
        count = true
    }
    local rate_input = player.force.item_production_statistics.get_flow_count{
        name = item,
        input = false,
        precision_index = precision,
        count = true
    }
    return {
        input = rate_input,
        output = rate_output,
    }
end

return this