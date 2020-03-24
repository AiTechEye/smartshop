local Amount = {}
Amount.__index = Amount
local AmountMeta = {}

function AmountMeta:__call(whole, cents)
    local amount = setmetatable({}, Amount)
    amount.whole = whole or 0
    amount.cents = cents or 0
    return amount
end

setmetatable(Amount, AmountMeta)

function Amount:to_cents()
    return self.whole * 100 + self.cents
end

function Amount.from_cents(cents)
    return Amount(math.floor(cents / 100), cents % 100)
end

function Amount.__add(arg1, arg2)
    local whole = arg1.whole + arg2.whole
    local cents = arg1.cents + arg2.cents
    whole = whole + math.floor(cents / 100)
    cents = math.floor(cents % 100)
    return Amount(whole, cents)
end

function Amount.__mul(amount, multiple)
    local whole = amount.whole * multiple
    local cents = amount.cents * multiple
    whole = whole + math.floor(cents / 100)
    cents = math.floor(cents % 100)
    return Amount(whole, cents)
end

function Amount:__tostring()
    return ('%i.%02i'):format(self.whole, self.cents)
end

function Amount.__eq(a, b)
    return a.whole == b.whole and a.cents == b.cents
end

function Amount.__lt(a, b)
    return a.whole < b.whole or (a.whole == b.whole and a.cents < b.cents)
end

function Amount.__le(a, b)
    return a.whole < b.whole or (a.whole == b.whole and a.cents <= b.cents)
end

local zero_minegeld = Amount(0, 0)

local known_currency = {
    ["currency:minegeld_cent_5"]=Amount(0, 5),
    ["currency:minegeld_cent_10"]=Amount(0, 10),
    ["currency:minegeld_cent_25"]=Amount(0, 25),
    ["currency:minegeld"]=Amount(1, 0),
    ["currency:minegeld_2"]=Amount(2, 0),
    ["currency:minegeld_5"]=Amount(5, 0),
    ["currency:minegeld_10"]=Amount(10, 0),
    ["currency:minegeld_20"]=Amount(20, 0),
    ["currency:minegeld_50"]=Amount(50, 0),
    ["currency:minegeld_100"]=Amount(100, 0),
}

local available_currency = {}
for name, amount in pairs(known_currency) do
    if minetest.registered_items[name] then
        available_currency[name] = amount
        smartshop.log("action", "available currency: %s=%q", name, tostring(amount))
    end
end

local function sum_stack(stack)
    local name = stack:get_name()
    local count = stack:get_count()
    local amount = available_currency[name] or zero_minegeld
    return amount * count
end

local function sum_inv(inv, list_name)
    local size = inv:get_size(list_name)
    local total = Amount(0, 0)
    for index = 1, size do
        local stack = inv:get_stack(list_name, index)
        total = total + sum_stack(stack)
    end
    return total
end

function smartshop.is_currency(stack)
    local name = stack:get_name()
    return available_currency[name]
end

local function sort_increasing(currency_name_a, currency_name_b)
    return available_currency[currency_name_a] < available_currency[currency_name_b]
end

local function sort_decreasing(currency_name_a, currency_name_b)
    return available_currency[currency_name_b] < available_currency[currency_name_a]
end

local function get_currency_count_by_name(src_inv, src_list_name)
    local src_counts_by_denomination = {}
    local src_inv_size = src_inv:get_size(src_list_name)
    for index = 1, src_inv_size do
        local src_inv_stack = src_inv:get_stack(src_list_name, index)
        local src_inv_stack_name = src_inv_stack:get_name()
        if available_currency[src_inv_stack_name] then
            src_counts_by_denomination[src_inv_stack_name] = (src_counts_by_denomination[src_inv_stack_name] or 0) + src_inv_stack:get_count()
        end
    end
    return src_counts_by_denomination
end

local function make_change(change_cents)
    -- find the largest denomination that evenly divides change_cents
    local denomination
    local value = 0
    for name, amount in pairs(available_currency) do
        local cents = amount:to_cents()
        if change_cents % cents == 0 and cents > value then
            denomination = name
            value = cents
        end
    end
    if denomination then
        return ItemStack({name=denomination, count=change_cents / value})
    end
end

local function get_whole_counts(currency_count_by_name, pay_amount)
    local currency_to_take = {}
    local remaining_cents  = pay_amount:to_cents()

    for currency_name, count in smartshop.util.pairs_by_keys(currency_count_by_name, sort_decreasing) do
        if remaining_cents == 0 then
            break
        end
        local currency_amount = available_currency[currency_name]
        local currency_cents  = currency_amount:to_cents()
        local required_count  = math.floor(remaining_cents / currency_cents)
        if required_count > 0 then
            local count_to_use = math.min(count, required_count)
            currency_to_take[currency_name] = count_to_use
            remaining_cents = remaining_cents - (currency_cents * count_to_use)

            -- update src_counts_by_denomination
            if count_to_use == count then
                currency_count_by_name[currency_name] = nil
            else
                currency_count_by_name[currency_name] = count - count_to_use
            end
        end
    end
    return currency_to_take, remaining_cents
end

local function get_change_to_give(currency_count_by_name, currency_to_take, remaining_cents)
    -- find the smallest bill that exceeds the amount we need
    local currency_to_use
    for currency_name, _ in smartshop.util.pairs_by_keys(currency_count_by_name, sort_increasing) do
        local currency_amount = available_currency[currency_name]
        local currency_cents  = currency_amount:to_cents()
        if currency_cents >= remaining_cents then
            currency_to_use = currency_name
            break
        end
    end
    if not currency_to_use then
        -- didn't find any currency to use
        return false
    end
    -- update counts
    currency_to_take[currency_to_use]       = (currency_to_take[currency_to_use] or 0) + 1
    currency_count_by_name[currency_to_use] = currency_count_by_name[currency_to_use] - 1
    local change_cents                      = available_currency[currency_to_use]:to_cents() - remaining_cents
    return true, make_change(change_cents)
end

local function get_items_to_take(currency_to_take)
    local items_to_take = {}
    for name, count in pairs(currency_to_take) do
        local stack_to_take = ItemStack({name=name, count=count})
        table.insert(items_to_take, stack_to_take)
    end
    return items_to_take
end

function smartshop.can_exchange_currency(player_inv, shop_inv, send_inv, refill_inv, pay_stack, give_stack, is_unlimited)
    --[[
        This function implements a quick-and-dirty change-making algorithm.
        It can return "false" when change-making is actually technically possible,
        but the "correct" algorithm is NP-hard (and even more complicated than this mess).

        pay_stack is assumed to be valid currency. It is also assumed that a check of
        whether the player had the exact payment was done before calling this method.

        If currency can be moved, it returns true, and a list of stacks to remove from the source
        inventory, and a stack (or nil) of change to add to the player's inventory

        Note: The shop inventory will always get the exact pay_stack requested.
    ]]--
    local pay_amount = sum_stack(pay_stack)
    if pay_amount > sum_inv(player_inv, "main") then
        -- quick check: does the person even have enough money?
        return false, nil, nil, "you lack sufficient payment"
    end

    -- count up the currency in the source inv
    local currency_count_by_name = get_currency_count_by_name(player_inv, "main")

    -- take as much of the source money as possible, without breaking bills or going over the required amount
    local currency_to_take, remaining_cents = get_whole_counts(currency_count_by_name, pay_amount)

    local change_to_give
    if remaining_cents ~= 0 then
        local made_change
        made_change, change_to_give = get_change_to_give(currency_count_by_name, currency_to_take, remaining_cents)
        if not made_change then
            return false, nil, nil, "failed to make change: no bill large enough"
        elseif not change_to_give then
            -- can't make change for some reason? should always be possible
            return false, nil, nil, "failed to make change"
        end
        remaining_cents = 0
    end

    local items_to_take   = get_items_to_take(currency_to_take)

    -- create a temporary copy of the src_inv to check that we can take the determined bills, give change, and still give the exchanged item
    local player_inv_copy = smartshop.util.clone_tmp_inventory("smartshop_tmp_player_inv", player_inv, "main")
    local function helper()
        for _, item_stack in ipairs(items_to_take) do
            local removed = player_inv_copy:remove_item("main", item_stack)
            if removed:get_count() ~= item_stack:get_count() then
                return false, "unknown error"
            end
        end
        if change_to_give then
            local leftover = player_inv_copy:add_item("main", change_to_give)
            if leftover:get_count() ~= 0 then
                return false, "cannot change currency: no room in inventory for change"
            end
        end
        -- is there still room in the inventory for the acquired item?
        local leftover = player_inv_copy:add_item("main", give_stack)
        if leftover:get_count() ~= 0 then
            return false, "cannot change currency: no room in inventory for purchased item"
        end
        return true
    end
    local rv, message = helper()
    smartshop.util.delete_tmp_inventory("smartshop_tmp_player_inv")
    if not rv then
        return rv, nil, nil, message
    end

    if not is_unlimited then
        local shop_inv_copy = smartshop.util.clone_tmp_inventory("smartshop_tmp_shop_inv", shop_inv, "main")
        local send_inv_copy = send_inv and smartshop.util.clone_tmp_inventory("smartshop_tmp_send_inv", send_inv, "main")
        local refill_inv_copy = refill_inv and smartshop.util.clone_tmp_inventory("smartshop_tmp_refill_inv", refill_inv, "main")

        function helper()
            local sold_thing
			if refill_inv_copy then
				sold_thing = refill_inv_copy:remove_item("main", give_stack)
				local sold_count = sold_thing:get_count()
				local still_need = give_stack:get_count() - sold_count
				if still_need ~= 0 then
					sold_thing = shop_inv_copy:remove_item("main", {name = give_stack:get_name(), count = still_need})
					sold_thing:set_count(sold_thing:get_count() + sold_count)
				end
			else
				sold_thing = shop_inv_copy:remove_item("main", give_stack)
			end
            if sold_thing:get_count() < give_stack:get_count() then
				return false, ("%s is sold out"):format(give_stack:to_string())
            end
			local leftover
			if send_inv_copy then
				leftover = send_inv_copy:add_item("main", pay_stack)
				leftover = shop_inv_copy:add_item("main", leftover)
			else
				leftover = shop_inv_copy:add_item("main", pay_stack)
			end
			if not leftover:is_empty() then
				return false, "the shop is full"
			end
            return true
        end
        rv, message = helper()
        smartshop.util.delete_tmp_inventory("smartshop_tmp_shop_inv")
        smartshop.util.delete_tmp_inventory("smartshop_tmp_send_inv")
        smartshop.util.delete_tmp_inventory("smartshop_tmp_refill_inv")
        if not rv then
            return rv, nil, nil, message
        end
    end

    return true, items_to_take, change_to_give
end

function smartshop.exchange_currency(player_inv, shop_inv, send_inv, refill_inv, items_to_take, item_to_give, pay_stack, give_stack, is_unlimited)
	if is_unlimited then
        for _, item_to_take in pairs(items_to_take) do
            local removed = player_inv:remove_item("main", item_to_take)
            if removed:get_count() < item_to_take:get_count() then
                smartshop.log("error", "(ec) failed to extract full payment using creative shop (missing: %s)", removed:to_string())
            end
        end
		local leftover = player_inv:add_item("main", item_to_give)
		if not leftover:is_empty() then
			smartshop.log("error", "(ec) player did not receive full *change* amount when using creative shop (leftover: %s)", leftover:to_string())
		end
        leftover = player_inv:add_item("main", give_stack)
		if not leftover:is_empty() then
			smartshop.log("error", "(ec) player did not receive full amount when using creative shop (leftover: %s)", leftover:to_string())
		end
	else
        for _, item_to_take in pairs(items_to_take) do
            local payment    = player_inv:remove_item("main", item_to_take)
            if payment:get_count() < item_to_take:get_count() then
                smartshop.log("error", "(ec) failed to extract full purchase from shop (missing: %s)", payment:to_string())
            end
        end
		local sold_thing
		if refill_inv then
			sold_thing = refill_inv:remove_item("main", give_stack)
			local sold_count = sold_thing:get_count()
			local still_need = give_stack:get_count() - sold_count
			if still_need ~= 0 then
				sold_thing = shop_inv:remove_item("main", {name = give_stack:get_name(), count = still_need})
				sold_thing:set_count(sold_thing:get_count() + sold_count)
			end
		else
			sold_thing = shop_inv:remove_item("main", give_stack)
		end
		local leftover   = player_inv:add_item("main", sold_thing)
		if not leftover:is_empty() then
			smartshop.log("error", "(ec) player did not receive full amount from shop (leftover: %s)", leftover:to_string())
		end
        leftover   = player_inv:add_item("main", item_to_give)
		if not leftover:is_empty() then
			smartshop.log("error", "(ec) player did not receive full *change* amount (leftover: %s)", leftover:to_string())
		end
		if send_inv then
			leftover = send_inv:add_item("main", pay_stack)
			leftover = shop_inv:add_item("main", leftover)
		else
			leftover = shop_inv:add_item("main", pay_stack)
		end
		if not leftover:is_empty() then
			smartshop.log("error", "(ec) shop did not receive full payment (leftover: %s)", leftover:to_string())
		end
	end
end
