local wifi_link_time = smartshop.settings.wifi_link_time

local function expire_link(player_name, kind, pos)
	local add_storage = smartshop.add_storage[player_name]
	if add_storage and add_storage[kind] and vector.equals(add_storage.pos, pos) then
		minetest.chat_send_player(player_name, ("Smartshop linking time expired (%is)"):format(wifi_link_time))
		smartshop.add_storage[player_name] = nil
	end
end

local function toggle_send(player_name, pos)
	smartshop.add_storage[player_name] = { send = true, pos = pos }
	minetest.after(wifi_link_time, expire_link, player_name, "send", pos)
	minetest.chat_send_player(player_name, "Open a storage owned by you")
end

local function toggle_refill(player_name, pos)
	smartshop.add_storage[player_name] = { refill = true, pos = pos }
	minetest.after(wifi_link_time, expire_link, player_name, "refill", pos)
	minetest.chat_send_player(player_name, "Open a storage owned by you")
end

local function toggle_limit(player, pos)
	local meta = minetest.get_meta(pos)
	if smartshop.is_unlimited(meta) then
		smartshop.set_unlimited(meta, false)
	else
		smartshop.set_unlimited(meta, true)
		smartshop.set_send_spos(meta, "")
		smartshop.set_refill_spos(meta, "")
	end
	smartshop.update_shop_color(pos)
	smartshop.shop_showform(pos, player)
end

local function get_buy_n(pressed)
	for n = 1, 4 do
		if pressed["buy" .. n] then return n end
	end
end

local function player_has_used_tool(player_inv, pay_stack)
	for i = 0, 32, 1 do
		local player_inv_stack = player_inv:get_stack("main", i)
		if player_inv_stack:get_name() == pay_stack:get_name() and player_inv_stack:get_wear() > 0 then
			return true
		end
	end
	return false
end

local function process_purchase(player_inv, shop_inv, pay_name, pay_stack, give_name, player_name, is_unlimited, shop_owner, pos)
	if player_has_used_tool(player_inv, pay_stack) then
		minetest.chat_send_player(player_name, "Error: You cannot trade in used tools")
		return
	elseif is_unlimited then
		player_inv:add_item("main", give_name)
		player_inv:remove_item("main", pay_name)
	else
		local sold_thing = shop_inv:remove_item("main", give_name)
		local payment    = player_inv:remove_item("main", pay_name)
		player_inv:add_item("main", sold_thing)
		shop_inv:add_item("main", payment)
	end
	local spos = minetest.pos_to_string(pos)
	smartshop.log("action", "%s bought %q for %q from %s at %s", player_name, give_name, pay_name, shop_owner, spos)
end

local function transfer_wifi_storage(shop_meta, shop_inv, pay_name, get_name, exchange_possible, player_name)
	local send_spos = smartshop.get_send_spos(shop_meta)
	local send_pos  = smartshop.util.string_to_pos(send_spos)
	if send_pos then
		local wifi_meta = minetest.get_meta(send_pos)
		local wifi_inv  = smartshop.get_inventory(wifi_meta)
		local mes       = smartshop.get_mesein(wifi_meta)
		for i = 1, 10 do
			if wifi_inv:room_for_item("main", pay_name) and shop_inv:contains_item("main", pay_name) then
				wifi_inv:add_item("main", shop_inv:remove_item("main", pay_name))
				if mes == 1 or mes == 3 then
					smartshop.send_mesecon(send_pos)
				end
			else
				break
			end
		end
	end

	local refill_spos = smartshop.get_refill_spos(shop_meta)
	local refill_pos  = smartshop.util.string_to_pos(refill_spos)
	if refill_pos then
		local wifi_meta       = minetest.get_meta(refill_pos)
		local wifi_inv        = smartshop.get_inventory(wifi_meta)
		local mesein          = smartshop.get_mesein(wifi_meta)
		local stuff_was_moved = false
		local space           = 0
		--check if its room for other items, else the shop will stuck
		for i = 1, 32, 1 do
			if shop_inv:get_stack("main", i):get_count() == 0 then
				space = space + 1
			end
		end
		for i = 1, space, 1 do
			if i < space and wifi_inv:contains_item("main", get_name) and shop_inv:room_for_item("main", get_name) then
				local rstack = wifi_inv:remove_item("main", get_name)
				shop_inv:add_item("main", rstack)
				stuff_was_moved = true
				if mesein == 2 or mesein == 3 then
					smartshop.send_mesecon(refill_pos)
				end
			else
				break
			end
		end
		if stuff_was_moved and not exchange_possible then
			minetest.chat_send_player(player_name, "Try again, stock just refilled")
		end
	end
end

local function buy_item_n(player, pos, n)
	local meta        = minetest.get_meta(pos)
	local shop_inv    = smartshop.get_inventory(meta)
	local get_stack   = shop_inv:get_stack("give" .. n, 1)
	local name        = get_stack:get_name()
	if name == "" then return end

	local exchange_possible
	local is_unlimited  = smartshop.is_unlimited(meta)
	local player_inv    = player:get_inventory()
	local get_name      = name .. " " .. get_stack:get_count()
	local pay_stack     = shop_inv:get_stack("pay" .. n, 1)
	local pay_name      = pay_stack:get_name() .. " " .. pay_stack:get_count()
	local shop_owner    = smartshop.get_owner(meta)

    local player_name   = player:get_player_name()
	--fast checks
	if not player_inv:room_for_item("main", get_name) then
		minetest.chat_send_player(player_name, "Error: Your inventory is full, exchange failed.")
		return
	elseif not player_inv:contains_item("main", pay_name) then
		minetest.chat_send_player(player_name, "Error: You dont have enough to buy this, exchange failed.")
		return
	elseif not is_unlimited and shop_inv:room_for_item("main", pay_name) == false then
		minetest.chat_send_player(player_name, "Error: This shop is full, exchange failed.")
		return
	end

	if is_unlimited or shop_inv:contains_item("main", get_name) then
		process_purchase(player_inv, shop_inv, pay_name, pay_stack, get_name, player_name, is_unlimited, shop_owner, pos)
		smartshop.send_mesecon(pos)
		exchange_possible = true
	else
		minetest.chat_send_player(player_name, "Error: This item has sold out.")
		exchange_possible = false
	end
	-- send to / refill from wifi storage
	if not is_unlimited then
		transfer_wifi_storage(meta, shop_inv, pay_name, get_name, exchange_possible, player_name)
	end
end

local function get_shop_owner_gui(spos, shop_meta, is_creative)
    local gui          = "size[8,10]"
             .. "button_exit[6,0;1.5,1;customer;Customer]"
             .. "label[0,0.2;Item:]"
             .. "label[0,1.2;Price:]"
             .. "list[nodemeta:" .. spos .. ";give1;1,0;1,1;]"
             .. "list[nodemeta:" .. spos .. ";pay1;1,1;1,1;]"
             .. "list[nodemeta:" .. spos .. ";give2;2,0;1,1;]"
             .. "list[nodemeta:" .. spos .. ";pay2;2,1;1,1;]"
             .. "list[nodemeta:" .. spos .. ";give3;3,0;1,1;]"
             .. "list[nodemeta:" .. spos .. ";pay3;3,1;1,1;]"
             .. "list[nodemeta:" .. spos .. ";give4;4,0;1,1;]"
             .. "list[nodemeta:" .. spos .. ";pay4;4,1;1,1;]"
	local send_spos    = smartshop.get_send_spos(shop_meta)
    local send_pos     = smartshop.util.string_to_pos(send_spos)
	local refill_spos  = smartshop.get_refill_spos(shop_meta)
    local refill_pos   = smartshop.util.string_to_pos(refill_spos)
	local is_unlimited = smartshop.is_unlimited(shop_meta)
	local shop_owner   = smartshop.get_owner(shop_meta)

	if not is_unlimited then
		gui = gui .. "button_exit[5,0;1,1;tsend;Send]"
                  .. "button_exit[5,1;1,1;trefill;Refill]"
	end

    if send_pos then
        local wifi_meta  = minetest.get_meta(send_pos)
        local wifi_title = smartshop.get_title(wifi_meta)
		local wifi_owner = smartshop.get_owner(wifi_meta)
        if wifi_title == "" or wifi_owner ~= shop_owner then
			smartshop.log("warning", "send storage for shop @ %s has error: send_pos=%q title=%q wifi_owner=%q shop_owner=%q",
						  spos, send_spos, wifi_title, wifi_owner, shop_owner)
            smartshop.set_send_spos(shop_meta, "")
	        gui = gui .. "tooltip[tsend;Error w/ send storage]"
		else
			wifi_title = minetest.formspec_escape(wifi_title)
            gui        = gui .. "tooltip[tsend;Payments sent to " .. wifi_title .. "]"
	    end
    else
        gui = gui .. "tooltip[tsend;No send storage configured]"
    end

    if refill_pos then
        local wifi_meta  = minetest.get_meta(refill_pos)
        local wifi_title = smartshop.get_title(wifi_meta)
		local wifi_owner = smartshop.get_owner(wifi_meta)
        if wifi_title == "" or wifi_owner ~= shop_owner then
			smartshop.log("warning", "refill storage for shop @ %s has error: send_pos=%q title=%q wifi_owner=%q shop_owner=%q",
						  spos, send_spos, wifi_title, wifi_owner, shop_owner)
			smartshop.set_refill_spos(shop_meta, "")
	        gui = gui .. "tooltip[tsend;Error w/ refill storage]"
		else
			wifi_title = minetest.formspec_escape(wifi_title)
			gui        = gui .. "tooltip[trefill;Refilled from " .. wifi_title .. "]"
        end
    else
        gui = gui .. "tooltip[trefill;No refill storage configured]"
    end

	if is_unlimited then
        gui = gui .. "label[0.5,-0.4;Your stock is unlimited]"
	end
    if is_creative then
        gui = gui .. "button[6,1;2.2,1;togglelimit;Toggle limit]"
    end
    gui = gui
            .. "list[nodemeta:" .. spos .. ";main;0,2;8,4;]"
            .. "list[current_player;main;0,6.2;8,4;]"
            .. "listring[nodemeta:" .. spos .. ";main]"
            .. "listring[current_player;main]"
    return gui
end

local function get_shop_player_gui(spos, shop_inv)
    return "size[8,6]"
		.. "list[current_player;main;0,2.2;8,4;]"
		.. "label[0,0.2;Item:]"
		.. "label[0,1.2;Price:]"
		.. "list[nodemeta:" .. spos .. ";give1;2,0;1,1;]"
		.. "item_image_button[2,1;1,1;" .. shop_inv:get_stack("pay1", 1):get_name()
		.. ";buy1;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay1", 1):get_count() .. "]"
		.. "list[nodemeta:" .. spos .. ";give2;3,0;1,1;]"
		.. "item_image_button[3,1;1,1;" .. shop_inv:get_stack("pay2", 1):get_name()
		.. ";buy2;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay2", 1):get_count() .. "]"
		.. "list[nodemeta:" .. spos .. ";give3;4,0;1,1;]"
		.. "item_image_button[4,1;1,1;" .. shop_inv:get_stack("pay3", 1):get_name()
		.. ";buy3;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay3", 1):get_count() .. "]"
		.. "list[nodemeta:" .. spos .. ";give4;5,0;1,1;]"
		.. "item_image_button[5,1;1,1;" .. shop_inv:get_stack("pay4", 1):get_name()
		.. ";buy4;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay4", 1):get_count() .. "]"
end

function smartshop.shop_receive_fields(player, pressed)
    local player_name = player:get_player_name()
    local pos         = smartshop.player_pos[player_name]
    if not pos then
        return
    elseif pressed.tsend then
        toggle_send(player_name, pos)
    elseif pressed.trefill then
		toggle_refill(player_name, pos)
    elseif pressed.customer then
        return smartshop.shop_showform(pos, player, true)
    elseif pressed.togglelimit then
		toggle_limit(player, pos)
    elseif not pressed.quit then
        local n = get_buy_n(pressed)
		if n then
			buy_item_n(player, pos, n)
        end
    else
        smartshop.update_shop_info(pos)
        smartshop.update_shop_display(pos, "update")
		smartshop.update_shop_color(pos)
        smartshop.player_pos[player_name] = nil
    end
end

function smartshop.shop_showform(pos, player, ignore_owner)
    local meta        = minetest.get_meta(pos)
    local inv         = smartshop.get_inventory(meta)
    local fpos        = pos.x .. "," .. pos.y .. "," .. pos.z
    local player_name = player:get_player_name()
    local is_owner

    if ignore_owner then
        is_owner = false
    else
        is_owner = smartshop.util.can_access(player, pos)
    end

    local gui
    if is_owner then
        -- if a shop is creative, but the player no longer has creative privs, revert the shop
        local is_creative = smartshop.is_creative(meta)
        if is_creative and not smartshop.util.player_is_creative(player_name) then
			smartshop.set_creative(meta, false)
			smartshop.set_unlimited(meta, false)
            is_creative = false
        end

        gui = get_shop_owner_gui(fpos, meta, is_creative)
    else
        gui = get_shop_player_gui(fpos, inv)
    end

    smartshop.player_pos[player_name] = pos
    minetest.after(0, minetest.show_formspec, player_name, "smartshop.shop_showform", gui)
end
