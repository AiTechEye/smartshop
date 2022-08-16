local inv_count = smartshop.tests.inv_count
local put_in_shop = smartshop.tests.put_in_shop

smartshop.tests.register_test({
    name = "item with metadata in a normal shop can be purchased",
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

        local metatool = ItemStack("smartshop:tool")
        local tool_meta = metatool:get_meta()
        tool_meta:set_string("description", "Hey I'm a Tool")
        put_in_shop(shop, metatool, player)
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:gold"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:gold") == 0, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 0, "correct amount were removed")

        local should_have_meta = player_inv:remove_item("main", "smartshop:tool")
        tool_meta = should_have_meta:get_meta()
        assert(tool_meta:get_string("description") == "Hey I'm a Tool", "purchased tool has meta")
    end,
})

smartshop.tests.register_test({
    name = "shop is strict, only contains meta mismatch",
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
        shop:receive_fields(player, {strict_meta = "true"})

        shop.inv:set_stack("pay3", 1, "smartshop:gold")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        local metatool = ItemStack("smartshop:tool")
        local tool_meta = metatool:get_meta()
        tool_meta:set_string("description", "Hey I'm a Tool")
        put_in_shop(shop, metatool, player)
        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:gold"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:gold") == 1, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 0, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 0, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 1, "correct amount were removed")
    end,
})

smartshop.tests.register_test({
    name = "shop is strict, contains meta match and mismatch",
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
        shop:receive_fields(player, {strict_meta = "true"})

        shop.inv:set_stack("pay3", 1, "smartshop:gold")

        local metatool = ItemStack("smartshop:tool")
        local tool_meta = metatool:get_meta()
        tool_meta:set_string("description", "Hey I'm a Tool")
        put_in_shop(shop, "smartshop:tool", player)
        put_in_shop(shop, metatool, player)
        shop:update_appearance()
        shop.inv:set_stack("give3", 1, metatool)

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:gold"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:gold") == 0, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 1, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 1, "correct amount were removed")

        local should_have_meta = player_inv:remove_item("main", "smartshop:tool")
        tool_meta = should_have_meta:get_meta()
        assert(tool_meta:get_string("description") == "Hey I'm a Tool", "purchased tool has meta")
    end,
})
