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
    smartshop.update_shop_color(pos)
    return added
end

local function after_place_node(pos, placer)
    local shop_meta   = minetest.get_meta(pos)
    local player_name = placer:get_player_name()
    local is_creative = smartshop.util.player_is_creative(player_name) and 1 or 0
    smartshop.set_owner(shop_meta, player_name)
    smartshop.set_infotext(shop_meta, ("Shop by: %s"):format(player_name))
    smartshop.set_creative(shop_meta, is_creative)
    smartshop.set_unlimited(shop_meta, is_creative)
    smartshop.update_shop_color(pos)
end

local function on_construct(pos)
    local meta = minetest.get_meta(pos)
    smartshop.set_state(meta, 0) -- mesecons?
    local inv = smartshop.get_inventory(meta)
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

local function on_rightclick(pos, node, player, itemstack, pointed_thing)
    smartshop.shop_showform(pos, player)
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
        if allow_metadata_inventory_put(pos, to_list, to_index, stack, player) ~= 0 then
            return count
        else
            return 0
        end
    elseif to_list == "main" then
        local inv   = smartshop.get_inventory(pos)
        local stack = inv:get_stack(to_list, to_index)
        if allow_metadata_inventory_take(pos, from_list, from_index, stack, player) ~= 0 then
            return count
        else
            return 0
        end
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
    local meta  = minetest.get_meta(pos)
    local inv   = smartshop.get_inventory(meta)
    local owner = smartshop.get_owner(meta)
    if (owner == "" or smartshop.util.can_access(player, pos)) and inv:is_empty("main") then
        smartshop.clear_shop_display(pos)
        return true
    end
end

local smartshop_def                                 = {
    description                   = "Smartshop",
    tiles                         = { "(default_chest_top.png^[colorize:#FFFFFF77)^default_obsidian_glass.png" },
    groups                        = { choppy                  = 2,
                                      oddly_breakable_by_hand = 1,
                                      tubedevice              = 1,
                                      tubedevice_receiver     = 1,
                                      mesecon                 = 2 },
    drawtype                      = "nodebox",
    node_box                      = { type  = "fixed",
                                      fixed = { -0.5, -0.5, -0.0, 0.5, 0.5, 0.5 } },
    paramtype2                    = "facedir",
    paramtype                     = "light",
    sunlight_propagates           = true,
    light_source                  = 10,
    on_timer                      = on_timer,
    tube                          = { insert_object   = tube_insert,
                                      can_insert      = tube_can_insert,
                                      input_inventory = "main",
                                      connect_sides   = { left   = 1,
                                                          right  = 1,
                                                          front  = 1,
                                                          back   = 1,
                                                          top    = 1,
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
}

local smartshop_full_def                            = smartshop.util.deepcopy(smartshop_def)
smartshop_full_def.drop                             = "smartshop:shop"
smartshop_full_def.tiles                            = { "(default_chest_top.png^[colorize:#FFFFFF77)^(default_obsidian_glass.png^[colorize:#0000FF77)" }
smartshop_full_def.groups.not_in_creative_inventory = 1

local smartshop_empty_def                           = smartshop.util.deepcopy(smartshop_full_def)
smartshop_empty_def.tiles                           = { "(default_chest_top.png^[colorize:#FFFFFF77)^(default_obsidian_glass.png^[colorize:#FF000077)" }

local smartshop_used_def                            = smartshop.util.deepcopy(smartshop_full_def)
smartshop_used_def.tiles                            = { "(default_chest_top.png^[colorize:#FFFFFF77)^(default_obsidian_glass.png^[colorize:#00FF0077)" }

local smartshop_admin_def                           = smartshop.util.deepcopy(smartshop_full_def)
smartshop_admin_def.tiles                           = { "(default_chest_top.png^[colorize:#FFFFFF77)^(default_obsidian_glass.png^[colorize:#00FFFF77)" }

minetest.register_node("smartshop:shop", smartshop_def)
minetest.register_node("smartshop:shop_full", smartshop_full_def)
minetest.register_node("smartshop:shop_empty", smartshop_empty_def)
minetest.register_node("smartshop:shop_used", smartshop_used_def)
minetest.register_node("smartshop:shop_admin", smartshop_admin_def)

smartshop.shop_node_names = {
    "smartshop:shop",
    "smartshop:shop_full",
    "smartshop:shop_empty",
    "smartshop:shop_used",
    "smartshop:shop_admin"
}

function smartshop.is_smartshop(pos)
    local node = minetest.get_node(pos)
    local node_name = node.name
    for _, name in ipairs(smartshop.shop_node_names) do
        if name == node_name then return true end
    end
    return false
end

minetest.register_lbm({
    name              = "smartshop:repay_lost_stuff",
    nodenames         = {
        "smartshop:shop",
        "smartshop:shop_empty",
        "smartshop:shop_full",
        "smartshop:shop_used",
    },
    run_at_every_load = false,
    action            = function(pos, node)
        -- recoup lost inventory items if possible
        local meta = minetest.get_meta(pos)
        if smartshop.is_creative(meta) then return end
        local inv = smartshop.get_inventory(meta)
        for index = 1, 4 do
            local pay_stack = inv:get_stack("pay" .. index, 1)
            if not pay_stack:is_empty() and inv:room_for_item("main", pay_stack) then
                inv:add_item("main", pay_stack)
            end
            local give_stack = inv:get_stack("give" .. index, 1)
            if not give_stack:is_empty() and inv:room_for_item("main", give_stack) then
                inv:add_item("main", give_stack)
            end
        end
    end,
})
