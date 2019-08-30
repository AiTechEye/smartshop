local function get_exchange_status(inv, slot)
    local pay_key = "pay"..slot
    local pay_stack = inv:get_stack(pay_key, 1)
    local give_key = "give"..slot
    local give_stack = inv:get_stack(give_key, 1)

    if give_stack:is_empty() and pay_stack:is_empty() then
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
    local shop_meta    = minetest.get_meta(pos)
    local shop_inv     = smartshop.get_inventory(shop_meta)
    local is_unlimited = smartshop.is_unlimited(shop_meta)

    local total        = 4
    local full_count   = 0
    local empty_count  = 0
    local used         = false

    for slot = 1,4 do
        local status = get_exchange_status(shop_inv, slot)
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
        to_swap = "smartshop:shop_empty"
    elseif is_unlimited then
        to_swap = "smartshop:shop_admin"
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
