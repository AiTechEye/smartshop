local inv_count = smartshop.tests.inv_count
local put_in_shop = smartshop.tests.put_in_shop

table.insert(smartshop.tests.tests, {
    name = "shop is full, but can place payment (item)",
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

        shop.inv:set_stack("pay3", 1, "smartshop:gold")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        for _ = 1, 32 do
            put_in_shop(shop, "smartshop:tool", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:gold"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:gold") == 0, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 31, "correct amount were removed")
    end
})

table.insert(smartshop.tests.tests, {
    name = "shop is full, but can place payment (currency)",
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

        shop.inv:set_stack("pay3", 1, "smartshop:currency_50")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        for _ = 1, 32 do
            put_in_shop(shop, "smartshop:tool", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:currency_1 50"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:currency_1") == 0, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:currency_50") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 31, "correct amount were removed")
    end
})

table.insert(smartshop.tests.tests, {
    name = "shop is full, exchange not possible",
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

        shop.inv:set_stack("pay3", 1, "smartshop:currency_1")
        shop.inv:set_stack("give3", 1, "smartshop:node")

        for _ = 1, 32 do
            put_in_shop(shop, "smartshop:node 99", player)
        end
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:currency_1"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:currency_1") == 1, "nothing was spent")
        assert(inv_count(player_inv, "main", "smartshop:node") == 0, "got no nodes")

        assert(inv_count(shop.inv, "main", "smartshop:currency_1") == 0, "nothing was received")
        assert(inv_count(shop.inv, "main", "smartshop:node") == 99 * 32, "nothing was removed")
    end
})
