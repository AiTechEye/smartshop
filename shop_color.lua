local function get_exchange_status(shop_inv, slot, send_inv, refill_inv)
    local pay_key = "pay"..slot
    local pay_stack = shop_inv:get_stack(pay_key, 1)
    local give_key = "give"..slot
    local give_stack = shop_inv:get_stack(give_key, 1)

    -- TODO: this isn't quite correct, as it doesn't allow for stacks split between the shop and storage
    if give_stack:is_empty() or pay_stack:is_empty() then
        return "skip"
    elseif not (shop_inv:room_for_item("main", pay_stack) or (send_inv and send_inv:room_for_item("main", pay_stack))) then
        return "full"
    elseif not (shop_inv:contains_item("main", give_stack) or (refill_inv and refill_inv:contains_item("main", give_stack))) then
        return "empty"
    elseif shop_inv:contains_item("main", pay_stack) or (send_inv and send_inv:contains_item("main", pay_stack)) then
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
    if not smartshop.is_smartshop(pos) then
        return
    end
    local shop_meta    = minetest.get_meta(pos)
    local shop_inv     = smartshop.get_inventory(shop_meta)
    local is_unlimited = smartshop.is_unlimited(shop_meta)
	local send_spos    = smartshop.get_send_spos(shop_meta)
    local send_pos     = smartshop.util.string_to_pos(send_spos)
	local send_inv     = send_pos and minetest.get_meta(send_pos):get_inventory()
	local refill_spos  = smartshop.get_refill_spos(shop_meta)
    local refill_pos   = smartshop.util.string_to_pos(refill_spos)
	local refill_inv   = refill_pos and minetest.get_meta(refill_pos):get_inventory()

    local total        = 4
    local full_count   = 0
    local empty_count  = 0
    local used         = false

    for slot = 1,4 do
        local status = get_exchange_status(shop_inv, slot, send_inv, refill_inv)
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

    local node = minetest.get_node(pos)
    local node_name = node.name
    if node_name ~= to_swap then
        minetest.swap_node(pos, {
            name = to_swap,
            param2 = node.param2
        })
    end
end
