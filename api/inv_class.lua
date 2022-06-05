
local class = smartshop.util.class
local get_stack_key = smartshop.util.get_stack_key
local remove_stack_with_meta = smartshop.util.remove_stack_with_meta

--------------------

local inv_class = class()
smartshop.inv_class = inv_class

--------------------

function inv_class:__new(inv)
	if type(inv) ~= "userdata" then
		smartshop.util.error("new inventory unexpectedly %s", dump(inv))
	end
	self.inv = inv
end

--------------------

function inv_class:initialize_inventory()
	-- noop
end

--------------------

function inv_class:get_count(stack, match_meta)
	if type(stack) == "string" then
		stack = ItemStack(stack)
	end
	if stack:is_empty() then
		return 0
	end
	local inv = self.inv
	local total = 0

	local key = get_stack_key(stack, match_meta)
	for _, inv_stack in ipairs(inv:get_list("main")) do
		if key == get_stack_key(inv_stack, match_meta) then
			total = total + inv_stack:get_count()
		end
	end

	return math.floor(total / stack:get_count())
end

function inv_class:get_all_counts(match_meta)
	local inv = self.inv
	local all_counts = {}

	for _, stack in ipairs(inv:get_list("main")) do
		local key = get_stack_key(stack, match_meta)
		local count = all_counts[key] or 0
		count = count + stack:get_count()
		all_counts[key] = count
	end

	return all_counts
end

function inv_class:room_for_item(stack)
	return self.inv:room_for_item("main", stack)
end

function inv_class:add_item(stack)
	return self.inv:add_item("main", stack)
end

function inv_class:contains_item(stack, match_meta)
	return self.inv:contains_item("main", stack, match_meta)
end

function inv_class:remove_item(stack, match_meta)
	local inv = self.inv

	local removed
	if match_meta then
		removed = remove_stack_with_meta(inv, "main", stack)

	else
		removed = inv:remove_item("main", stack)
	end

	return removed
end

--------------------

function inv_class:get_tmp_inv()
	return smartshop.tmp_inv_class:new(self.inv)
end

function inv_class:destroy_tmp_inv(tmp_inv)
	tmp_inv:destroy()
end
