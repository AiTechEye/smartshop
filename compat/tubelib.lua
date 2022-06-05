-- luacheck: globals tubelib

local table_copy = table.copy

local get_object = smartshop.api.get_object

--------------------

local tubelib_callbacks = {
    on_pull_item = function(pos, side, player_name)
	    local obj = get_object(pos)
        if not obj or not obj:is_owner(player_name) then
            return
        end
	    local inv = obj.inv

        for _, stack in pairs(inv:get_list("main")) do
            if not stack:is_empty() then
                local rv = inv:remove_item("main", stack:get_name())
                obj:update_appearance()
                return rv
            end
        end
    end,
    on_push_item = function(pos, side, item, player_name)
	    local obj = get_object(pos)
	    if not obj then return false end
	    local inv = obj.inv

        if inv:room_for_item("main", item) then
            inv:add_item("main", item)
            obj:update_appearance()
            return true
        end
        return false
    end,
    on_unpull_item = function(pos, side, item, player_name)
	    local obj = get_object(pos)
	    if not obj then return false end
	    local inv = obj.inv

        if inv:room_for_item("main", item) then
            inv:add_item("main", item)
            obj:update_appearance()
            return true
        end
        return false
    end,
}

--------------------

local function tubelib_override(itemstring)
    local def = minetest.registered_nodes[itemstring]
	local groups = table_copy(def.groups or {})
	groups.tubedevice = 1
	groups.tubedevice_receiver = 1

	minetest.override_item(itemstring, {
		groups = groups,
		tube = {
			insert_object = function(pos, node, stack, direction)
				local obj = get_object(pos)
				local inv = obj.inv
				local remainder = inv:add_item("main", stack)

			    obj:update_appearance()

			    return remainder
			end,
			can_insert = function(pos, node, stack, direction)
				local obj = get_object(pos)
				local inv = obj.inv
				return inv:room_for_item("main", stack)
			end,
			input_inventory = "main",
			connect_sides = {
				left = 1,
				right = 1,
				front = 1,
				back = 1,
				top = 1,
				bottom = 1}
		},
	})

end

--------------------

for _, variant in ipairs(smartshop.shop_node_names) do
	tubelib_override(variant)
	tubelib.register_node(variant, {}, tubelib_callbacks)
end

for _, variant in ipairs(smartshop.storage_node_names) do
	tubelib_override(variant)
	tubelib.register_node(variant, {}, tubelib_callbacks)
end
