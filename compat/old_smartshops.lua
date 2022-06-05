--[[
because this fork turns the "give" and "pay" lines in the shop inventory into
placeholders, and not actual inventory slots, upgrading causes the items
stored in those slots to be lost.

if enabled (by default), this LBM will refund those items, even in the event
that the shop is currently full, by waiting until there's available space.

the items can still be lost, though, if the player empties the shop and then
breaks the node, before the LBM has been run.
--]]


local v_eq = vector.equals
local v_round = vector.round

local string_to_pos = smartshop.util.string_to_pos

local get_meta = minetest.get_meta
local get_objects_inside_radius = minetest.get_objects_inside_radius

local api = smartshop.api

local function clear_legacy_entities(pos)
    for _, ob in ipairs(get_objects_inside_radius(pos, 3)) do
        -- "3" was chosen because "2" doesn't work sometimes. it should work w/ "1" but doesn't.
        -- note that we still check that the entity is related to the current shop

        local le = ob:get_luaentity()
        if le then
            if le.smartshop then
                -- old smartshop entity
                ob:remove()
            elseif le.pos and type(le.pos) == "table" and v_eq(pos, v_round(le.pos)) then
                -- entities associated w/ the current pos
                ob:remove()
            end
        end
    end
end

local function convert_metadata(pos)
    -- convert legacy metadata
	local shop = api.get_object(pos)
    local meta = get_meta(pos)
    local old_metatable = meta:to_table() or {}
	local fields = old_metatable.fields or {}
	meta:from_table({inventory = old_metatable.inventory})
	shop:initialize_metadata(fields.owner)

    if fields.creative == 1 and (fields.type or 0) == 0 then
        shop:set_unlimited(true)
        shop:set_send_pos()
        shop:set_refill_pos()
    else
	    if fields.item_send then
			local pos2 = string_to_pos(fields.item_send)
		    if pos2 then
			    shop:set_send_pos(pos2)
		    end
	    end
	    if fields.item_refill then
			local pos2 = string_to_pos(fields.item_refill)
		    if pos2 then
			    shop:set_refill_pos(pos2)
		    end
	    end
    end

	if smartshop.settings.enable_refund then
		meta:set_string("upgraded", fields.upgraded or "")
		smartshop.compat.do_refund(pos)
	end
end

function smartshop.compat.convert_legacy_shop(pos)
	convert_metadata(pos)
	clear_legacy_entities(pos)

	local shop = api.get_object(pos)
	shop:update_appearance()
end

minetest.register_lbm({
	name = "smartshop:convert_legacy",
	nodenames = {
        "smartshop:shop",
    },
    run_at_every_load = false,
	action = function(pos)
		smartshop.compat.convert_legacy_shop(pos)
	end,
})

local function try_refund(shop)
	local owner = shop:get_owner()

	local unrefunded = {}

	for _, itemstring in ipairs(shop:get_refund()) do
		local itemstack = ItemStack(itemstring)
		if shop:room_for_item(itemstack) then
			smartshop.log("action", "refunding %s to %s's shop at %s",
				itemstring, owner, minetest.pos_to_string(shop.pos, 0)
			)
			shop:add_item(itemstack)
		else
			table.insert(unrefunded, itemstack:to_string())
		end
	end

	shop:set_refund(unrefunded)
end

local function generate_unrefunded(shop)
	local inv = shop.inv

	local unrefunded = {}

	for index = 1, 4 do
		local pay_stack = inv:get_stack("pay" .. index, 1)
		if not pay_stack:is_empty() then
			table.insert(unrefunded, pay_stack:to_string())
		end

		local give_stack = inv:get_stack("give" .. index, 1)
		if not give_stack:is_empty() then
			table.insert(unrefunded, give_stack:to_string())
		end
	end

	return unrefunded
end

function smartshop.compat.do_refund(pos)
	local shop = smartshop.api.get_object(pos)

	-- don't bother refunding admin shops
	if shop:is_admin() then
		shop:set_upgraded()
		return
	end

	if not shop:has_upgraded() then
		local unrefunded = generate_unrefunded(shop)
		shop:set_refund(unrefunded)
		shop:set_upgraded()
	end

	if shop:has_refund() then
		try_refund(shop)
	end
end

if smartshop.settings.enable_refund then
	minetest.register_lbm({
		name = "smartshop:repay_lost_stuff",
		nodenames = {
			"smartshop:shop",
			"smartshop:shop_empty",
			"smartshop:shop_full",
			"smartshop:shop_used",
		},
		run_at_every_load = true,
		action = function(pos, node)
			smartshop.compat.do_refund(pos)
		end,
	})
end
