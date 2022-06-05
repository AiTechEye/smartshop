smartshop.tests = {
    tests = {},
    inv_count = function(inv, listname, item_name)
        local count = 0
        for _, item in ipairs(inv:get_list(listname)) do
            if item:get_name() == item_name then
                count = count + item:get_count()
            end
        end
        return count
    end,
    put_in_shop = function(shop, item, player)
        local stack = ItemStack(item)
        for i = 1, 32 do
            if shop.inv:get_stack("main", i):is_empty() then
                shop.inv:set_stack("main", i, stack)
                shop:on_metadata_inventory_put("main", i, stack, player)
                return
            end
        end
    end,
}

minetest.settings:set("movement_gravity", 0)

local function run_test(name, state, i)
    if not i then
        error(("? %s %s %s"):format(name, state, i))
    end
    if i > #smartshop.tests.tests then
        return
    end
    local player = minetest.get_player_by_name(name)
    if not player then
        return
    end
    local start = minetest.get_us_time()
    local test = smartshop.tests.tests[i]
    local ok, res = xpcall(test.func, debug.traceback, player, state)
    local elapsed = (minetest.get_us_time() - start) / 1e6
    if ok then
        minetest.chat_send_player(name, ("%s passed in %ss"):format(test.name, elapsed))
        state = res or state
    else
        minetest.chat_send_player(name, ("%s failed in %ss"):format(test.name, elapsed))
        minetest.chat_send_player(name, res)
        return
    end

    minetest.after(0, run_test, name, state, i + 1)
end

minetest.register_chatcommand("smartshop_tests", {
    privs = {server = true},
    func = function(name)
        run_test(name, {}, 1)
    end
})

smartshop.dofile("tests", "define_items")

smartshop.dofile("tests", "initialize")
smartshop.dofile("tests", "place_shop")
smartshop.dofile("tests", "dig_shop")
smartshop.dofile("tests", "configure_shop")
smartshop.dofile("tests", "do_purchase")

smartshop.dofile("tests", "upgrade_old_shop")
smartshop.dofile("tests", "storage")
smartshop.dofile("tests", "currency")
smartshop.dofile("tests", "shop_full")
smartshop.dofile("tests", "strict_meta")
smartshop.dofile("tests", "admin_shop")
