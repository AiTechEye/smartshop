-- luacheck: globals tubelib

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

for _, variant in ipairs(smartshop.nodes.shop_node_names) do
	tubelib.register_node(variant, {}, tubelib_callbacks)
end

for _, variant in ipairs(smartshop.nodes.storage_node_names) do
	tubelib.register_node(variant, {}, tubelib_callbacks)
end
