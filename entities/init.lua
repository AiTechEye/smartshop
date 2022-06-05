smartshop.entities = {
	element_dir = {
	    vector.new(0, 0, -1),
	    vector.new(-1, 0, 0),
	    vector.new(0, 0, 1),
	    vector.new(1, 0, 0),
	},
	entity_offset = vector.new(0.01, 6.5/16, 0.01),
}

smartshop.dofile("entities", "quad_upright_sprite")
smartshop.dofile("entities", "single_sprite")
smartshop.dofile("entities", "single_upright_sprite")
smartshop.dofile("entities", "single_wielditem")

minetest.register_lbm({
	name = "smartshop:load_shop",
	nodenames = {
        "smartshop:shop",
        "smartshop:shop_full",
        "smartshop:shop_empty",
        "smartshop:shop_used",
        "smartshop:shop_admin"
    },
    run_at_every_load = true,
	action = function(pos, node)
		local shop = smartshop.api.get_object(pos)
		shop:update_appearance()
	end,
})
