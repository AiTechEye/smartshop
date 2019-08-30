local function toggle_mesein(meta)
    local mesein = smartshop.get_mesein(meta)
    if mesein <= 2 then
        mesein = mesein + 1
    else
        mesein = 0
    end
    smartshop.set_mesein(meta, mesein)
end


function smartshop.wifi_receive_fields(player, pressed)
    local player_name = player:get_player_name()
    local pos         = smartshop.player_pos[player_name]
    if not pos then return end
    local meta = minetest.get_meta(pos)

    if pressed.mesesin then
        toggle_mesein(meta)
        smartshop.wifi_showform(pos, player)
    elseif pressed.save then
        local title = pressed.title
        if not title or title == "" then
            title = "wifi " .. minetest.pos_to_string(pos)
        end
        smartshop.set_title(meta, title)
        local spos = minetest.pos_to_string(pos)
        smartshop.log("action", "%s set title of wifi storage at %s to %s", player_name, spos, title)
        smartshop.player_pos[player_name] = nil
    elseif pressed.quit then
        smartshop.player_pos[player_name] = nil
    end
end

function smartshop.wifi_showform(pos, player)
    if not smartshop.util.can_access(player, pos) then return end
    local meta        = minetest.get_meta(pos)
    local player_name = player:get_player_name()
    local spos        = minetest.pos_to_string(pos)
    local fpos        = pos.x .. "," .. pos.y .. "," .. pos.z
    local title       = smartshop.get_title(meta)
    if not title or title == "" then
        title = "wifi " .. spos
    end
    title = minetest.formspec_escape(title)

    local gui = "size[12,9]"

    if smartshop.settings.has_mesecon then
        local mesein = smartshop.get_mesein(meta)
        if mesein == 0 then
            gui = gui .. "button[0,7;2,1;mesesin;Don't send]"
        elseif mesein == 1 then
            gui = gui .. "button[0,7;2,1;mesesin;Incoming]"
        elseif mesein == 2 then
            gui = gui .. "button[0,7;2,1;mesesin;Outcoming]"
        elseif mesein == 3 then
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

    local shop_info = smartshop.add_storage[player_name]
    if shop_info and shop_info.pos then
        local distance = vector.distance(shop_info.pos, pos)
        if distance > smartshop.settings.max_wifi_distance then
            minetest.chat_send_player(player_name, "Too far, max distance " .. smartshop.settings.max_wifi_distance)
        end
        local shop_meta = minetest.get_meta(shop_info.pos)
        if shop_info.send then
            smartshop.set_send_spos(shop_meta, spos)
            minetest.chat_send_player(player_name, "send storage connected")
        elseif shop_info.refill then
            smartshop.set_refill_spos(shop_meta, spos)
            minetest.chat_send_player(player_name, "refill storage connected")
        else
            smartshop.log("warning", "weird data received when linking storage: %s", minetest.serialize(shop_info))
        end
        smartshop.add_storage[player_name] = nil
    end

    smartshop.player_pos[player_name] = pos
    minetest.after(0, minetest.show_formspec, player_name, "smartshop.wifi_showform", gui)
end



