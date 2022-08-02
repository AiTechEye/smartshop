
local F = minetest.formspec_escape
local string_to_pos = minetest.string_to_pos

local S = smartshop.S
local api = smartshop.api

local function FS(text, ...)
	return F(S(text, ...))
end

local formspec_pos = smartshop.util.formspec_pos
local get_short_description = smartshop.util.get_short_description
local player_is_admin = smartshop.util.player_is_admin
local truncate = smartshop.util.truncate

local history_max = smartshop.settings.history_max

--------------------

function api.on_player_receive_fields(player, formname, fields)
	local spos = formname:match("^smartshop:(.+)$")
	local pos = spos and string_to_pos(spos)
	local obj = api.get_object(pos)
	if obj then
		obj:receive_fields(player, fields)
		return true
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	return api.on_player_receive_fields(player, formname, fields)
end)

function api.build_owner_formspec(shop)
	local fpos = formspec_pos(shop.pos)
	local send = shop:get_send()
	local refill = shop:get_refill()

	local is_unlimited = shop:is_unlimited()
	local is_strict_meta = shop:is_strict_meta()
	local is_private = shop:is_private()
	local allow_freebies = shop:allow_freebies()
	local owner = shop:get_owner()

	local fs_parts = {
		"size[8,11]",

		("label[0,0.2;%s]"):format(FS("for sale:")),
		("list[nodemeta:%s;give1;1,0;1,1;]"):format(fpos),
		("list[nodemeta:%s;give2;2,0;1,1;]"):format(fpos),
		("list[nodemeta:%s;give3;3,0;1,1;]"):format(fpos),
		("list[nodemeta:%s;give4;4,0;1,1;]"):format(fpos),
		("label[0,1.2;%s]"):format(FS("price:")),
		("list[nodemeta:%s;pay1;1,1;1,1;]"):format(fpos),
		("list[nodemeta:%s;pay2;2,1;1,1;]"):format(fpos),
		("list[nodemeta:%s;pay3;3,1;1,1;]"):format(fpos),
		("list[nodemeta:%s;pay4;4,1;1,1;]"):format(fpos),

		("button[6,0;2,1;customer;%s]"):format(FS("customer view")),
		("tooltip[customer;%s]"):format(FS("view the shop as a customer")),

		("checkbox[6,0.9;strict_meta;%s;%s]"):format(FS("strict meta?"), tostring(is_strict_meta)),
		("tooltip[strict_meta;%s]"):format(FS("check this if you are buying or selling items with unique properties " ..
			"like written books or petz.")),
		("checkbox[6,1.2;private;%s;%s]"):format(FS("private?"), tostring(is_private)),
		("tooltip[private;%s]"):format(FS("uncheck this if you want to share control of the shop with anyone in the " ..
			"protected area.")),
		("checkbox[6,1.5;freebies;%s;%s]"):format(FS("freebies?"), tostring(allow_freebies)),
		("tooltip[freebies;%s]"):format(FS("check this if you want to be able to give/receive items without " ..
			"an exchange")),

		"list[current_player;main;0,7.2;8,4;]",
		("listring[nodemeta:%s;main]"):format(fpos),
		"listring[current_player;main]",
	}

	if player_is_admin(owner) then
		table.insert_all(fs_parts, {
			("checkbox[6,0.6;is_unlimited;%s;%s]"):format(FS("unlimited?"), tostring(is_unlimited)),
			("tooltip[is_unlimited;%s]"):format(FS("check this allow exchanges ex nihilo. " ..
				"shop contents will be ignored")),
		})
	end

	if history_max ~= 0 then
		table.insert_all(fs_parts, {
			("button[5,2;2.5,1;history;%s]"):format(FS("purchase history")),
			("tooltip[history;%s]"):format(FS("view a log of purchases from the shop")),
		})
	end

	if is_unlimited then
		table.insert(fs_parts, ("label[0.5,2.5;%s]"):format(FS("Stock is unlimited")))

	else
		table.insert_all(fs_parts, {
			("list[nodemeta:%s;main;0,3;8,4;]"):format(fpos),
			("button_exit[5,0;1,1;trefill;%s]"):format(FS("refill")),
			("button_exit[5,1;1,1;tsend;%s]"):format(FS("send")),
		})

		if send then
			local title = F(send:get_title())
			table.insert(fs_parts, ("tooltip[tsend;%s]"):format(FS("payments sent to @1", title)))
		else
			table.insert(fs_parts, ("tooltip[tsend;%s]"):format(FS("click to set send storage")))
		end

		if refill then
			local title = F(refill:get_title())
			table.insert(fs_parts, ("tooltip[trefill;%s]"):format(FS("automatically refilled from @1", title)))
		else
			table.insert(fs_parts, ("tooltip[trefill;%s]"):format(FS("click to set refill storage")))
		end
	end

	return table.concat(fs_parts, "")
end

function api.build_client_formspec(shop)
	-- we need formspec version3 here,
	-- so that we can make the give/pay slots list[]s, and cover them w/ an invisible button
	-- which fixes UI scaling issues for small screens

	local fpos = formspec_pos(shop.pos)
	local strict_meta = shop:is_strict_meta()

	local fs_parts = {
		"formspec_version[3]",
		"size[10.5,8]",
		"style_type[image_button;bgcolor=#00000000;bgimg=blank.png;border=false]",
		"list[current_player;main;0.375,3.125;8,4;]",
		("label[0.375,0.625;%s]"):format(FS("for sale:")),
		("label[0.375,1.875;%s]"):format(FS("price:")),
	}

	local function give_i(i)
		if shop:can_exchange(i) then
			local give_stack = shop:get_give_stack(i)
			local give_parts = {
				("list[nodemeta:%s;give%i;%f,0.375;1,1;]"):format(fpos, i, (i + 1) * (5 / 4) + (3 / 8)),
				("image_button[%f,0.375;1,1;blank.png;buy%ia;]"):format((i + 1) * (5 / 4) + (3 / 8), i),
			}

			if strict_meta then
				table.insert(give_parts, ("tooltip[buy%ia;%s\n%s]"):format(
					i, F(get_short_description(give_stack)), F(truncate(give_stack:to_string(), 50))
				))

			else
				local item_name = give_stack:get_name()
				local def = minetest.registered_items[item_name]
				local description
				if def then
					description = def.short_description or def.description or def.name
				else
					description = item_name
				end

				table.insert(give_parts, ("tooltip[buy%ia;%s\n%s]"):format(
					i, F(description), F(item_name)
				))
			end

			return table.concat(give_parts, "")
		else
			return ""
		end
	end

	local function buy_i(i)
		if shop:can_exchange(i) then
			local pay_stack = shop:get_pay_stack(i)
			local pay_parts = {
				("list[nodemeta:%s;pay%i;%f,1.625;1,1;]"):format(fpos, i, (i + 1) * (5 / 4) + (3 / 8)),
				("image_button[%f,1.625;1,1;blank.png;buy%ib;]"):format((i + 1) * (5 / 4) + (3 / 8), i),
			}

			if strict_meta then
				table.insert(pay_parts, ("tooltip[buy%ib;%s\n%s]"):format(
					i, F(get_short_description(pay_stack)), F(truncate(pay_stack:to_string(), 50))
				))

			else
				local item_name = pay_stack:get_name()
				local def = minetest.registered_items[item_name]
				local description
				if def then
					description = def.short_description or def.description or def.name
				else
					description = item_name
				end

				table.insert(pay_parts, ("tooltip[buy%ib;%s\n%s]"):format(
					i, F(description), F(item_name)
				))
			end

			return table.concat(pay_parts, "")
		else
			return ""
		end
	end

	for i = 1, 4 do
		table.insert(fs_parts, give_i(i))
		table.insert(fs_parts, buy_i(i))
	end

	return table.concat(fs_parts, "")
end

function api.build_storage_formspec(storage)
	local fpos = formspec_pos(storage.pos)
	local is_private = storage:is_private()

	local fs_parts = {
		"size[12,9]",
		("field[0.3,5.3;2,1;title;;%s]"):format(F(storage:get_title())),
		"field_close_on_enter[title;false]",
		("tooltip[title;%s]"):format(FS("used with connected smartshops")),
		("button_exit[0,6;2,1;save;%s]"):format(FS("save")),
		("list[nodemeta:%s;main;0,0;12,5;]"):format(fpos),
		"list[current_player;main;2,5;8,4;]",
		("listring[nodemeta:%s;main]"):format(fpos),
		"listring[current_player;main]",
		("checkbox[0,7;private;%s;%s]"):format(FS("Private?"), tostring(is_private)),
		("tooltip[private;%s]"):format(FS("uncheck this if you want to share control of the storage with anyone in " ..
			"the protected area.")),
	}

	return table.concat(fs_parts, "")
end

local function format_timestamp(timestamp)
	return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

local function format_item(item, count)
	if count == 0 then
		return "nothing"

	elseif count == 1 then
		return item

	else
		return ("%i*%s"):format(count, item)
	end
end

function api.build_history_formspec(shop)
	local history = shop:get_purchase_history()
	local fs_parts = {
		"size[11,11]",
		"button[5,10;1,1;close_history;X]",
		("tooltip[close_history;%s]"):format(FS("close history")),
		"textlist[0,0;10.8,9.8;history;",
	}

	local tl_parts = {}
	local index = history.index
	local i = index
	while true do
		local entry = history[i]

		if not entry then
			break
		end

		table.insert(tl_parts, FS("@1 @2 bought @3 for @4",
			format_timestamp(entry.timestamp),
			entry.player_name,
			format_item(entry.give_item, entry.give_count),
			format_item(entry.pay_item, entry.pay_count)
		))

		i = i - 1
		if i == 0 then
			i = #history
		end

		if i == index then
			break
		end
	end

	table.insert(fs_parts, table.concat(tl_parts, ","))
	table.insert(fs_parts, "]")

	return table.concat(fs_parts, "")
end
