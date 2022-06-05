-- large

local v_add = vector.add
local v_mul = vector.multiply

local add_entity = minetest.add_entity
local get_node = minetest.get_node
local pos_to_string = minetest.pos_to_string

local api = smartshop.api

local element_dir = smartshop.entities.element_dir
local entity_offset = smartshop.entities.entity_offset

local element_offset = {
    vector.new(0, 0, -0.1),
    vector.new(-0.1, 0, 0),
    vector.new(0, 0, 0.1),
    vector.new(0.1, 0, 0),
}

minetest.register_entity("smartshop:single_upright_sprite", {
	hp_max = 1,
	visual = "upright_sprite",
	visual_size = {x = 1.0, y = 1.0},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	smartshop2 = true,
	static_save = false,
})

function smartshop.entities.add_single_upright_sprite(shop, index)
	local shop_pos = shop.pos
	local param2 = get_node(shop_pos).param2

	local item = shop:get_give_stack(index):get_name()
	--local items = {}

	local dir = element_dir[param2 + 1]
    local base_pos = v_add(shop_pos, v_mul(dir, entity_offset))
    local offset = element_offset[param2 + 1]
	local entity_pos = v_add(base_pos, offset)

	local obj = add_entity(entity_pos, "smartshop:single_upright_sprite")
	if not obj then
		smartshop.log("warning", "could not create single_upright_sprite @ %s", pos_to_string(shop_pos))
		return
	end

	local texture = api.get_image(item)
	smartshop.log("info", "single texture = %s", texture)

	obj:set_yaw(math.pi * (2 - (param2 / 2)))
	obj:set_properties({textures = {texture}})

	local entity = obj:get_luaentity()

	entity.pos = shop_pos
	entity.item = item

	return obj
end
