-- collect up available minegeld amounts

function smartshop.can_move_currency(currency_stack, src_inv, dest_inv, src_inv_name, dest_inv_name)
    --[[
        before this function: just check if the exchange can be done normally
        1. sum up the currency
        2. check if the src_inv has enough money total to do the exchange
            a. if not, return
        3. check if transaction can be done w/out breaking any bills
        4.

    ]]--
    if not src_inv_name then src_inv_name = "main" end
    if not dest_inv_name then dest_inv_name = "main" end
end
