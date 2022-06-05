local create_detached_inventory = minetest.create_detached_inventory

local error_behavior = smartshop.settings.error_behavior

smartshop.util = {}
local util = smartshop.util

function util.error(messagefmt, ...)
	local message = messagefmt:format(...)

	if error_behavior == "crash" then
		error(message)

	elseif error_behavior == "announce" then
		minetest.chat_send_all(message)
	end

	smartshop.log("error", message)
end

function util.string_to_pos(pos_as_string)
	-- can't just use minetest.string_to_pos, for sake of backward compatibility
	if not pos_as_string or type(pos_as_string) ~= "string" then
		return nil
	end
	local x, y, z = pos_as_string:match("^%s*%(?%s*(%-?%d+)[%s,]+(%-?%d+)[%s,]+(%-?%d+)%s*%)?%s*$")
	if x and y and z then
		return vector.new(tonumber(x), tonumber(y), tonumber(z))
	end
end

function util.formspec_pos(pos)
	return ("%i,%i,%i"):format(pos.x, pos.y, pos.z)
end

function util.player_is_admin(player_or_name)
	return minetest.check_player_privs(player_or_name, {[smartshop.settings.admin_shop_priv] = true})
end

function util.table_is_empty(t)
	return not next(t)
end

function util.pairs_by_value(t, sort_function)
	if not sort_function then
		sort_function = function(a, b)
			return a < b
		end
	end
	local s = {}
	for k, v in pairs(t) do
		table.insert(s, {k, v})
	end
	table.sort(s, function(a, b)
		return sort_function(a[2], b[2])
	end)
	local i = 0
	return function()
		i = i + 1
		local v = s[i]
		if v then
			return unpack(v)
		else
			return nil
		end
	end
end

function util.check_shop_add_remainder(shop, remainder)
	if remainder:is_empty() then
		return false
	end

	local owner = shop:get_owner()
	local pos_as_string = shop:get_pos_as_string()

	util.error("ERROR: %s's smartshop @ %s lost %q while adding", owner, pos_as_string, remainder:to_string())

	return true
end

function util.check_shop_remove_remainder(shop, remainder, expected)
	if remainder:get_count() == expected:get_count() then
		return false
	end

	local owner = shop:get_owner()
	local pos_as_string = shop:get_pos_as_string()

	util.error("ERROR: %s's smartshop @ %s lost %q of %q while removing",
		owner, pos_as_string, remainder:to_string(), expected:to_string())

	return true
end

function util.check_player_add_remainder(player_inv, shop, remainder)
	if remainder:get_count() == 0 then
		return false
	end

	local player_name = player_inv.name

	util.error("ERROR: %s lost %q on add using %'s shop @ %s",
		player_name, remainder:to_string(), shop:get_owner(), shop:get_pos_as_string())

	return true
end

function util.check_player_remove_remainder(player_inv, shop, remainder, expected)
	if remainder:get_count() == expected:get_count() then
		return false
	end

	local player_name = player_inv.name

	util.error("ERROR: %s lost %q of %q on remove from %'s shop @ %s",
		player_name, remainder:to_string(), expected:to_string(), shop:get_owner(), shop:get_pos_as_string())

	return true
end

function util.table_size(t)
	local size = 0
	for _ in pairs(t) do
		size = size + 1
	end
	return size
end

local table_size = util.table_size

function util.equals(a, b)
	local t = type(a)
	if t ~= type(b) then
		return false
	end
	if t ~= "table" then
		return a == b
	else
		local size_a = 0
		for key, value in pairs(a) do
			if not util.equals(value, b[key]) then
				return false
			end
			size_a = size_a + 1
		end
		return size_a == table_size(b)
	end
end

local equals = util.equals

function util.remove_stack_with_meta(inv, list_name, stack)
	local stack_name = stack:get_name()
	local stack_count = stack:get_count()
	local stack_wear = stack:get_wear()
	local stack_meta = stack:get_meta():to_table()
	local list_table = inv:get_list(list_name)

	for _, i_stack in ipairs(list_table) do
		local i_name = i_stack:get_name()
		local i_count = i_stack:get_count()
		local i_wear = i_stack:get_wear()
		local i_meta = i_stack:get_meta():to_table()
		if stack_name == i_name and stack_wear == i_wear and equals(stack_meta, i_meta) then
			if i_count >= stack_count then
				i_count = i_count - stack_count
				stack_count = 0
				i_stack:set_count(i_count)
				break
			else
				stack_count = stack_count - i_count
				i_stack:clear(0)
			end
		end
	end

	inv:set_list(list_name, list_table)

	-- returns the items that were actually removed
	local removed = ItemStack(stack)
	removed:set_count(stack:get_count() - stack_count)
	return removed
end

function util.get_stack_key(stack, match_meta)
	if match_meta then
		local key_stack = ItemStack(stack) -- clone
		key_stack:set_count(1)
		return key_stack:to_string()
	else
		return stack:get_name()
	end
end

function util.clone_tmp_inventory(inv_name, src_inv)
	local tmp_inv = create_detached_inventory(inv_name, {})

	for name, _ in pairs(src_inv:get_lists()) do
		if not tmp_inv:is_empty(name) or tmp_inv:get_size(name) ~= 0 then
			util.error("attempt to re-use existing temporary inventory %s", inv_name)
			return
		end
	end

	for name, list in pairs(src_inv:get_lists()) do
		tmp_inv:set_size(name, src_inv:get_size(name))
		tmp_inv:set_list(name, list)
	end

	return tmp_inv
end

function util.class(super)
    local class = {}
	class.__index = class

	if super then
		setmetatable(class, {__index = super})
	end

    function class:new(...)
        local obj = setmetatable({}, class)
        if obj.__new then
            obj:__new(...)
        end
        return obj
    end

    return class
end

-- https://github.com/minetest/minetest/blob/9fc018ded10225589d2559d24a5db739e891fb31/doc/lua_api.txt#L453-L462
function util.escape_texture(texturestring)
	local v = texturestring:gsub("%^", "\\^"):gsub(":", "\\:")
	return v
end
