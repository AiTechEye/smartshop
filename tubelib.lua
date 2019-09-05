if minetest.global_exists("tubelib") then
    local _TUBELIB_CALLBACKS = {
        on_pull_item = function(pos, side, player_name)
            local meta = minetest.get_meta(pos)
            if smartshop.get_owner(meta) ~= player_name then
                return nil
            end
            local inv = meta:get_inventory()
            for _, stack in pairs(inv:get_list("main")) do
                if not stack:is_empty() then
                    local rv = inv:remove_item("main", stack:get_name())
                    if smartshop.is_smartshop(pos) then
                        smartshop.update_shop_info(pos)
                        smartshop.update_shop_display(pos)
                        smartshop.update_shop_color(pos)
                    end
                    return rv
                end
            end
            return nil
        end,
        on_push_item = function(pos, side, item, player_name)
            local inv = minetest.get_meta(pos):get_inventory()
            if inv:room_for_item("main", item) then
                inv:add_item("main", item)
                if smartshop.is_smartshop(pos) then
                    smartshop.update_shop_info(pos)
                    smartshop.update_shop_display(pos)
                    smartshop.update_shop_color(pos)
                end
                return true
            end
            return false
        end,
        on_unpull_item = function(pos, side, item, player_name)
            local inv = minetest.get_meta(pos):get_inventory()
            if inv:room_for_item("main", item) then
                inv:add_item("main", item)
                if smartshop.is_smartshop(pos) then
                    smartshop.update_shop_info(pos)
                    smartshop.update_shop_display(pos)
                    smartshop.update_shop_color(pos)
                end
                return true
            end
            return false
        end,
    }

    tubelib.register_node("smartshop:shop", {}, _TUBELIB_CALLBACKS)
    tubelib.register_node("smartshop:shop_full", {}, _TUBELIB_CALLBACKS)
    tubelib.register_node("smartshop:shop_empty", {}, _TUBELIB_CALLBACKS)
    tubelib.register_node("smartshop:shop_used", {}, _TUBELIB_CALLBACKS)
    tubelib.register_node("smartshop:shop_admin", {}, _TUBELIB_CALLBACKS)
    tubelib.register_node("smartshop:wifistorage", {}, _TUBELIB_CALLBACKS)
end
