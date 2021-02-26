local function get_meta(pos_or_meta)
    if type(pos_or_meta) == "userdata" then
        return pos_or_meta
    else
        return minetest.get_meta(pos_or_meta)
    end
end

function smartshop.is_admin(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_int("creative") == 1
end

function smartshop.set_admin(pos_or_meta, value)
    local meta = get_meta(pos_or_meta)
    meta:set_int("creative", value and 1 or 0)
end

function smartshop.is_unlimited(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_int("unlimited") == 1
end

function smartshop.set_unlimited(pos_or_meta, value)
    local meta = get_meta(pos_or_meta)
    meta:set_int("unlimited", value and 1 or 0)
end

function smartshop.get_owner(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_string("owner")
end

function smartshop.set_owner(pos_or_meta, value)
    local meta = get_meta(pos_or_meta)
    meta:set_string("owner", value)
end

function smartshop.get_infotext(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_string("infotext")
end

function smartshop.set_infotext(pos_or_meta, value, ...)
    local meta = get_meta(pos_or_meta)
    value = value:format(...)
    return meta:set_string("infotext", value)
end

function smartshop.get_send_spos(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_string("item_send")
end

function smartshop.set_send_spos(pos_or_meta, value, ...)
    local meta = get_meta(pos_or_meta)
    value = value:format(...)
    return meta:set_string("item_send", value)
end

function smartshop.get_refill_spos(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_string("item_refill")
end

function smartshop.set_refill_spos(pos_or_meta, value, ...)
    local meta = get_meta(pos_or_meta)
    value = value:format(...)
    return meta:set_string("item_refill", value)
end

function smartshop.get_title(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_string("title")
end

function smartshop.set_title(pos_or_meta, value, ...)
    local meta = get_meta(pos_or_meta)
    value = value:format(...)
    return meta:set_string("title", value)
end

function smartshop.get_mesein(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_int("mesein")
end

function smartshop.set_mesein(pos_or_meta, value)
    local meta = get_meta(pos_or_meta)
    return meta:set_int("mesein", value)
end

function smartshop.get_inventory(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get_inventory()
end

function smartshop.set_state(pos_or_meta, value)
    local meta = get_meta(pos_or_meta)
    meta:set_int("state", value)
end

function smartshop.has_upgraded(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:get("upgraded")
end

function smartshop.set_upgraded(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    return meta:set_string("upgraded", "true")
end

-- when upgrading, sometimes we can't refund the player if their shop is full
-- so, keep track of it
function smartshop.set_refund(pos_or_meta, refund)
    local meta = get_meta(pos_or_meta)
    meta:set_string("refund", minetest.write_json(refund))
end

function smartshop.remove_refund(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    meta:set_string("refund", "")
end

function smartshop.get_refund(pos_or_meta)
    local meta = get_meta(pos_or_meta)
    local refund = meta:get_string("refund")
    if refund == "" then
        return {}
    else
        return minetest.parse_json(refund)
    end
end
