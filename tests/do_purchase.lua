local inv_count = smartshop.tests.inv_count

smartshop.tests.register_test({
    name = "simulate a purchase",
    func = function(player, state)
        local shop_at = state.shop_at
        player:get_inventory():set_list("main", {"smartshop:gold 99"})

        local shop = smartshop.api.get_object(shop_at)
        shop:receive_fields(player, {buy1a = true})
        shop:receive_fields(player, {buy2a = true})
        shop:receive_fields(player, {buy3a = true})
        shop:receive_fields(player, {buy4a = true})

        local player_inv = player:get_inventory()

        assert(inv_count(player_inv, "main", "smartshop:gold") == 83, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:node") == 6, "got correct # of nodes")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 16, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:node") == 19, "correct amount were removed")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 0, "correct amount were removed")
    end,
})
