local api = smartshop.api
local util = smartshop.util

local check_shop_add = util.check_shop_add_remainder
local check_shop_removed = util.check_shop_remove_remainder
local check_player_add = util.check_player_add_remainder
local check_player_removed = util.check_player_remove_remainder
local pairs_by_value = util.pairs_by_value

smartshop.currency = {}
local currency = smartshop.currency

local known_currency = {
    -- standard currency
    ["currency:minegeld_cent_5"]=5,
    ["currency:minegeld_cent_10"]=10,
    ["currency:minegeld_cent_25"]=25,
    ["currency:minegeld"]=100,
    ["currency:minegeld_2"]=200,
    ["currency:minegeld_5"]=500,
    ["currency:minegeld_10"]=1000,
    ["currency:minegeld_20"]=2000,
    ["currency:minegeld_50"]=5000,
    ["currency:minegeld_100"]=10000,

    -- tunneler's abyss
    ["currency:cent_1"]=1,
    ["currency:cent_2"]=2,
    ["currency:cent_5"]=5,
    ["currency:cent_10"]=10,
    ["currency:cent_20"]=20,
    ["currency:cent_50"]=50,
    ["currency:buck_1"]=100,
    ["currency:buck_2"]=200,
    ["currency:buck_5"]=500,
    ["currency:buck_10"]=1000,
    ["currency:buck_20"]=2000,
    ["currency:buck_50"]=5000,
    ["currency:buck_100"]=10000,
    ["currency:buck_200"]=20000,
    ["currency:buck_500"]=50000,
    ["currency:buck_1000"]=100000,

    -- for testing code
    ["smartshop:currency_1"]=1,
    ["smartshop:currency_2"]=2,
    ["smartshop:currency_5"]=5,
    ["smartshop:currency_10"]=10,
    ["smartshop:currency_20"]=20,
    ["smartshop:currency_50"]=50,
    ["smartshop:currency_100"]=100,
}

function currency.register_currency(name, value)
    if minetest.registered_items[name] then
        currency.available_currency[name] = value
        smartshop.log("action", "available currency: %s=%q", name, tostring(value))
    end
end

currency.available_currency = {}
for name, value in pairs(known_currency) do
	currency.register_currency(name, value)
end

local decreasing_values = {}
for name, value in pairs_by_value(currency.available_currency, function(a, b) return b < a end) do
	table.insert(decreasing_values, {name, value})
end

local stack_sizes = {}
for name, _ in pairs(currency.available_currency) do
	stack_sizes[name] = ItemStack(name):get_stack_max()
end

local function sum_stack(stack)
    local name = stack:get_name()
    local count = stack:get_count()
    local value = currency.available_currency[name] or 0
    return value * count
end

local function is_currency(stack)
	local name
	if type(stack) == "string" then
		name = stack
	else
		name = stack:get_name()
	end
    return currency.available_currency[name]
end

local function sort_currency_counts(a, b)
    return currency.available_currency[a[1]] < currency.available_currency[b[1]]
end

function currency.room_for_item(inv, stack, kind)
	return inv:room_for_item(stack, kind)
end

function currency.add_item(inv, stack, kind)
	return inv:add_item(stack, kind)
end

local function get_change_stacks(value)
	for _, currency_value in ipairs(decreasing_values) do
		local name, c_value = unpack(currency_value)
		if value % c_value == 0 then
			local change_stacks = {}
			local count_required = value / c_value
			local stack_max = stack_sizes[name]

			if stack_max < count_required then
				local num_full_stacks = math.floor(count_required / stack_max)
				local remainder = count_required % stack_max
				for _ = 1, num_full_stacks do
					local change_stack = ItemStack(name)
					change_stack:set_count(stack_max)
					table.insert(change_stack)
				end
				local change_stack = ItemStack(name)
				change_stack:set_count(remainder)
				table.insert(change_stack)
			else
				local change_stack = ItemStack(name)
				change_stack:set_count(count_required)
				table.insert(change_stacks, change_stack)
			end

			return change_stacks
		end
	end
end

function currency.contains_item(inv, stack, kind)
	local tmp_inv = inv:get_tmp_inv()
	local removed = currency.remove_item(tmp_inv, stack, kind)
	local contains_item = removed:to_string() == stack:to_string()
	inv:destroy_tmp_inv(tmp_inv)
	return contains_item
end

local function get_currency_counts(inv, kind)
	local currency_counts = {}
	local all_counts = inv:get_all_counts(kind)
	for item, count in pairs(all_counts) do
		if is_currency(item) then
			table.insert(currency_counts, {item, count})
		end
	end
	table.sort(currency_counts, sort_currency_counts)
	return currency_counts
end

local function remove_small_bills(inv, kind, currency_counts, owed_value, removed_items)
	-- remove small bills
	local name_to_break  -- name of bill to break, if value is left over
	for _, currency_count in ipairs(currency_counts) do
		local name, count = unpack(currency_count)
		local value = currency.available_currency[name]
		local count_to_remove = math.min(count, math.floor(owed_value / value))
		if count_to_remove == 0 then
			name_to_break = name
			break
		end

		local stack_to_remove = ItemStack(name)
		stack_to_remove:set_count(count_to_remove)
		table.insert(removed_items, inv:remove_item(stack_to_remove, kind))
		owed_value = owed_value - (count_to_remove * value)
	end

	return name_to_break, owed_value
end

local function try_to_change(inv, kind, name_to_break, owed_value, removed_items)
	local stack_to_break = ItemStack(name_to_break)

	table.insert(removed_items, inv:remove_item(stack_to_break, kind))
	local value = currency.available_currency[name_to_break]

	local change_stacks = get_change_stacks(value - owed_value)
	if not change_stacks then
		return true
	end

	-- try adding the change to the inventory
	local num_stacks_processed = 0
	for _, change_stack in ipairs(change_stacks) do
		local remainder = inv:add_item(change_stack, kind)

		if not remainder:is_empty() then
			-- failed to fit full change stack, we've got to undo inventory changes now
			local partial_change_stack = ItemStack(change_stack:get_name())
			partial_change_stack:set_count(change_stack:get_count() - remainder:get_count())
			inv:remove_item(partial_change_stack, kind)
			break
		end

		num_stacks_processed = num_stacks_processed + 1
	end

	if num_stacks_processed ~= #change_stacks then
		-- changing failed, remove any change that was already added
		for i = 1, num_stacks_processed do
			inv:remove_item(change_stacks[i], kind)
		end

		return true
	end

	return false
end

function currency.remove_item(inv, stack, kind)
	-- do the simple thing if possible
	if inv:contains_item(stack, kind) then
		return inv:remove_item(stack, kind)
	end
	-- here be dragons
	local owed_value = sum_stack(stack)
	local removed_items = {}

	-- remove any relevant denominations
	do
		local removed = inv:remove_item(stack, kind)
		local removed_value = sum_stack(removed)
		owed_value = owed_value - removed_value
		if not removed:is_empty() then
			table.insert(removed_items, removed)
		end
	end

	-- see what's in the player's inventory
	local currency_counts = get_currency_counts(inv, kind)

	local name_to_break
	name_to_break, owed_value = remove_small_bills(inv, kind, currency_counts, owed_value, removed_items)

	local change_failed = false
	if owed_value > 0 then
		-- break the next largest bill
		if not name_to_break then
			change_failed = true
		else
			change_failed = try_to_change(inv, kind, name_to_break, owed_value, removed_items)
		end
	end

	-- if we failed, put stuff back
	if change_failed then
		for _, removed_item in ipairs(removed_items) do
			inv:add_item(removed_item, kind)
		end
		return ItemStack()
	end

	return ItemStack(stack)
end


api.register_purchase_mechanic({
	name = "smartshop:currency",
	allow_purchase = function(player, shop, i)
		local player_inv = api.get_player_inv(player)

		local pay_stack = shop:get_pay_stack(i)
		local give_stack = shop:get_give_stack(i)

		if not (is_currency(pay_stack) or is_currency(give_stack)) then
			return
		end

		local tmp_shop_inv = shop:get_tmp_inv()
		local tmp_player_inv = player_inv:get_tmp_inv()

		local success = true
		local player_removed, shop_removed

		if is_currency(pay_stack) then
			player_removed = currency.remove_item(tmp_player_inv, pay_stack, "pay")
			success = success and not player_removed:is_empty()
		else
			local count = pay_stack:get_count()
			player_removed = tmp_player_inv:remove_item(pay_stack, "pay")
			success = success and (count == player_removed:get_count())
		end

		if is_currency(give_stack) then
			shop_removed = currency.remove_item(tmp_shop_inv, give_stack, "give")
			success = success and not shop_removed:is_empty()
		else
			local count = give_stack:get_count()
			shop_removed = tmp_shop_inv:remove_item(give_stack, "give")
			success = success and (count == shop_removed:get_count())
		end

		if is_currency(pay_stack) then
			local shop_remaining = currency.add_item(tmp_shop_inv, player_removed, "pay")
			success = success and shop_remaining:is_empty()
		else
			local shop_remaining = tmp_shop_inv:add_item(player_removed, "pay")
			success = success and shop_remaining:is_empty()
		end

		if is_currency(give_stack) then
			local player_remaining = currency.add_item(tmp_player_inv, shop_removed, "give")
			success = success and player_remaining:is_empty()
		else
			local player_remaining = tmp_player_inv:add_item(shop_removed, "give")
			success = success and player_remaining:is_empty()
		end

	    shop:destroy_tmp_inv(tmp_shop_inv)
		player_inv:destroy_tmp_inv(tmp_player_inv)

		return success
	end,
	do_purchase = function(player, shop, i)
		local player_inv = api.get_player_inv(player)

		local pay_stack = shop:get_pay_stack(i)
		local give_stack = shop:get_give_stack(i)

		local shop_removed
		local shop_remaining
		local player_removed
		local player_remaining

		if is_currency(pay_stack) then
			player_removed = currency.remove_item(player_inv, pay_stack, "pay")
		else
			player_removed = player_inv:remove_item(pay_stack, "pay")
		end

		if is_currency(give_stack) then
			shop_removed = currency.remove_item(shop, give_stack, "give")
		else
			shop_removed = shop:remove_item(give_stack, "give")
		end

		if is_currency(pay_stack) then
			shop_remaining = currency.add_item(shop, player_removed, "pay")
		else
			shop_remaining = shop:add_item(player_removed, "pay")
		end

		if is_currency(give_stack) then
			player_remaining = currency.add_item(player_inv, shop_removed, "give")
		else
			player_remaining = player_inv:add_item(shop_removed, "give")
		end

		check_shop_removed(shop, shop_removed, give_stack)
		check_player_removed(player_inv, shop, player_removed, pay_stack)
		check_player_add(player_inv, shop, player_remaining)
		check_shop_add(shop, shop_remaining)
	end,
})
