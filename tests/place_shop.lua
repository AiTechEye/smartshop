
smartshop.tests.register_test({
    name = "place a shop",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))
        local placed_stack, placed_pos = minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )
        assert(vector.equals(placed_pos, shop_at), "placed to right position")
        assert(placed_stack:is_empty(), "no rv after place")
        local node = minetest.get_node(shop_at)
        assert(node.name == "smartshop:shop", "correct node placed")

        state.shop_at = shop_at
        return state
    end
})
