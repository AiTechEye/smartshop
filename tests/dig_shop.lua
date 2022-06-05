
table.insert(smartshop.tests.tests, {
    name = "dig shop",
    func = function(player, state)
        assert(minetest.node_dig(state.shop_at, minetest.get_node(state.shop_at), player), "node_dig")
        assert(minetest.get_node(state.shop_at).name == "air", "node_dig success")
        state.shop_at = nil
        player:get_inventory():set_list("main", {})
        return state
    end,
})
