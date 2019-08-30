local on_timer
if smartshop.settings.has_mesecon then
    function on_timer(pos, elapsed)
        mesecon.receptor_off(pos)
        return false
    end
else
    function on_timer() return false end
end

local function tube_can_insert(pos, node, stack, direction)
    local meta = minetest.get_meta(pos)
    local inv  = smartshop.get_inventory(meta)
    return inv:room_for_item("main", stack)
end

local function tube_insert(pos, node, stack, direction)
    local meta  = minetest.get_meta(pos)
    local inv   = smartshop.get_inventory(meta)
    local added = inv:add_item("main", stack)
    return added
end

local function after_place_node(pos, placer)
    local meta        = minetest.get_meta(pos)
    local player_name = placer:get_player_name()
    smartshop.set_owner(meta, player_name)
    smartshop.set_infotext(meta, ("External storage by: %s"):format(player_name))
end

local function on_construct(pos)
    local meta = minetest.get_meta(pos)
    local inv = smartshop.get_inventory(meta)
    inv:set_size("main", 60)
    smartshop.set_mesein(meta, 0)
    smartshop.set_title(meta, "storage@" .. minetest.pos_to_string(pos))
end

local function on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.wifi_showform(pos, player)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
    if stack:get_wear() ~= 0 or not smartshop.util.can_access(player, pos) then
        return 0
    elseif listname == "main" then
        return stack:get_count()
    else
        local inv = smartshop.get_inventory(pos)
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
        local inv = smartshop.get_inventory(pos)
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
        local inv   = smartshop.get_inventory(pos)
        local stack = inv:get_stack(from_list, from_index)
        return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
    elseif to_list == "main" then
        local inv   = smartshop.get_inventory(pos)
        local stack = inv:get_stack(to_list, to_index)
        return allow_metadata_inventory_take(pos, from_list, from_index, stack, player)
    else
        return count
    end
end

local function on_metadata_inventory_put(pos, listname, index, stack, player)
    if listname == "main" then
        smartshop.log("action", "%s put %q in %s @ %s",
                      player:get_player_name(),
                      stack:to_string(),
                      minetest.get_node(pos).name,
                      minetest.pos_to_string(pos)
        )
    end
end

local function on_metadata_inventory_take(pos, listname, index, stack, player)
    if listname == "main" then
        smartshop.log("action", "%s took %q from %s @ %s",
                      player:get_player_name(),
                      stack:to_string(),
                      minetest.get_node(pos).name,
                      minetest.pos_to_string(pos)
        )
    end
end

local function can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv  = smartshop.get_inventory(meta)
    local owner = smartshop.get_owner(meta)
    if (owner == "" or smartshop.util.can_access(player, pos)) and inv:is_empty("main") then
        return true
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
    tube                          = { insert_object   = tube_insert,
                                      can_insert      = tube_can_insert,
                                      input_inventory = "main",
                                      connect_sides   = { left = 1,
                                                          right = 1,
                                                          front = 1,
                                                          back = 1,
                                                          top = 1,
                                                          bottom = 1 } },
    after_place_node              = after_place_node,
    on_construct                  = on_construct,
    on_rightclick                 = on_rightclick,
    allow_metadata_inventory_put  = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    on_metadata_inventory_put     = on_metadata_inventory_put,
    on_metadata_inventory_take    = on_metadata_inventory_take,
    can_dig                       = can_dig,
})
