local inv_count = smartshop.tests.inv_count

table.insert(smartshop.tests.tests, {
    name = "configure and use an admin shop",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(state.place_shop_against, vector.new(0, 0, 1))
        minetest.remove_node(shop_at)

        minetest.set_player_privs(player:get_player_name(), {
            interact = true,
            server = true,
            [smartshop.settings.admin_shop_priv] = true,
        })

        minetest.item_place_node(
            ItemStack("smartshop:shop"),
            player,
            {type = "node", under = under, above = shop_at}
        )

        local shop = smartshop.api.get_object(shop_at)

        shop.inv:set_stack("pay3", 1, "smartshop:gold")
        shop.inv:set_stack("give3", 1, "smartshop:tool")

        shop:update_appearance()

        local player_inv = player:get_inventory()
        player_inv:set_list("main", {"smartshop:gold"})

        shop:receive_fields(player, {buy3a = true})

        assert(inv_count(player_inv, "main", "smartshop:gold") == 0, "correct amount was spent")
        assert(inv_count(player_inv, "main", "smartshop:tool") == 1, "got correct # of tools")

        assert(inv_count(shop.inv, "main", "smartshop:gold") == 0, "correct amount was received")
        assert(inv_count(shop.inv, "main", "smartshop:tool") == 0, "correct amount were removed")
    end,
})

local function init_old_admin_shop(pos, player)
    minetest.remove_node(pos)
    minetest.swap_node(pos, {name = "smartshop:shop"})

    local player_name = player:get_player_name()
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", player_name)
    meta:set_string("infotext", ("(Smartshop by %s) Stock is unlimited"):format(player_name))
    meta:set_int("creative", 1)

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

table.insert(smartshop.tests.tests, {
    name = "update old admin shop",
    func = function(player, state)
        local under = state.place_shop_against
        local shop_at = vector.subtract(under, vector.new(0, 0, 1))

        minetest.set_player_privs(player:get_player_name(), {
            interact = true,
            server = true,
            [smartshop.settings.admin_shop_priv] = true,
        })

        init_old_admin_shop(shop_at, player)

        local meta = minetest.get_meta(shop_at)
        local inv = meta:get_inventory()

        inv:set_stack("give3", 1, "smartshop:gold")
        inv:set_stack("pay3", 1, "smartshop:tool")
        inv:set_stack("main", 1, "smartshop:gold 98")

        smartshop.compat.convert_legacy_shop(shop_at)
        smartshop.compat.do_refund(shop_at)

        assert(inv_count(inv, "main", "smartshop:gold") == 98, "refunded correct amount")
        assert(inv_count(inv, "main", "smartshop:tool") == 0, "refunded correct amount")

        local shop = smartshop.api.get_object(shop_at)
        assert(shop:is_unlimited(), "shop is still an admin shop")
    end,
})
