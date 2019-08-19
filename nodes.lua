local shop_on_timer, wifi_on_timer
if smartshop.settings.has_mesecon then
    function shop_on_timer(pos, elapsed)
        mesecon.receptor_off(pos)
        return false
    end

    function wifi_on_timer(pos, elapsed)
        mesecon.receptor_off(pos)
        return false
    end
else
    function shop_on_timer() return false end
    function wifi_on_timer(pos, elapsed) return false end
end

local function shop_tube_insert(pos, node, stack, direction)
    local meta  = minetest.get_meta(pos)
    local inv   = meta:get_inventory()
    local added = inv:add_item("main", stack)
    smartshop.update_shop_color(pos)
    return added
end

local function wifi_tube_insert(pos, node, stack, direction)
    local meta  = minetest.get_meta(pos)
    local inv   = meta:get_inventory()
    local added = inv:add_item("main", stack)
    smartshop.update_shop_color(pos)
    return added
end

local function shop_tube_can_insert(pos, node, stack, direction)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    return inv:room_for_item("main", stack)
end

local function wifi_tube_can_insert(pos, node, stack, direction)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    return inv:room_for_item("main", stack)
end

local function shop_after_place_node(pos, placer)
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", placer:get_player_name())
    meta:set_string("infotext", "Shop by: " .. placer:get_player_name())
    meta:set_int("type", 1)
    meta:set_int("sellall", 1)
    if smartshop.util.player_is_creative(placer:get_player_name()) then
        meta:set_int("creative", 1)
        meta:set_int("type", 0)
        meta:set_int("sellall", 0)
    end
end

local function wifi_after_place_node(pos, placer)
    local meta = minetest.get_meta(pos)
    local name = placer:get_player_name()
    meta:set_string("owner", name)
    meta:set_string("infotext", "Wifi storage by: " .. name)
end

local function shop_on_construct(pos)
    local meta = minetest.get_meta(pos)
    meta:set_int("state", 0)
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

local function wifi_on_construct(pos)
    local meta = minetest.get_meta(pos)
    meta:get_inventory():set_size("main", 60)
    meta:set_int("mesein", 0)
    meta:set_string("title", "wifi" .. math.random(1, 999))
end

local function shop_on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.shop_showform(pos, player)
end

local function wifi_on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.wifi_showform(pos, player)
end

local function shop_allow_put(pos, listname, index, stack, player)
    if stack:get_wear() == 0 and smartshop.util.can_access(player, pos) then
        return stack:get_count()
    end
    return 0
end

local function wifi_allow_put(pos, listname, index, stack, player)
    if stack:get_wear() == 0 and smartshop.util.can_access(player, pos) then
        return stack:get_count()
    end
    return 0
end

local function shop_allow_take(pos, listname, index, stack, player)
    if smartshop.util.can_access(player, pos) then
        return stack:get_count()
    end
    return 0
end

local function wifi_allow_take(pos, listname, index, stack, player)
    if smartshop.util.can_access(player, pos) then
        return stack:get_count()
    end
    return 0
end

local function shop_allow_move(pos, from_list, from_index, to_list, to_index, count, player)
    if smartshop.util.can_access(player, pos) then
        return count
    end
    return 0
end

local function shop_can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    local invs_are_empty = (
        inv:is_empty("main") and
        inv:is_empty("pay1") and
        inv:is_empty("pay2") and
        inv:is_empty("pay3") and
        inv:is_empty("pay4") and
        inv:is_empty("give1") and
        inv:is_empty("give2") and
        inv:is_empty("give3") and
        inv:is_empty("give4")
    )
    if (meta:get_string("owner") == "" or smartshop.util.can_access(player, pos)) and invs_are_empty then
        smartshop.clear_shop_display(pos)
        return true
    end
end

local function wifi_can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    if (meta:get_string("owner") == "" or smartshop.util.can_access(player, pos)) and inv:is_empty("main")  then
        return true
    end
end

local smartshop_def = {
    description                   = "Smartshop",
    tiles                         = { "default_chest_top.png^[colorize:#ffffff77^default_obsidian_glass.png" },
    groups                        = { choppy = 2,
                                      oddly_breakable_by_hand = 1,
                                      tubedevice = 1,
                                      tubedevice_receiver = 1,
                                      mesecon = 2 },
    drawtype                      = "nodebox",
    node_box                      = { type = "fixed",
                                      fixed = { -0.5, -0.5, -0.0, 0.5, 0.5, 0.5 } },
    paramtype2                    = "facedir",
    paramtype                     = "light",
    sunlight_propagates           = true,
    light_source                  = 10,
    on_timer                      = shop_on_timer,
    tube                          = { insert_object   = shop_tube_insert,
                                      can_insert      = shop_tube_can_insert,
                                      input_inventory = "main",
                                      connect_sides   = { left = 1,
                                                          right = 1,
                                                          front = 1,
                                                          back = 1,
                                                          top = 1,
                                                          bottom = 1 } },
    after_place_node              = shop_after_place_node,
    on_construct                  = shop_on_construct,
    on_rightclick                 = shop_on_rightclick,
    allow_metadata_inventory_put  = shop_allow_put,
    allow_metadata_inventory_take = shop_allow_take,
    allow_metadata_inventory_move = shop_allow_move,
    can_dig                       = shop_can_dig,
}

local smartshop_full_def = smartshop.util.deepcopy(smartshop_def)
smartshop_full_def.drop = "smartshop:shop"
smartshop_full_def.tiles = { "default_chest_top.png^[colorize:#0000FF77^default_obsidian_glass.png" }
smartshop_full_def.groups.not_in_creative_inventory = 1

local smartshop_empty_def = smartshop.util.deepcopy(smartshop_def)
smartshop_empty_def.drop = "smartshop:shop"
smartshop_empty_def.tiles = { "default_chest_top.png^[colorize:#FF000077^default_obsidian_glass.png" }
smartshop_empty_def.groups.not_in_creative_inventory = 1

local smartshop_used_def = smartshop.util.deepcopy(smartshop_def)
smartshop_used_def.drop = "smartshop:shop"
smartshop_used_def.tiles = { "default_chest_top.png^[colorize:#00FF0077^default_obsidian_glass.png" }
smartshop_used_def.groups.not_in_creative_inventory = 1

minetest.register_node("smartshop:shop", smartshop_def)
minetest.register_node("smartshop:shop_full", smartshop_full_def)
minetest.register_node("smartshop:shop_empty", smartshop_empty_def)
minetest.register_node("smartshop:shop_used", smartshop_used_def)

minetest.register_node("smartshop:wifistorage", {
    description                   = "Wifi storage",
    tiles                         = { "default_chest_top.png^[colorize:#ffffff77^default_obsidian_glass.png" },
    groups                        = { choppy = 2, oddly_breakable_by_hand = 1, tubedevice = 1, tubedevice_receiver = 1, mesecon = 2 },
    paramtype                     = "light",
    sunlight_propagates           = true,
    light_source                  = 10,
    on_timer                      = wifi_on_timer,
    tube                          = { insert_object   = wifi_tube_insert,
                                      can_insert      = wifi_tube_can_insert,
                                      input_inventory = "main",
                                      connect_sides   = { left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1 } },
    after_place_node              = wifi_after_place_node,
    on_construct                  = wifi_on_construct,
    on_rightclick                 = wifi_on_rightclick,
    allow_metadata_inventory_put  = wifi_allow_put,
    allow_metadata_inventory_take = wifi_allow_take,
    can_dig                       = wifi_can_dig,
})

local function exchange_status(inv, slot)
    local pay_key = "pay"..slot
    local pay_stack = inv:get_stack(pay_key, 1)
    local give_key = "give"..slot
    local give_stack = inv:get_stack(give_key, 1)

    if give_stack:is_empty() or pay_stack:is_empty() then
        return "skip"
    elseif not inv:room_for_item("main", pay_stack) then
        return "full"
    elseif not inv:contains_item("main", give_stack) then
        return "empty"
    elseif inv:contains_item("main", pay_stack) then
        return "used"
    else
        return "ignore"
    end
end

function smartshop.update_shop_color(pos)
    --[[
    normal: nothing in the give slots
    full  : no exchanges possible because no room for pay items
    empty : no exchanges possible because no more give items
    used  : pay items in main
    ]]--
    local node = minetest.get_node(pos)
    local cur_name = node.name
    if (
        cur_name ~= "smartshop:shop" and
        cur_name ~= "smartshop:shop_full" and
        cur_name ~= "smartshop:shop_empty" and
        cur_name ~= "smartshop:shop_used"
    ) then
        return
    end
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()

    local total = 4
    local full_count = 0
    local empty_count = 0
    local used = false

    for slot = 1,4 do
        local status = exchange_status(inv, slot)
        if status == "full" then
            full_count = full_count + 1
        elseif status == "empty" then
            empty_count = empty_count + 1
        elseif status == "used" then
            used = true
        elseif status == "skip" then
            total = total - 1
        end
    end

    local to_swap
    if total == 0 then
        to_swap = "smartshop:shop"
    elseif full_count == total then
        to_swap = "smartshop:shop_full"
    elseif empty_count == total then
        to_swap = "smartshop:shop_empty"
    elseif used then
        to_swap = "smartshop:shop_used"
    else
        to_swap = "smartshop:shop"
    end

    if cur_name ~= to_swap then
        minetest.swap_node(pos, {
            name = to_swap,
            param2 = node.param2
        })
    end
end
