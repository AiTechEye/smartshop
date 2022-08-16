local error_behavior = smartshop.settings.error_behavior

local util = {}

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
	return next(t) == nil
end

function util.pairs_by_value(t, sort_function)
	local s = {}
	for k, v in pairs(t) do
		table.insert(s, {k, v})
	end

	if sort_function then
		table.sort(s, function(a, b)
			return sort_function(a[2], b[2])
		end)
	else
		table.sort(s, function(a, b)
			return a[2] < b[2]
		end)
	end

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

function util.class(super)
    local class = {}
	class.__index = class

	local meta = {
		__call = function(_, ...)
	        local obj = setmetatable({}, class)
	        if obj._init then
	            obj:_init(...)
	        end
	        return obj
	    end
	}

	if super then
		meta.__index = super
	end

	setmetatable(class, meta)

    return class
end

-- https://github.com/minetest/minetest/blob/9fc018ded10225589d2559d24a5db739e891fb31/doc/lua_api.txt#L453-L462
function util.escape_texture(texturestring)
	-- store in a variable so we don't return both rvs of gsub
	local v = texturestring:gsub("%^", "\\^"):gsub(":", "\\:")
	return v
end

function util.truncate(s, max_length)
	if s:len() > max_length then
		return s:sub(1, max_length - 3) .. "..."
	else
		return s
	end
end

local function tokenize(s)
	local tokens = {}

	local i = 1
	local j = 1

	while true do
		if s:sub(j, j) == "" then
			if i < j then
				table.insert(tokens, s:sub(i, j - 1))
			end
			return tokens

		elseif s:sub(j, j):byte() == 27 then
			if i < j then
				table.insert(tokens, s:sub(i, j - 1))
			end

			i = j
			local n = s:sub(i + 1, i + 1)

			if n == "(" then
				local m = s:sub(i + 2, i + 2)
				local k = s:find(")", i + 3, true)
				if m == "T" then
					table.insert(tokens, {
						type = "translation",
						domain = s:sub(i + 4, k - 1)
					})

				elseif m == "c" then
					table.insert(tokens, {
						type = "color",
						color = s:sub(i + 4, k - 1),
					})

				elseif m == "b" then
					table.insert(tokens, {
						type = "bgcolor",
						color = s:sub(i + 4, k - 1),
					})

				else
					error(("couldn't parse %s"):format(s))
				end
				i = k + 1
				j = k + 1

			elseif n == "F" then
				table.insert(tokens, {
					type = "start",
				})
				i = j + 2
				j = j + 2

			elseif n == "E" then
				table.insert(tokens, {
					type = "stop",
				})
				i = j + 2
				j = j + 2

			else
				error(("couldn't parse %s"):format(s))
			end

		else
			j = j + 1
		end
	end
end

local function parse(tokens, i, parsed)
	parsed = parsed or {}
	i = i or 1
	while i <= #tokens do
		local token = tokens[i]
		if type(token) == "string" then
			table.insert(parsed, token)
			i = i + 1

		elseif token.type == "color" or token.type == "bgcolor" then
			table.insert(parsed, token)
			i = i + 1

		elseif token.type == "translation" then
			local contents = {
				type = "translation",
				domain = token.domain
			}
			i = i + 1
			contents, i = parse(tokens, i, contents)
			table.insert(parsed, contents)

		elseif token.type == "start" then
			local contents = {
				type = "escape",
			}
			i = i + 1
			contents, i = parse(tokens, i, contents)
			table.insert(parsed, contents)

		elseif token.type == "stop" then
			i = i + 1
			return parsed, i

		else
			error(("couldn't parse %s"):format(dump(token)))
		end
	end
	return parsed, i
end

local function erase_after_newline(parsed, erasing)
	local single_line_parsed = {}

	for _, piece in ipairs(parsed) do
		if type(piece) == "string" then
			if not erasing then
				if piece:find("\n") then
					erasing = true
					local single_line = piece:match("^([^\n]*)\n")
					table.insert(single_line_parsed, single_line)

				else
					table.insert(single_line_parsed, piece)
				end
			end

		elseif piece.type == "bgcolor" or piece.type == "color" then
			table.insert(single_line_parsed, piece)

		elseif piece.type == "escape" then
			table.insert(single_line_parsed, erase_after_newline(piece, erasing))

		elseif piece.type == "translation" then
			local stuff = erase_after_newline(piece, erasing)
			stuff.domain = piece.domain
			table.insert(single_line_parsed, stuff)

		else
			error(("unknown type %s"):format(piece.type))
		end
	end

	return single_line_parsed
end

local function unparse(parsed, parts)
	parts = parts or {}
	for _, part in ipairs(parsed) do
		if type(part) == "string" then
			table.insert(parts, part)

		else
			if part.type == "bgcolor" then
				table.insert(parts, ("\27(b@%s)"):format(part.color))

			elseif part.type == "color" then
				table.insert(parts, ("\27(c@%s)"):format(part.color))

			elseif part.domain then
				table.insert(parts, ("\27(T@%s)"):format(part.domain))
				unparse(part, parts)
				table.insert(parts, "\27E")

			else
				table.insert(parts, "\27F")
				unparse(part, parts)
				table.insert(parts, "\27E")

			end
		end
	end

	return parts
end

function util.get_short_description(itemstack)
	local description = itemstack:get_description()
	local tokens = tokenize(description)
	local parsed = parse(tokens)
	local single_line_parsed = erase_after_newline(parsed)
	local single_line = table.concat(unparse(single_line_parsed), "")
	return single_line
end

local max_dist_xz = smartshop.settings.entity_reaction_distance_xz
local max_dist_y = smartshop.settings.entity_reaction_distance_y

function util.is_near_player(pos)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	local players = minetest.get_connected_players()
	for i = 1, #players do
		local ppos = players[i]:get_pos()
		if (
			ppos and
			(math.abs(ppos.x - x) < max_dist_xz) and
			(math.abs(ppos.y + 1 - y) < max_dist_y) and
			(math.abs(ppos.z - z) < max_dist_xz)
		) then
			return true
		end
	end
	return false
end

function util.memoize1(f)
	local memo = {}
	return function(arg)
		if arg == nil then
			return f(arg)
		end
		local rv = memo[arg]

		if not rv then
			rv = f(arg)
			memo[arg] = rv
		end

		return rv
	end
end

smartshop.util = util
