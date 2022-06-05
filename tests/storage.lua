local inv_count = smartshop.tests.inv_count

table.insert(smartshop.tests, {
    name = "connect and use separate storage",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = state.shop_at
        minetest.remove_node(shop_at)
        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )
        local send_at = vector.subtract(state.place_shop_against, vector.new(1, 0, 0))
        minetest.item_place_node(
            ItemStack("smartshop:storage"),
            player,
            {type = "node", under = under, above = send_at}
        )
        local refill_at = vector.add(state.place_shop_against, vector.new(1, 0, 0))
        minetest.item_place_node(
            ItemStack("smartshop:storage"),
            player,
            {type = "node", under = under, above = refill_at}
        )

        local shop = smartshop.api.get_object(shop_at)
        local storage_def = minetest.registered_nodes["smartshop:storage"]
        shop:receive_fields(player, {tsend = true})
        storage_def.on_punch(send_at, minetest.get_node(send_at), player,
            {type="node", under=send_at, above=send_at})
        shop:receive_fields(player, {trefill = true})
        storage_def.on_punch(refill_at, minetest.get_node(refill_at), player,
            {type="node", under=refill_at, above=refill_at})
        local send = shop:get_send()
        local refill = shop:get_refill()

        shop.inv:set_stack("pay1", 1, "smartshop:gold")
        shop.inv:set_stack("give1", 1, "smartshop:node")
        shop.inv:set_stack("pay2", 1, "smartshop:gold 5")
        shop.inv:set_stack("give2", 1, "smartshop:node 5")
        shop.inv:set_stack("pay3", 1, "smartshop:gold 10")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        refill.inv:add_item("main", "smartshop:node 25")
        refill:on_metadata_inventory_put("main", 1, ItemStack("smartshop:node 25"), player)
        refill.inv:add_item("main", "smartshop:tool")
        refill:on_metadata_inventory_put("main", 1, ItemStack("smartshop:tool"), player)
        shop:update_appearance()

        player:get_inventory():set_list("main", {"smartshop:gold 99"})

        shop:receive_fields(player, {buy1a = true})
        shop:receive_fields(player, {buy2a = true})
        shop:receive_fields(player, {buy3a = true})
        shop:receive_fields(player, {buy4a = true})

        local player_inv = player:get_inventory()

        assert(inv_count(player_inv, "main", "smartshop:gold") == 83, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:node") == 6, "got correct # of nodes")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(send.inv, "main", "smartshop:gold") == 16, "correct amount was received")
        assert(inv_count(refill.inv, "main", "smartshop:node") == 19, "correct amount were removed")
        assert(inv_count(refill.inv, "main", "smartshop:tool") == 0, "correct amount were removed")

        minetest.remove_node(send_at)
        minetest.remove_node(refill_at)
    end,
})
