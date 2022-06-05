local S = smartshop.S
local table_copy = table.copy
local nodes = smartshop.nodes
local api = smartshop.api

smartshop.storage_node_names = {}

local storage_def = {
	description = S("Smartshop external storage"),
	tiles = {"smartshop_face.png^[colorize:#ffffff77^smartshop_border.png"},
	use_texture_alpha = "opaque",
	sounds = smartshop.resources.sounds.storage_sounds,
	groups = {
		choppy = 2,
		oddly_breakable_by_hand = 1,
	},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 10,
	after_place_node = nodes.after_place_node,
	on_rightclick = nodes.on_rightclick,
	allow_metadata_inventory_put = nodes.allow_metadata_inventory_put,
	allow_metadata_inventory_take = nodes.allow_metadata_inventory_take,
	allow_metadata_inventory_move = nodes.allow_metadata_inventory_move,
	on_metadata_inventory_put = nodes.on_metadata_inventory_put,
	on_metadata_inventory_take = nodes.on_metadata_inventory_take,
	can_dig = nodes.can_dig,
	on_blast = function() end,  -- explosion-proof
	on_punch = function(pos, node, puncher, pointed_thing)
		local storage = api.get_object(pos)
		api.try_link_storage(storage, puncher)
	end,
}

local function register_variant(name, overrides)
	local variant_def
	if overrides then
		variant_def = table_copy(storage_def)
		for key, value in pairs(overrides) do
			variant_def[key] = value
		end
		variant_def.drop = "smartshop:storage"
		variant_def.groups.not_in_creative_inventory = 1
	else
		variant_def = storage_def
	end

	minetest.register_node(name, variant_def)
	table.insert(smartshop.storage_node_names, name)
end

local function make_variant_tiles(color)
	return {("(smartshop_face.png^[colorize:#FFFFFF77)^(smartshop_border.png^[colorize:%s)"):format(color)}
end

register_variant("smartshop:storage")
register_variant("smartshop:storage_full", {
	tiles = make_variant_tiles("#0000FF77")
})
register_variant("smartshop:storage_empty", {
	tiles = make_variant_tiles("#FF000077")
})
register_variant("smartshop:storage_used", {
	tiles = make_variant_tiles("#00FF0077")
})
