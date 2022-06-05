local inv_count = smartshop.tests.inv_count
local put_in_shop = smartshop.tests.put_in_shop

table.insert(smartshop.tests.tests, {
    name = "test that currency changing works (accept small bills)",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))

        minetest.remove_node(shop_at)
        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )

        local shop = smartshop.api.get_object(shop_at)

        shop.inv:set_stack("pay1", 1, "smartshop:currency_1")
        shop.inv:set_stack("give1", 1, "smartshop:node")
        shop.inv:set_stack("pay2", 1, "smartshop:currency_10")
        shop.inv:set_stack("give2", 1, "smartshop:node 5")
        shop.inv:set_stack("pay3", 1, "smartshop:currency_50")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        for _ = 1, 2 do
            put_in_shop(shop, "smartshop:node 99", player)
        end
        for _ = 1, 5 do
            put_in_shop(shop, "smartshop:tool", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:currency_1 99"})

        shop:receive_fields(player, {buy1a = true})
        shop:receive_fields(player, {buy2a = true})
        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:currency_1") == 99 - (1+10+50), "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:node") == 6, "got correct # of nodes")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:currency_1") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:currency_10") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:currency_50") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:node") == (2 * 99 - 6), "correct amount were removed")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 4, "correct amount were removed")
    end
})


table.insert(smartshop.tests.tests, {
    name = "test that currency changing works (accept large bills)",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))

        minetest.remove_node(shop_at)
        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )

        local shop = smartshop.api.get_object(shop_at)

        shop.inv:set_stack("pay1", 1, "smartshop:currency_1")
        shop.inv:set_stack("give1", 1, "smartshop:node")
        shop.inv:set_stack("pay2", 1, "smartshop:currency_10")
        shop.inv:set_stack("give2", 1, "smartshop:node 5")
        shop.inv:set_stack("pay3", 1, "smartshop:currency_50")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        for _ = 1, 2 do
            put_in_shop(shop, "smartshop:node 99", player)
        end
        for _ = 1, 5 do
            put_in_shop(shop, "smartshop:tool", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:currency_100"})

        shop:receive_fields(player, {buy3a = true})
        shop:receive_fields(player, {buy2a = true})
        shop:receive_fields(player, {buy1a = true})

        assert(inv_count(player_inv, "main", "smartshop:currency_20") == 1  , "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:currency_1") == 19, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:node") == 6, "got correct # of nodes")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:currency_1") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:currency_10") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:currency_50") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:node") == (2 * 99 - 6), "correct amount were removed")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 4, "correct amount were removed")
    end
})


table.insert(smartshop.tests.tests, {
    name = "test that currency changing works (not enough money)",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))

        minetest.remove_node(shop_at)
        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )

        local shop = smartshop.api.get_object(shop_at)

        shop.inv:set_stack("pay1", 1, "smartshop:currency_1")
        shop.inv:set_stack("give1", 1, "smartshop:node")
        shop.inv:set_stack("pay2", 1, "smartshop:currency_10")
        shop.inv:set_stack("give2", 1, "smartshop:node 5")
        shop.inv:set_stack("pay3", 1, "smartshop:currency_50")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        for _ = 1, 2 do
            put_in_shop(shop, "smartshop:node 99", player)
        end
        for _ = 1, 5 do
            put_in_shop(shop, "smartshop:tool", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:currency_1 49"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:currency_1") == 49, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 0, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:currency_50") == 0, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 5, "correct amount were removed")
    end
})
