local fake_inventory = smartshop.fake_inventory

smartshop.tests.register_test({
	name = "make sure fake inventory works",
	func = function(player, state)
		local inv = fake_inventory()
		assert(inv:is_empty("main"))
		assert(inv:get_size("main") == 0)
		assert(inv:get_stack("main", 1):is_empty())
		assert(inv:get_list("main") == nil)

		inv:set_size("main", 32)
		assert(inv:room_for_item("main", "smartshop:gold 99"))

		inv:set_stack("main", 1, "smartshop:gold 99")
		assert(inv:contains_item("main", ItemStack("smartshop:gold")))
		assert(inv:contains_item("main", ItemStack("smartshop:gold 99")))
		assert(not inv:contains_item("main", ItemStack("smartshop:gold 100")))

		local s = inv:get_stack("main", 1)
		assert(s:get_name() == "smartshop:gold")
		assert(s:get_count() == 99)

		local removed = inv:remove_item("main", ItemStack("smartshop:gold 99"))

		assert(not inv:contains_item("main", ItemStack("smartshop:gold")))
		assert(removed:get_name() == "smartshop:gold")
		assert(removed:get_count() == 99)

		for _ = 1, 20 do
			inv:add_item("main", ItemStack("smartshop:gold 5"))
		end

		assert(inv:contains_item("main", ItemStack("smartshop:gold 100")))
		inv:remove_item("main", ItemStack("smartshop:gold 100"))


	end,
})
