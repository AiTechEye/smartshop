--[[
Because this fork turns the "give" and "pay" lines in the shop inventory into
placeholders, and not actual inventory slots, upgrading would cause the items
stored in those slots to be lost.else

If enabled (by default), this LBM will refund those items, even in the event
that the shop is currently full. 
--]]


if smartshop.settings.enable_refund then
    minetest.register_lbm({
        name              = "smartshop:repay_lost_stuff",
        nodenames         = {
            "smartshop:shop",
            "smartshop:shop_empty",
            "smartshop:shop_full",
            "smartshop:shop_used",
        },
        run_at_every_load = true,
        action            = function(pos, node)
            -- refund lost inventory items, or store them for later
            local meta = minetest.get_meta(pos)
            if smartshop.is_creative(meta) then return end
            local inv = smartshop.get_inventory(meta)

            if smartshop.has_upgraded(meta) then
                local unrefunded = {}
                for _, itemstring in ipairs(smartshop.get_refund(meta)) do
                    local itemstack = ItemStack(itemstring)
                    if inv:room_for_item("main", itemstack) then
                        inv:add_item("main", itemstack)
                    else
                        table.insert(unrefunded, itemstack:to_string())
                    end
                end
                if not smartshop.util.table_is_empty(unrefunded) then
                    smartshop.set_refund(meta, unrefunded)
                end

            else
                local unrefunded = {}
                for index = 1, 4 do
                    local pay_stack = inv:get_stack("pay" .. index, 1)
                    if not pay_stack:is_empty() then
                        if inv:room_for_item("main", pay_stack) then
                            inv:add_item("main", pay_stack)
                        else
                            table.insert(unrefunded, pay_stack:to_string())
                        end
                    end
                    local give_stack = inv:get_stack("give" .. index, 1)
                    if not give_stack:is_empty() then
                        if inv:room_for_item("main", give_stack) then
                            inv:add_item("main", give_stack)
                        else
                            table.insert(unrefunded, give_stack:to_string())
                        end
                    end
                end
                if not smartshop.util.table_is_empty(unrefunded) then
                    smartshop.set_refund(meta, unrefunded)
                end
                smartshop.set_upgraded(meta)
            end

        end,
    })
end
