function smartshop.wifi_receive_fields(player, pressed)
    local player_name = player:get_player_name()
    local pos         = smartshop.player_pos[player_name]
    if not pos then
        return
    end
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
        local t = pressed.title
        if t == "" then t = "wifi" .. math.random(1, 9999) end
        meta:set_string("title", t)
    end
    smartshop.player_pos[player_name] = nil
end

function smartshop.wifi_showform(pos, player)
    if not smartshop.util.can_access(player, pos) then return end
    local meta        = minetest.get_meta(pos)
    local player_name = player:get_player_name()
    local spos              = pos.x .. "," .. pos.y .. "," .. pos.z
    local title             = meta:get_string("title")

    smartshop.player_pos[player_name] = pos

    local gui               = "size[12,9]"

    if title == "" then
        title = "wifi" .. math.random(1, 999)
    end

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

    gui = gui .. ""

            .. "field[0.3,5.3;2,1;title;;" .. title .. "]"
    gui = gui
            .. "tooltip[title;Used with connected smartshops]"
            .. "button_exit[0,6;2,1;save;Save]"

            .. "list[nodemeta:" .. spos .. ";main;0,0;12,5;]"
            .. "list[current_player;main;2,5;8,4;]"
            .. "listring[nodemeta:" .. spos .. ";main]"
            .. "listring[current_player;main]"
    minetest.after((0.1), function(gui)
        return minetest.show_formspec(player_name, "smartshop.wifi_showform", gui)
    end, gui)

    local a = smartshop.add_storage[player_name]
    if a then
        if not a.pos then return end
        if vector.distance(a.pos, pos) > smartshop.settings.max_wifi_distance then
            minetest.chat_send_player(player_name, "Too far, max distance " .. smartshop.settings.max_wifi_distance)
        end
        local meta = minetest.get_meta(a.pos)
        local p    = minetest.pos_to_string(pos)
        if a.send and p then
            meta:set_string("item_send", p)
        elseif a.refill and p then
            meta:set_string("item_refill", p)
        end
        minetest.chat_send_player(player_name, "smartshop connected")
        smartshop.add_storage[player_name] = nil
    end
end



