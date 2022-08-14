-- large

local v_add = vector.add
local v_mul = vector.multiply

local add_entity = minetest.add_entity
local get_node = minetest.get_node
local pos_to_string = minetest.pos_to_string
local serialize = minetest.serialize
local deserialize = minetest.deserialize

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
	visual_size = {x = 0.9, y = 0.9},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	smartshop2 = true,

	get_staticdata = function(self)
		minetest.log("action", "get_staticdata single")
		return serialize({
			self.pos, self.item,
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		minetest.log("action", "on_activate single")
		local pos, item = unpack(deserialize(staticdata))
		local obj = self.object

		if not (pos and item and api.is_shop(pos)) then
			obj:remove()
			return
		end

		self.pos = pos

		for _, other_obj in ipairs(api.get_entities(pos)) do
			if obj ~= other_obj then
				obj:remove()
				return
			end
		end

		self.items = item

		obj:set_properties({textures = {api.get_image(item)}})
	end,
})

local function get_entity_pos(shop_pos, param2)
	local dir = element_dir[param2 + 1]
    local base_pos = v_add(shop_pos, v_mul(dir, entity_offset))
    local offset = element_offset[param2 + 1]

	return v_add(base_pos, offset)
end

function smartshop.entities.add_single_upright_sprite(shop, index)
	local shop_pos = shop.pos
	local param2 = get_node(shop_pos).param2
	local item = shop:get_give_stack(index):get_name()

	local entity_pos = get_entity_pos(shop_pos, param2)
	local staticdata = serialize({shop_pos, item})
	local obj = add_entity(entity_pos, "smartshop:single_upright_sprite", staticdata)

	if not obj then
		smartshop.log("warning", "could not create single_upright_sprite @ %s", pos_to_string(shop_pos))
		return
	end

	obj:set_yaw(math.pi * (2 - (param2 / 2)))

	return obj
end
