local function expire_link(player_name)
	if smartshop.add_storage[player_name] then
		minetest.chat_send_player(player_name, "Time expired (30s)")
		smartshop.add_storage[player_name] = nil
	end
end

local function toggle_send(player_name, pos)
	smartshop.add_storage[player_name] = { send = true, pos = pos }
	minetest.after(30, expire_link, player_name)
	minetest.chat_send_player(player_name, "Open a storage owned by you")
end

local function toggle_refill(player_name, pos)
	smartshop.add_storage[player_name] = { refill = true, pos = pos }
	minetest.after(30, expire_link, player_name)
	minetest.chat_send_player(player_name, "Open a storage owned by you")
end

local function toggle_sell_all(player_name, pos)
	local meta  = minetest.get_meta(pos)
	if meta:get_int("sellall") == 0 then
		meta:set_int("sellall", 1)
		minetest.chat_send_player(player_name, "Sell your stock and give line")
	else
		meta:set_int("sellall", 0)
		minetest.chat_send_player(player_name, "Sell your stock only")
	end
end

local function toggle_limit(player_name, pos)
	local meta  = minetest.get_meta(pos)
	if meta:get_int("type") == 0 then
		meta:set_int("type", 1)
		minetest.chat_send_player(player_name, "Your stock is limited")
	else
		meta:set_int("type", 0)
		minetest.chat_send_player(player_name, "Your stock is unlimited")
	end
end

local function get_buy_n(pressed)
	for n = 1, 4 do
		if pressed["buy" .. n] then return n end
	end
end

local function process_purchase(player_inv, shop_inv, pay_name, pay_stack, stack_to_use, get_name, player_name, is_unlimited)
	for i = 0, 32, 1 do
		local player_inv_stack = player_inv:get_stack("main", i)
		if player_inv_stack:get_name() == pay_stack:get_name() and player_inv_stack:get_wear() > 0 then
			minetest.chat_send_player(player_name, "Error: You cannot trade in used tools")
			return
		end
	end
	if is_unlimited then
		player_inv:add_item("main", pay_name)
	else
		local sold_thing = shop_inv:remove_item(stack_to_use, get_name)
		local payment    = player_inv:remove_item("main", pay_name)
		player_inv:add_item("main", sold_thing)
		shop_inv:add_item("main", payment)
	end
end

local function update_wifi_storage(shop_meta, shop_inv, pay_name, get_name, exchange_possible, player_name)
	local tsend   = minetest.string_to_pos(shop_meta:get_string("item_send"))
	if tsend then
		local wifi_meta = minetest.get_meta(tsend)
		local wifi_inv  = wifi_meta:get_inventory()
		local mes       = wifi_meta:get_int("mesein")
		for i = 1, 10 do
			if wifi_inv:room_for_item("main", pay_name) and shop_inv:contains_item("main", pay_name) then
				wifi_inv:add_item("main", shop_inv:remove_item("main", pay_name))
				if mes == 1 or mes == 3 then
					smartshop.send_mesecon(tsend)
				end
			else
				break
			end
		end
	end

	local trefill = minetest.string_to_pos(shop_meta:get_string("item_refill"))
	if trefill then
		local wifi_meta = minetest.get_meta(trefill)
		local wifi_inv  = wifi_meta:get_inventory()
		local mes       = wifi_meta:get_int("mesein")

		local space     = 0
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
				if mes == 2 or mes == 3 then
					smartshop.send_mesecon(trefill)
				end
			else
				break
			end
		end
		if space ~= 0 and not exchange_possible then
			minetest.chat_send_player(player_name, "Try again, stock just refilled")
		end
	end
end

local function buy_item_n(player, pos, n)
	local meta        = minetest.get_meta(pos)
	local shop_inv    = meta:get_inventory()
	local get_stack   = shop_inv:get_stack("give" .. n, 1)
	local name        = get_stack:get_name()
	if name == "" then return end

	local exchange_possible = true
	local is_unlimited  = meta:get_int("type") == 0
	local sellall       = meta:get_int("sellall")
	local player_inv    = player:get_inventory()
	local get_name      = name .. " " .. get_stack:get_count()
	local pay_stack     = shop_inv:get_stack("pay" .. n, 1)
	local pay_name      = pay_stack:get_name() .. " " .. pay_stack:get_count()

    local player_name   = player:get_player_name()
	--fast checks
	if not player_inv:room_for_item("main", get_name) then
		minetest.chat_send_player(player_name, "Error: Your inventory is full, exchange aborted.")
		return
	elseif not player_inv:contains_item("main", pay_name) then
		minetest.chat_send_player(player_name, "Error: You dont have enough to buy this, exchange aborted.")
		return
	elseif not is_unlimited and shop_inv:room_for_item("main", pay_name) == false then
		minetest.chat_send_player(player_name, "Error: This shop is full, exchange aborted.")
		return
	end

	local stack_to_use
	if shop_inv:contains_item("main", get_name) then
		stack_to_use = "main"
	elseif sellall == 1 and shop_inv:contains_item("give" .. n, get_name) then
		stack_to_use = "give" .. n
	else
		minetest.chat_send_player(player_name, "Error: This item has sold out.")
		exchange_possible = false
	end

	if exchange_possible then
		process_purchase(player_inv, shop_inv, pay_name, pay_stack, stack_to_use, get_name, player_name, is_unlimited)
		smartshop.send_mesecon(pos)
	end
	-- send to / refill from wifi storage
	if not is_unlimited then
		update_wifi_storage(meta, shop_inv, pay_name, get_name, exchange_possible, player_name)
	end
end

local function get_shop_owner_gui(spos, shop_meta, is_creative)
    local gui = ""
            .. "size[8,10]"

            .. "button_exit[6,0;1.5,1;customer;Customer]"
            .. "button[7.2,0;1,1;sellall;All]"
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

            .. "button_exit[5,0;1,1;tsend;Send]"
            .. "button_exit[5,1;1,1;trefill;Refill]"

    local tsend   = minetest.string_to_pos(shop_meta:get_string("item_send"))
    local trefill = minetest.string_to_pos(shop_meta:get_string("item_refill"))
	local is_unlimited = shop_meta:get_int("type") == 0

    if tsend then
        local m     = minetest.get_meta(tsend)
        local title = m:get_string("title")
        if title == "" or m:get_string("owner") ~= shop_meta:get_string("owner") then
            shop_meta:set_string("item_send", "")
            title = "error"
        end
        gui = gui .. "tooltip[tsend;Send payments to " .. title .. "]"
    else
        gui = gui .. "tooltip[tsend;Send payments to storage]"

    end

    if trefill then
        local m     = minetest.get_meta(trefill)
        local title = m:get_string("title")
        if title == "" or m:get_string("owner") ~= shop_meta:get_string("owner") then
            shop_meta:set_string("item_refill", "")
            title = "error"
        end
        gui = gui .. "tooltip[trefill;Refill from " .. title .. "]"
    else
        gui = gui .. "tooltip[trefill;Refill from storage]"
    end

	if is_unlimited then
        gui = gui .. "label[0.5,-0.4;Your stock is unlimited because you have creative or give]"
	end
    if is_creative then
        gui = gui .. "button[6,1;2.2,1;togglelime;Toggle limit]"
    end
    gui = gui
            .. "list[nodemeta:" .. spos .. ";main;0,2;8,4;]"
            .. "list[current_player;main;0,6.2;8,4;]"
            .. "listring[nodemeta:" .. spos .. ";main]"
            .. "listring[current_player;main]"
    return gui
end

local function get_shop_player_gui(spos, shop_inv)
    return ""
                .. "size[8,6]"
                .. "list[current_player;main;0,2.2;8,4;]"
                .. "label[0,0.2;Item:]"
                .. "label[0,1.2;Price:]"
                .. "list[nodemeta:" .. spos .. ";give1;2,0;1,1;]"
                .. "item_image_button[2,1;1,1;" .. shop_inv:get_stack("pay1", 1):get_name() .. ";buy1;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay1", 1):get_count() .. "]"
                .. "list[nodemeta:" .. spos .. ";give2;3,0;1,1;]"
                .. "item_image_button[3,1;1,1;" .. shop_inv:get_stack("pay2", 1):get_name() .. ";buy2;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay2", 1):get_count() .. "]"
                .. "list[nodemeta:" .. spos .. ";give3;4,0;1,1;]"
                .. "item_image_button[4,1;1,1;" .. shop_inv:get_stack("pay3", 1):get_name() .. ";buy3;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay3", 1):get_count() .. "]"
                .. "list[nodemeta:" .. spos .. ";give4;5,0;1,1;]"
                .. "item_image_button[5,1;1,1;" .. shop_inv:get_stack("pay4", 1):get_name() .. ";buy4;\n\n\b\b\b\b\b" .. shop_inv:get_stack("pay4", 1):get_count() .. "]"
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
    elseif pressed.sellall then
		toggle_sell_all(player_name, pos)
    elseif pressed.togglelime then
		toggle_limit(player_name, pos)
    elseif not pressed.quit then
        local n = get_buy_n(pressed)
		if n then
			buy_item_n(player, pos, n)
        end
    else
        smartshop.update_shop_info(pos)
        smartshop.update_shop_display(pos, "update")
        smartshop.player_pos[player:get_player_name()] = nil
    end
end

function smartshop.shop_showform(pos, player, ignore_owner)
    local shop_meta   = minetest.get_meta(pos)
    local shop_inv    = shop_meta:get_inventory()
    local spos        = pos.x .. "," .. pos.y .. "," .. pos.z
    local player_name = player:get_player_name()
    local is_owner

    if ignore_owner then
        is_owner = false
    else
        is_owner = smartshop.util.can_access(player, pos)
    end

    local gui
    if is_owner then
        -- if a shop is unlimited, but the player no longer has creative privs, revert the shop
        local is_creative
        if shop_meta:get_int("type") == 0 and not smartshop.util.player_is_creative(player_name) then
            shop_meta:set_int("creative", 0)
            shop_meta:set_int("type", 1)
            is_creative = false
        else
            is_creative = shop_meta:get_int("creative") == 1
        end

        gui = get_shop_owner_gui(spos, shop_meta, is_creative)
    else
        gui = get_shop_player_gui(spos, shop_inv)
    end

    smartshop.player_pos[player_name] = pos
    minetest.after(0, minetest.show_formspec, player_name, "smartshop.shop_showform", gui)
end
