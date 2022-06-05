
table.insert(smartshop.tests.tests, {
    name = "configure a shop",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))
        assert(minetest.get_node(shop_at).name == "air", "room for shop")
        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )
        local player_name = player:get_player_name()
        local shop = smartshop.api.get_object(shop_at)
        assert(shop, "creation of shop object")
        assert(not shop:is_admin(), "not an admin shop")
        assert(not shop:is_unlimited(), "not unlimited inventory")
        assert(shop:get_owner() == player_name, "player is owner")
        assert(not shop:get_send(), "no send inventory")
        assert(not shop:get_refill(), "no send refill")
        assert(shop:has_upgraded(), "is an upgraded shop")
        assert(not shop:has_refund(), "no refund")

        shop.inv:set_stack("pay1", 1, "smartshop:gold")
        shop.inv:set_stack("give1", 1, "smartshop:node")
        shop.inv:set_stack("pay2", 1, "smartshop:gold 5")
        shop.inv:set_stack("give2", 1, "smartshop:node 5")
        shop.inv:set_stack("pay3", 1, "smartshop:gold 10")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        shop.inv:add_item("main", "smartshop:node 25")
        shop:on_metadata_inventory_put("main", 1, ItemStack("smartshop:node 25"), player)
        shop.inv:add_item("main", "smartshop:tool")
        shop:on_metadata_inventory_put("main", 1, ItemStack("smartshop:tool"), player)
        shop:update_appearance()

        state.shop_at = shop_at
        return state
    end
})
