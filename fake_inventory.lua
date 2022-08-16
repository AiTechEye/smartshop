local class = smartshop.util.class

local fake_inventory = class()

function fake_inventory:_init()
	self._lists = {}
end

function fake_inventory:is_empty(listname)
	local list = self._lists[listname]
	return not list or #list == 0
end

function fake_inventory:get_size(listname)
	local list = self._lists[listname]
	return list and #list or 0
end

function fake_inventory:set_size(listname, size)
	if size == 0 then
		self._lists[listname] = nil
		return
	end

	local list = self._lists[listname] or {}

	if #list < size then
		for _ = #list + 1, size do
			table.insert(list, ItemStack(""))
		end

	elseif #list > size then
		for _ = #list, size + 1, -1 do
			table.remove(list)
		end
	end

	self._lists[listname] = list
end

function fake_inventory:get_stack(listname, i)
	local list = self._lists[listname]
	if not list or i > #list then
		return ItemStack()
	end
	return ItemStack(list[i])
end

function fake_inventory:set_stack(listname, i, stack)
	local list = self._lists[listname]
	if not list or i > #list then
		return
	end
	list[i] = ItemStack(stack)
end

function fake_inventory:get_list(listname)
	local list = self._lists[listname]
	if not list then
		return
	end
	local stacks = {}
	for _, stack in ipairs(list) do
		table.insert(stacks, ItemStack(stack))
	end
	return stacks
end

function fake_inventory:set_list(listname, list)
	local ourlist = self._lists[listname]
	if not ourlist then
		return
	end

	for i = 1, math.min(#ourlist, #list) do
		ourlist[i] = ItemStack(list[i])
	end
end

function fake_inventory:get_lists()
	local lists = {}
	for listname in pairs(self._lists) do
		lists[listname] = self:get_list(listname)
	end
	return lists
end

function fake_inventory:set_lists(lists)
	for listname, list in pairs(lists) do
		self:set_list(listname, list)
	end
end

-- add item somewhere in list, returns leftover `ItemStack`.
function fake_inventory:add_item(listname, stack)
	local list = self._lists[listname]
	stack = ItemStack(stack)
	if not list then
		return stack
	end

	for _, our_stack in ipairs(list) do
		stack = our_stack:add_item(stack)
		if stack:is_empty() then
			break
		end
	end

	return stack
end

-- returns `true` if the stack of items can be fully added to the list
function fake_inventory:room_for_item(listname, stack)
	local list = self._lists[listname]
	if not list then
		return false
	end

	stack = ItemStack(stack)
	local copy = table.copy(list)
	for _, our_stack in ipairs(copy) do
		stack = our_stack:add_item(stack)
		if stack:is_empty() then
			break
		end
	end

	return stack:is_empty()
end

-- take as many items as specified from the list, returns the items that were actually removed (as an `ItemStack`)
-- note that any item metadata is ignored, so attempting to remove a specific unique item this way will likely remove
-- the wrong one -- to do that use `set_stack` with an empty `ItemStack`.
function fake_inventory:remove_item(listname, stack)
	local removed = ItemStack()
	stack = ItemStack(stack)

	local list = self._lists[listname]
	if not list or stack:is_empty() then
		return removed
	end

	local name = stack:get_name()
	local count_remaining = stack:get_count()
	local taken = 0

	for _, our_stack in ipairs(list) do
		if our_stack:get_name() == name then
			local n = our_stack:take_item(count_remaining):get_count()
			count_remaining = count_remaining - n
			taken = taken + n
		end

		if count_remaining == 0 then
			break
		end
	end

	stack:set_count(taken)

	return stack
end

-- returns `true` if the stack of items can be fully taken from the list.
-- If `match_meta` is false, only the items' names are compared (default: `false`).
function fake_inventory:contains_item(listname, stack, match_meta)
	local list = self._lists[listname]
	if not list then
		return false
	end

	stack = ItemStack(stack)

	if match_meta then
		local name = stack:get_name()
		local wear = stack:get_wear()
		local meta = stack:get_meta()
		local needed_count = stack:get_count()

		for _, our_stack in ipairs(list) do
			if our_stack:get_name() == name and our_stack:get_wear() == wear and our_stack:get_meta():equals(meta) then
				local n = our_stack:peek_item(needed_count):get_count()
				needed_count = needed_count - n
			end
			if needed_count == 0 then
				break
			end
		end

		return needed_count == 0

	else
		local name = stack:get_name()
		local needed_count = stack:get_count()

		for _, our_stack in ipairs(list) do
			if our_stack:get_name() == name then
				local n = our_stack:peek_item(needed_count):get_count()
				needed_count = needed_count - n
			end
			if needed_count == 0 then
				break
			end
		end

		return needed_count == 0
	end
end

function smartshop.util.clone_fake_inventory(src_inv)
	local fake_inv = fake_inventory()

	fake_inv:set_size("main", src_inv:get_size("main"))
	fake_inv:set_list("main", src_inv:get_list("main"))

	return fake_inv
end

smartshop.fake_inventory = fake_inventory
