local api = smartshop.api

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
smartshop.dofile("entities", "remove_legacy_entities")

local entities = smartshop.entities

function entities.add_entity(shop, type, index)
	if type == "single_upright_sprite" then
		entities.add_single_upright_sprite(shop, index)

	elseif type == "quad_upright_sprite" then
		entities.add_quad_upright_sprite(shop)

	elseif type == "single_sprite" then
		entities.add_single_sprite(shop, index)

	elseif type == "single_wielditem" then
		entities.add_single_wielditem(shop, index)
	end
end

local queue
if smartshop.has.node_entity_queue then
	queue = node_entity_queue.queue
end

minetest.register_lbm({
	name = "smartshop:load_shop",
	nodenames = "group:smartshop",
    run_at_every_load = true,
	action = function(pos, node)
		if queue then
			queue:push_back(function()
				local shop = api.get_object(pos)
				api.update_entities(shop)
			end)

		else
			local shop = api.get_object(pos)
			api.update_entities(shop)
		end
	end,
})
