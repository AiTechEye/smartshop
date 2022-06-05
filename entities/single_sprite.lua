
local v_add = vector.add
local v_mul = vector.multiply

local add_entity = minetest.add_entity
local get_node = minetest.get_node
local pos_to_string = minetest.pos_to_string

local api = smartshop.api

local element_dir = smartshop.entities.element_dir
local entity_offset = smartshop.entities.entity_offset

local element_offset = {
    { vector.new(0.2, 0.2, -0.2), vector.new(-0.2, 0.2, -0.2),
      vector.new(0.2, -0.2, -0.2), vector.new(-0.2, -0.2, -0.2) },

    { vector.new(-0.2, 0.2, 0.2), vector.new(-0.2, 0.2, -0.2),
      vector.new(-0.2, -0.2, 0.2), vector.new(-0.2, -0.2, -0.2) },

    { vector.new(-0.2, 0.2, 0.2), vector.new(0.2, 0.2, 0.2),
      vector.new(-0.2, -0.2, 0.2), vector.new(0.2, -0.2, 0.2) },

    { vector.new(0.2, 0.2, -0.2), vector.new(0.2, 0.2, 0.2),
      vector.new(0.2, -0.2, -0.2), vector.new(0.2, -0.2, 0.2) },
}

minetest.register_entity("smartshop:single_sprite", {
	hp_max = 1,
	visual = "sprite",
	visual_size = {x = .40, y = .40},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	smartshop2 = true,
	static_save = false,
})

function smartshop.entities.add_single_sprite(shop, index)
	local shop_pos = shop.pos
	local param2 = get_node(shop_pos).param2
	local item_name = shop:get_give_stack(index):get_name()

	local dir = element_dir[param2 + 1]
    local base_pos = v_add(shop_pos, v_mul(dir, entity_offset))
    local offset = element_offset[param2 + 1][index]
	local entity_pos = v_add(base_pos, offset)

	local obj = add_entity(entity_pos, "smartshop:single_sprite")
	if not obj then
		smartshop.log("warning", "could not create single_sprite for %s @ %s", item_name, pos_to_string(shop_pos))
		return
	end

	obj:set_yaw(math.pi * (2 - (param2 / 2)))
	obj:set_properties({textures = {api.get_image(item_name)}})

	local entity = obj:get_luaentity()

	entity.pos = shop_pos
	entity.index = index
	entity.item = item_name

	return obj
end
