local function get_inv_totals(shop_inv, refill_inv)
    local inv_totals = {}
	for i = 1, 32 do
		local stack = shop_inv:get_stack("main", i)
		if not stack:is_empty() and stack:is_known() and stack:get_wear() == 0 then
			local name = stack:get_name()
			inv_totals[name] = (inv_totals[name] or 0) + stack:get_count()
		end
	end
    if refill_inv then
        for i = 1, (12*5) do
            local stack = refill_inv:get_stack("main", i)
            if not stack:is_empty() and stack:is_known() and stack:get_wear() == 0 then
                local name = stack:get_name()
                inv_totals[name] = (inv_totals[name] or 0) + stack:get_count()
            end
        end
    end
    return inv_totals
end

local function get_info_lines(owner, shop_inv, inv_totals)
    local lines = {("(Smartshop by %s) Purchases left:"):format(owner)}
    for i = 1, 4, 1 do
		local pay_stack  = shop_inv:get_stack("pay" .. i, 1)
		local give_stack = shop_inv:get_stack("give" .. i, 1)
		if not pay_stack:is_empty() and not give_stack:is_empty() and give_stack:is_known() and give_stack:get_wear() == 0 then
			local name  = give_stack:get_name()
	        local count = give_stack:get_count()
			local stock = inv_totals[name] or 0
			local buy_count = math.floor(stock / count)
			if buy_count ~= 0 then
				local def         = give_stack:get_definition()
				local description = def.short_description or (def.description or ""):match("^[^\n]*")
                if not description or description == "" then
                    description = name
                end
				local message     = ("(%i) %s"):format(buy_count, description)
				table.insert(lines, message)
			end
		end
    end
    return lines
end

function smartshop.update_shop_info(pos)
    if not smartshop.is_smartshop(pos) then return end

    local shop_meta = minetest.get_meta(pos)
    local owner     = smartshop.get_owner(shop_meta)

	if smartshop.is_unlimited(shop_meta) then
        smartshop.set_infotext(shop_meta, "(Smartshop by %s) Stock is unlimited", owner)
        return
    end

    local shop_inv     = smartshop.get_inventory(shop_meta)
	local refill_spos  = smartshop.get_refill_spos(shop_meta)
    local refill_pos   = smartshop.util.string_to_pos(refill_spos)
    local refill_inv
    if refill_pos then
        refill_inv = smartshop.get_inventory(refill_pos)
    end

	local inv_totals = get_inv_totals(shop_inv, refill_inv)
	local lines = get_info_lines(owner, shop_inv, inv_totals)

    if #lines == 1 then
        smartshop.set_infotext(shop_meta, "(Smartshop by %s)\nThis shop is empty.", owner)
    else
        smartshop.set_infotext(shop_meta, table.concat(lines, "\n"):gsub("%%", "%%%%"))
    end
end


minetest.register_lbm({
	name = "smartshop:load_shop",
	nodenames = {
        "smartshop:shop",
        "smartshop:shop_full",
        "smartshop:shop_empty",
        "smartshop:shop_used",
        "smartshop:shop_admin"
    },
    run_at_every_load = true,
	action = function(pos, node)
        smartshop.clear_shop_entities(pos)
        smartshop.clear_old_entities(pos)
        smartshop.update_shop_entities(pos)

        smartshop.update_shop_info(pos)
        smartshop.update_shop_color(pos)

        -- convert metadata
        local meta = minetest.get_meta(pos)
        local metatable = meta:to_table() or {}
        if metatable.creative == 1 then
            if metatable.type == 0 then
                metatable.unlimited = 1
                metatable.item_send = nil
                metatable.item_refill = nil
            elseif metatable.type == 1 then
                metatable.unlimited = 0
            end
            if metatable.type then
                metatable.type = nil
            end
        end
        meta:from_table(metatable)
	end,
})
