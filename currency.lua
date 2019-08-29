-- collect up available minegeld amounts

local Amount = {}
Amount.__index = Amount

function Amount.__call(whole, cents)
    local self = setmetatable({}, Amount)
    self.whole = whole or 0
    self.cents = cents or 0
    return self
end

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

function Amount:as_integer()
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

function smartshop.can_move_currency(src_currency_stack, src_inv, src_list_name, dest_inv, dest_list_name)
    --[[
        before this function: just check if the exchange can be done normally
        1. sum up the currency
        2. check if the src_inv has enough money total to do the exchange
            a. if not, return
        3.
        4.

    ]]--
    if not src_list_name then src_list_name = "main" end
    if not dest_list_name then dest_list_name = "main" end
    local stack_amount = sum_stack(src_currency_stack)
    local src_inv_amount = sum_inv(src_inv, src_list_name)
    if stack_amount > src_inv_amount then return end



    local src_counts_by_denomination = {}
    local src_inv_size = src_inv:get_size(src_list_name)
    for index = 1, src_inv_size do
        local src_inv_stack = src_inv:get_stack(src_list_name, index)
        local src_inv_stack_name = src_inv_stack:get_name()
        if available_currency[src_inv_stack_name] then
            src_counts_by_denomination[src_inv_stack_name] = (src_counts_by_denomination[src_inv_stack_name] or 0) + src_inv_stack:count()
        end
    end

    local currency_to_exchange = {}
    local remaining_cost = smartshop.util.deep_copy(stack_amount)

    for name, count in smartshop.util.pairs_by_keys(src_counts_by_denomination, function() end) do
    end

    --[[
    start w/ the largest available currency C.. take N = floor(cost / C) of them. update remaining cost.
    check next smallest amount.
    ]]--


\end
