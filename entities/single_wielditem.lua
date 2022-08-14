
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
    { vector.new(0.2, 0.2, -0.1), vector.new(-0.2, 0.2, -0.1),
      vector.new(0.2, -0.2, -0.1), vector.new(-0.2, -0.2, -0.1) },

    { vector.new(-0.1, 0.2, 0.2), vector.new(-0.1, 0.2, -0.2),
      vector.new(-0.1, -0.2, 0.2), vector.new(-0.1, -0.2, -0.2) },

    { vector.new(-0.2, 0.2, 0.1), vector.new(0.2, 0.2, 0.1),
      vector.new(-0.2, -0.2, 0.1), vector.new(0.2, -0.2, 0.1) },

    { vector.new(0.1, 0.2, -0.2), vector.new(0.1, 0.2, 0.2),
      vector.new(0.1, -0.2, -0.2), vector.new(0.1, -0.2, 0.2) },
}

-- for nodebox and mesh drawtypes without an inventory image, which can't be drawn well otherwise
minetest.register_entity("smartshop:single_wielditem", {
	visual = "wielditem",
	visual_size = {x = .20, y = .20},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	smartshop2 = true,

	get_staticdata = function(self)
		minetest.log("action", "get_staticdata wielditem")
		return minetest.serialize({
			self.pos, self.index, self.item,
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		minetest.log("action", "on_activate wielditem")
		local pos, index, item = unpack(deserialize(staticdata))
		local obj = self.object

		if not (pos and index and item and api.is_shop(pos)) then
			obj:remove()
			return
		end

		self.pos = pos
		self.index = index

		for _, other_obj in ipairs(api.get_entities(pos)) do
			local entity = other_obj:get_luaentity()
			if (not entity.index) or (entity.index == index and obj ~= other_obj) then
				obj:remove()
				return
			end
		end

		self.item = item

		obj:set_properties({wield_item = item})
	end,
})

local function get_entity_pos(shop_pos, param2, index)
	local dir = element_dir[param2 + 1]
    local base_pos = v_add(shop_pos, v_mul(dir, entity_offset))
    local offset = element_offset[param2 + 1][index]

	return v_add(base_pos, offset)
end

function smartshop.entities.add_single_wielditem(shop, index)
	local shop_pos = shop.pos
	local param2 = get_node(shop_pos).param2
	local item = shop:get_give_stack(index):get_name()

	local entity_pos = get_entity_pos(shop_pos, param2, index)
	local staticdata = serialize({shop_pos, index, item})
	local obj = add_entity(entity_pos, "smartshop:single_wielditem", staticdata)

	if not obj then
		smartshop.log("warning", "could not create single_wielditem for %s @ %s", item, pos_to_string(shop_pos))
		return
	end

	obj:set_yaw(math.pi * (2 - (param2 / 2)))

	return obj
end
