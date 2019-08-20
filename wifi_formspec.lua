function smartshop.wifi_receive_fields(player, pressed)
    local player_name = player:get_player_name()
    local pos         = smartshop.player_pos[player_name]
    if not pos then return end
    local meta = minetest.get_meta(pos)

    if pressed.mesesin then
        local m = meta:get_int("mesein")
        if m <= 2 then
            m = m + 1
        else
            m = 0
        end
        meta:set_int("mesein", m)
        smartshop.wifi_showform(pos, player)
        return
    elseif pressed.save then
        local title = pressed.title
        if not title or title == "" then
            title = "wifi " .. minetest.pos_to_string(pos)
        end
        meta:set_string("title", title)
        local spos = minetest.pos_to_string(pos)
        smartshop.log('action', '%s set title of wifi storage at %s to %s', player_name, spos, title)
    end
    smartshop.player_pos[player_name] = nil
end

function smartshop.wifi_showform(pos, player)
    if not smartshop.util.can_access(player, pos) then return end
    local meta        = minetest.get_meta(pos)
    local player_name = player:get_player_name()
    local spos        = minetest.pos_to_string(pos)
    local fpos        = pos.x .. "," .. pos.y .. "," .. pos.z
    local title       = meta:get_string("title")
    if not title or title == "" then
        title = "wifi " .. spos
    end
    title = minetest.formspec_escape(title)

    local gui = "size[12,9]"

    if smartshop.settings.has_mesecon then
        local m = meta:get_int("mesein")
        if m == 0 then
            gui = gui .. "button[0,7;2,1;mesesin;Don't send]"
        elseif m == 1 then
            gui = gui .. "button[0,7;2,1;mesesin;Incoming]"
        elseif m == 2 then
            gui = gui .. "button[0,7;2,1;mesesin;Outcoming]"
        elseif m == 3 then
            gui = gui .. "button[0,7;2,1;mesesin;Both]"
        end
        gui = gui .. "tooltip[mesesin;Send mesecon signal when items from shops does:]"
    end

    gui = gui
       .. "field[0.3,5.3;2,1;title;;" .. title .. "]"
       .. "tooltip[title;Used with connected smartshops]"
       .. "button_exit[0,6;2,1;save;Save]"
       .. "list[nodemeta:" .. fpos .. ";main;0,0;12,5;]"
       .. "list[current_player;main;2,5;8,4;]"
       .. "listring[nodemeta:" .. fpos .. ";main]"
       .. "listring[current_player;main]"

    smartshop.player_pos[player_name] = pos
    minetest.after(0, minetest.show_formspec, player_name, "smartshop.wifi_showform", gui)

    local shop_info = smartshop.add_storage[player_name]
    if shop_info then
        if not shop_info.pos then return end
        if vector.distance(shop_info.pos, pos) > smartshop.settings.max_wifi_distance then
            minetest.chat_send_player(player_name, "Too far, max distance " .. smartshop.settings.max_wifi_distance)
        end
        local shop_meta = minetest.get_meta(shop_info.pos)
        local shop_spos = minetest.pos_to_string(pos)
        if shop_spos then
            if shop_info.send then
                shop_meta:set_string("item_send", shop_spos)
            elseif shop_info.refill then
                shop_meta:set_string("item_refill", shop_spos)
            end
        end
        minetest.chat_send_player(player_name, "smartshop connected")
        smartshop.add_storage[player_name] = nil
    end
end



