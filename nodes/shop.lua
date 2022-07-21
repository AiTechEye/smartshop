local S = smartshop.S
local table_copy = table.copy
local nodes = smartshop.nodes

smartshop.nodes.shop_node_names = {}

local smartshop_def = {
	description = S("Smartshop"),
	tiles = {"(smartshop_face.png^[colorize:#FFFFFF77)^smartshop_border.png"},
	use_texture_alpha = "opaque",
	sounds = smartshop.resources.sounds.shop_sounds,
	groups = {
		choppy = 2,
        oddly_breakable_by_hand = 1,
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.0, 0.5, 0.5, 0.5}
	},
	paramtype2 = "facedir",
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
	on_destruct = nodes.on_destruct,
	on_blast = function() end,  -- explosion-proof
}

local function register_shop_variant(name, overrides)
	local variant_def
	if overrides then
		variant_def = table_copy(smartshop_def)
		for key, value in pairs(overrides) do
			variant_def[key] = value
		end
		variant_def.drop = "smartshop:shop"
		variant_def.groups.not_in_creative_inventory = 1
	else
		variant_def = smartshop_def
	end

	minetest.register_node(name, variant_def)
	table.insert(smartshop.nodes.shop_node_names, name)
end

local make_variant_tiles = smartshop.nodes.make_variant_tiles

register_shop_variant("smartshop:shop")

register_shop_variant("smartshop:shop_full", {
	tiles = make_variant_tiles("#80008077")
})

register_shop_variant("smartshop:shop_empty", {
	tiles = make_variant_tiles("#FF000077")
})

register_shop_variant("smartshop:shop_used", {
	tiles = make_variant_tiles("#00FF0077")
})

register_shop_variant("smartshop:shop_admin", {
	tiles = make_variant_tiles("#00FFFF77")
})
