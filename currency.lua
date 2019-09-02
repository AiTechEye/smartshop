-- collect up available minegeld amounts

local Amount = {}
local AmountMeta = {}

function AmountMeta.__call(whole, cents)
    local amount = setmetatable({}, Amount)
    amount.whole = whole or 0
    amount.cents = cents or 0
    return amount
end

function Amount.from_cents(cents)
    return Amount(math.floor(cents / 100), cents % 100)
end

setmetatable(Amount, AmountMeta)

function Amount.__add(arg1, arg2)
    local whole = arg1.whole + arg2.whole
    local cents = arg1.cents + arg2.cents
    whole = whole + math.floor(cents / 100)
    cents = cents % 100
    return Amount(whole, cents)
end

function Amount.__mul(amount, multiple)
    local whole = amount.whole * multiple
    local cents = amount.cents * multiple
    whole = whole + math.floor(cents / 100)
    cents = cents % 100
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

function Amount:to_cents()
    return self.whole * 100 + self.cents
end

function Amount:divides(other)
    local i = self:as_integer()
    local j = other:as_integer()
    return (j % i) == 0
end



local known_currency = {
    ["currency:minegeld_cent_5"]=Amount(0, 5),
    ["currency:minegeld_cent_10"]=Amount(0, 10),
    ["currency:minegeld_cent_25"]=Amount(0, 25),
    ["currency:minegeld"]=Amount(1, 0),
    ["currency:minegeld_5"]=Amount(5, 0),
    ["currency:minegeld_10"]=Amount(10, 0),
    ["currency:minegeld_50"]=Amount(50, 0),
    ["currency:minegeld_100"]=Amount(100, 0),
}

local available_currency = {}
for name, value in pairs(known_currency) do
    if minetest.registered_items[known] then
        available_currency[name] = value
    end
end

local function sum_stack(stack)
    local name = stack:get_name()
    local count = stack:get_count()
    local amount = available_currency[name]
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

local function get_src_counts_by_denomination(src_inv, src_list_name)
    local src_counts_by_denomination = {}
    local src_inv_size = src_inv:get_size(src_list_name)
    for index = 1, src_inv_size do
        local src_inv_stack = src_inv:get_stack(src_list_name, index)
        local src_inv_stack_name = src_inv_stack:get_name()
        if available_currency[src_inv_stack_name] then
            src_counts_by_denomination[src_inv_stack_name] = (src_counts_by_denomination[src_inv_stack_name] or 0) + src_inv_stack:count()
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
        end
    end
    if denomination then
        return ItemStack({name=denomination, count=change_cents / cents})
    end
end

function smartshop.can_move_currency(currency_stack, src_inv, src_list_name, trade_stack)
    --[[
        This function implements a quick-and-dirty change-making algorithm.
        It can return "false" when change-making is actually technically possible,
        but the "correct" algorithm is NP-hard.

        If currency can be moved, it returns true, and a list of stacks to remove from the source
        inventory, and a stack (or nil) to add to the source inventory

        Note: The dest inventory will always get the src_currency_stack, and that is handled
        outside (after) this function
    ]]--
    if not src_list_name then src_list_name = "main" end
    local stack_amount = sum_stack(currency_stack)
    if stack_amount > sum_inv(src_inv, src_list_name) then
        -- quick check: does the person even have enough money?
        smartshop.log("action", "cannot change currency: player doesn't have enough money") -- TODO remove debug
        return false
    end

    -- count up the currency in the source inv
    local src_counts_by_denomination = get_src_counts_by_denomination(src_inv, src_list_name)

    -- take as much of the source money as possible, without breaking bills or going over the required amount
    local currency_to_take = {}
    local remaining_cents = stack_amount:to_cents()
    for currency_name, count in smartshop.util.pairs_by_keys(src_counts_by_denomination, sort_decreasing) do
        if remaining_cents == 0 then
            break
        end
        local currency_amount = available_currency[currency_name]
        local currency_cents  = currency_amount
        local required_count  = math.floor(remaining_cents / currency_cents)
        if required_count > 0 then
            local count_to_use = math.min(count, required_count)
            currency_to_take[currency_name] = count_to_use
            remaining_cents = remaining_cents - (currency_cents * count_to_use)

            -- update src_counts_by_denomination
            if count_to_use == count then
                src_counts_by_denomination[currency_name] = nil
            else
                src_counts_by_denomination[currency_name] = count - count_to_use
            end
        end
    end

    local item_to_give
    if remaining_cents ~= 0 then
        -- we still need to make up some value; try to break some bills

        -- find the smallest bill that exceeds the amount we need
        local currency_to_use
        for currency_name, _ in smartshop.util.pairs_by_keys(src_counts_by_denomination, sort_decreasing) do
            local currency_amount = available_currency[currency_name]
            local currency_cents  = currency_amount
            if currency_cents >= remaining_cents then
                currency_to_use = currency_name
                break
            end
        end

        -- didn't find any currency to use
        if not currency_to_use then
            smartshop.log("action", "cannot change currency: could not find bill to break") -- TODO remove debug
            return false
        end
        currency_to_take[currency_to_use] = currency_to_take[currency_to_use] + 1
        available_currency[currency_to_use] = available_currency[currency_to_use] - 1

        local change_cents = available_currency[currency_to_use]:to_cents() - remaining_cents
        remaining_cents = 0
        item_to_give = make_change(change_cents)

        -- can't make change for some reason? should always be possible
        if not item_to_give then
            smartshop.log("action", "cannot change currency: couldn't make change") -- TODO remove debug
            return false
        end
    end

    local items_to_take = {}
    for name, count in pairs(currency_to_take) do
        table.insert(items_to_take, ItemStack(name, count))
    end

    -- create a temporary copy of the src_inv to check that we can take the determined bills, give change, and still give the exchanged item
    local src_inv_copy = minetest.create_detached_inventory("smartshop_tmp_src_inv", {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) return count end,
        allow_put = function(inv, listname, index, stack, player) return stack:get_size() end,
        allow_take = function(inv, listname, index, stack, player) return stack:get_size() end,
    })
    src_inv_copy:set_size(src_list_name, src_inv:get_size(src_list_name))
    src_inv_copy:set_list(src_list_name, src_inv:get_list(src_list_name))

    for _, item_stack in ipairs(items_to_take) do
        local removed = src_inv_copy:remove_item(src_list_name, item_stack)
        if removed:get_size() ~= item_stack:get_size() then
            smartshop.log("action", "cannot change currency: algorithm error: can't find items to remove from tmp inventory...") -- TODO remove debug
            return false
        end
    end

    if item_to_give then
        local leftover = src_inv_copy:add_item(src_list_name, item_to_give)
        if leftover:get_size() ~= 0 then
            smartshop.log("action", "cannot change currency: no room in inventory for change") -- TODO remove debug
            return false
        end
    end

    -- is there still room in the inventory for the acquired item?
    local leftover = src_inv_copy:add_item(src_list_name, trade_stack)
    if leftover:get_size() ~= 0 then
        smartshop.log("action", "cannot change currency: no room in inventory for purchased item") -- TODO remove debug
        return false
    end

    minetest.remove_detached_inventory("smartshop_tmp_src_inv")

    return true, items_to_take, item_to_give
end
