-- petz has its own mechanism for "selling" petz; this allows transferring ownership of animals put in shops

local function transfer_ownership(petstack, new_owner_name)
	local meta = petstack:get_meta()
	local serialized_data = meta:get("staticdata")
	if not serialized_data then
		return
	end

	local data = minetest.deserialize(serialized_data)

	if not (data and data.memory) then
		return
	end

	data.memory.exchange_item_amount = nil
	data.memory.exchange_item_index = nil
	data.memory.for_sale = nil

	if (data.memory.owner or "") ~= "" then
		data.memory.owner = new_owner_name
		meta:set_string("staticdata", minetest.serialize(data))
	end
end

local function is_petz(itemstack)
	local name = itemstack:get_name()
	return name:match("^petz:.*_set$")
end

smartshop.api.register_transaction_transform(function(player, shop, i, shop_removed, player_removed)
	if is_petz(shop_removed) then
		transfer_ownership(shop_removed, player:get_player_name())
	end
	if is_petz(player_removed) then
		transfer_ownership(player_removed, shop:get_owner())
	end
	return shop_removed, player_removed
end)
