local inv_count = smartshop.tests.inv_count

local function init_old_shop(pos, player)
    minetest.remove_node(pos)
    minetest.swap_node(pos, {name = "smartshop:shop"})

    local player_name = player:get_player_name()
    local meta = minetest.get_meta(pos)
    meta:set_int("state", 0)
    meta:set_string("owner", player_name)
    meta:set_string("infotext", "Shop by: " .. player_name)
    meta:set_int("type", 1)
    meta:set_int("sellall", 1)

    local inv = meta:get_inventory()
    inv:set_size("main", 32)
    inv:set_size("give1", 1)
    inv:set_size("pay1", 1)
    inv:set_size("give2", 1)
    inv:set_size("pay2", 1)
    inv:set_size("give3", 1)
    inv:set_size("pay3", 1)
    inv:set_size("give4", 1)
    inv:set_size("pay4", 1)
end

smartshop.tests.register_test({
    name = "simulate refunds in empty shop",
    func = function(player, state)
        local shop_at = state.shop_at
        init_old_shop(shop_at, player)
        local meta = minetest.get_meta(shop_at)
        local inv = meta:get_inventory()
        inv:set_stack("give1", 1, "smartshop:node")
        inv:set_stack("give2", 1, "smartshop:node 5")
        inv:set_stack("give3", 1, "smartshop:node 99")
        inv:set_stack("give4", 1, "smartshop:tool")
        inv:set_stack("pay1", 1, "smartshop:gold")
        inv:set_stack("pay2", 1, "smartshop:gold 5")
        inv:set_stack("pay3", 1, "smartshop:gold 99")
        inv:set_stack("pay4", 1, "smartshop:gold 20")

        smartshop.compat.convert_legacy_shop(shop_at)
        smartshop.compat.do_refund(shop_at)

        assert(inv_count(inv, "main", "smartshop:node") == 105, "refunded correct amount")
        assert(inv_count(inv, "main", "smartshop:tool") == 1, "refunded correct amount")
        assert(inv_count(inv, "main", "smartshop:gold") == 125, "refunded correct amount")
    end,
})

smartshop.tests.register_test({
    name = "simulate refunds in full shop",
    func = function(player, state)
        local shop_at = state.shop_at

        minetest.remove_node(shop_at)
        minetest.swap_node(shop_at, {name = "smartshop:shop"})

        init_old_shop(shop_at, player)
        local meta = minetest.get_meta(shop_at)
        local inv = meta:get_inventory()

        inv:set_stack("give1", 1, "smartshop:node")
        inv:set_stack("give2", 1, "smartshop:node 5")
        inv:set_stack("give3", 1, "smartshop:node 99")
        inv:set_stack("give4", 1, "smartshop:tool")
        inv:set_stack("pay1", 1, "smartshop:gold")
        inv:set_stack("pay2", 1, "smartshop:gold 5")
        inv:set_stack("pay3", 1, "smartshop:gold 99")
        inv:set_stack("pay4", 1, "smartshop:gold 20")

        for i = 1, 32 do
            inv:set_stack("main", i, "smartshop:tool")
        end

        smartshop.compat.do_refund(shop_at)

        assert(inv_count(inv, "main", "smartshop:tool") == 32, "no refund cuz shop full")

        for i = 1, 32 do
            inv:set_stack("main", i, ItemStack())
        end

        smartshop.compat.do_refund(shop_at)

        assert(inv_count(inv, "main", "smartshop:node") == 105, "refunded correct amount")
        assert(inv_count(inv, "main", "smartshop:tool") == 1, "refunded correct amount")
        assert(inv_count(inv, "main", "smartshop:gold") == 125, "refunded correct amount")

        for i = 1, 32 do
            inv:set_stack("main", i, ItemStack())
        end

        smartshop.compat.do_refund(shop_at)

        assert(inv_count(inv, "main", "smartshop:node") == 0, "already refunded")
        assert(inv_count(inv, "main", "smartshop:tool") == 0, "already refunded")
        assert(inv_count(inv, "main", "smartshop:gold") == 0, "already refunded")
    end,
})
