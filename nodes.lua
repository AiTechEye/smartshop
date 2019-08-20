local on_timer
if smartshop.settings.has_mesecon then
    function on_timer(pos, elapsed)
        mesecon.receptor_off(pos)
        return false
    end
else
    function on_timer() return false end
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
    return added
end

local function tube_can_insert(pos, node, stack, direction)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    return inv:room_for_item("main", stack)
end

local function shop_after_place_node(pos, placer)
    local meta        = minetest.get_meta(pos)
    local player_name = placer:get_player_name()
    local is_creative = smartshop.util.player_is_creative(player_name) and 1 or 0
    meta:set_string("owner", player_name)
    meta:set_string("infotext", "Shop by: " .. player_name)
    meta:set_int("unlimited", is_creative)
    meta:set_int("creative", is_creative)
end

local function wifi_after_place_node(pos, placer)
    local meta = minetest.get_meta(pos)
    local name = placer:get_player_name()
    meta:set_string("owner", name)
    meta:set_string("infotext", "Wifi storage by: " .. name)
end

local function shop_on_construct(pos)
    local meta = minetest.get_meta(pos)
    meta:set_int("state", 0) -- mesecons?
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
    meta:set_string("title", "wifi " .. minetest.pos_to_string(pos))
end

local function shop_on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.shop_showform(pos, player)
end

local function wifi_on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.wifi_showform(pos, player)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
    if stack:get_wear() ~= 0 or not smartshop.util.can_access(player, pos) then
        return 0
    elseif listname == "main" then
        return stack:get_count()
    else
        local inv = minetest.get_meta(pos):get_inventory()
        inv:set_stack(listname, index, stack)
        return 0
    end
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
    if not smartshop.util.can_access(player, pos) then
        return 0
    elseif listname == "main" then
        return stack:get_count()
    else
        local inv = minetest.get_meta(pos):get_inventory()
        inv:set_stack(listname, index, ItemStack(""))
        return 0
    end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
    if not smartshop.util.can_access(player, pos) then
        return 0
    elseif from_list == "main" and to_list == "main" then
        return count
    elseif from_list == "main" then
        local inv   = minetest.get_meta(pos):get_inventory()
        local stack = inv:get_stack(from_list, from_index)
        return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
    elseif to_list == "main" then
        local inv   = minetest.get_meta(pos):get_inventory()
        local stack = inv:get_stack(to_list, to_index)
        return allow_metadata_inventory_take(pos, from_list, from_index, stack, player)
    else
        return count
    end
end

local function on_metadata_inventory_put(pos, listname, index, stack, player)
    if listname == "main" then
        smartshop.log('action', '%s put %q in %s @ %s',
                      player:get_player_name(),
                      stack:to_string(),
                      minetest.get_node(pos).name,
                      minetest.pos_to_string(pos)
        )
    end
end

local function on_metadata_inventory_take(pos, listname, index, stack, player)
    if listname == "main" then
        smartshop.log('action', '%s took %q from %s @ %s',
                      player:get_player_name(),
                      stack:to_string(),
                      minetest.get_node(pos).name,
                      minetest.pos_to_string(pos)
        )
    end
end

local function can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    if (meta:get_string("owner") == "" or smartshop.util.can_access(player, pos)) and inv:is_empty("main") then
        smartshop.clear_shop_display(pos)
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
    on_timer                      = on_timer,
    tube                          = { insert_object   = shop_tube_insert,
                                      can_insert      = tube_can_insert,
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
    allow_metadata_inventory_put  = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    on_metadata_inventory_put     = on_metadata_inventory_put,
    on_metadata_inventory_take    = on_metadata_inventory_take,
    can_dig                       = can_dig,
}

local smartshop_full_def = smartshop.util.deepcopy(smartshop_def)
smartshop_full_def.drop = "smartshop:shop"
smartshop_full_def.tiles = { "default_chest_top.png^[colorize:#0000FF77^default_obsidian_glass.png" }
smartshop_full_def.groups.not_in_creative_inventory = 1

local smartshop_empty_def = smartshop.util.deepcopy(smartshop_full_def)
smartshop_empty_def.tiles = { "default_chest_top.png^[colorize:#FF000077^default_obsidian_glass.png" }

local smartshop_used_def = smartshop.util.deepcopy(smartshop_full_def)
smartshop_used_def.tiles = { "default_chest_top.png^[colorize:#00FF0077^default_obsidian_glass.png" }

local smartshop_admin_def = smartshop.util.deepcopy(smartshop_full_def)
smartshop_admin_def.tiles = { "default_chest_top.png^[colorize:#00FFFF77^default_obsidian_glass.png" }

minetest.register_node("smartshop:shop", smartshop_def)
minetest.register_node("smartshop:shop_full", smartshop_full_def)
minetest.register_node("smartshop:shop_empty", smartshop_empty_def)
minetest.register_node("smartshop:shop_used", smartshop_used_def)
minetest.register_node("smartshop:shop_admin", smartshop_admin_def)

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
        cur_name ~= "smartshop:shop_used" and
        cur_name ~= "smartshop:shop_admin"
    ) then
        return
    end
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    local is_unlimited = meta:get_int("unlimited") == 1

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
    if is_unlimited then
        to_swap = "smartshop:shop_admin"
    elseif total == 0 then
        to_swap = "smartshop:shop_empty"
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


minetest.register_node("smartshop:wifistorage", {
    description                   = "Smartshop external storage",
    tiles                         = { "default_chest_top.png^[colorize:#ffffff77^default_obsidian_glass.png" },
    groups                        = { choppy = 2,
                                      oddly_breakable_by_hand = 1,
                                      tubedevice = 1,
                                      tubedevice_receiver = 1,
                                      mesecon = 2 },
    paramtype                     = "light",
    sunlight_propagates           = true,
    light_source                  = 10,
    on_timer                      = on_timer,
    tube                          = { insert_object   = wifi_tube_insert,
                                      can_insert      = tube_can_insert,
                                      input_inventory = "main",
                                      connect_sides   = { left = 1,
                                                          right = 1,
                                                          front = 1,
                                                          back = 1,
                                                          top = 1,
                                                          bottom = 1 } },
    after_place_node              = wifi_after_place_node,
    on_construct                  = wifi_on_construct,
    on_rightclick                 = wifi_on_rightclick,
    allow_metadata_inventory_put  = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    on_metadata_inventory_put     = on_metadata_inventory_put,
    on_metadata_inventory_take    = on_metadata_inventory_take,
    can_dig                       = can_dig,
})
