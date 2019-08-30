smartshop.util = {}

function smartshop.util.string_to_pos(spos)
    -- can't just use minetest.string_to_pos, for sake of backward compatibility
    if not spos or type(spos) ~= "string" then
        return nil
    end
    local x, y, z = spos:match("^%s*%(?%s*(%-?%d+)[%s,]+(%-?%d+)[%s,]+(%-?%d+)%s*%)?%s*$")
    if x and y and z then
        return vector.new(tonumber(x), tonumber(y), tonumber(z))
    end
end

smartshop.util.pos_to_string = minetest.pos_to_string

function smartshop.util.player_is_creative(player_name)
    return (
        minetest.check_player_privs(player_name, { creative = true }) or
        minetest.check_player_privs(player_name, { give = true })
    )
end

function smartshop.util.can_access(player, pos)
    local player_name = player:get_player_name()

    return (
        smartshop.get_owner(pos) == player_name or
        minetest.check_player_privs(player_name, { protection_bypass = true })
    )
end

function smartshop.util.deepcopy(orig, copies)
    -- taken from lua documentation
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[smartshop.util.deepcopy(orig_key, copies)] = smartshop.util.deepcopy(orig_value, copies)
            end
            copies[orig] = copy
            setmetatable(copy, smartshop.util.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function smartshop.util.table_invert(t)
    local inverted = {}
    for k,v in pairs(t) do inverted[v] = k end
    return inverted
end

function smartshop.util.table_reversed(t)
    local len = #t
    local reversed = {}
    for i = len,1,-1 do
        reversed[len - i + 1] = t[i]
    end
    return reversed
end

function smartshop.util.table_contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

function smartshop.util.table_is_empty(t)
    for _ in pairs(t) do return false end
    return true
end

function smartshop.util.pairs_by_keys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0
    return function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
end

function smartshop.util.pairs_by_values(t, f)
    if not f then
        f = function(a, b) return a < b end
    end
    local s = {}
    for k, v in pairs(t) do
        table.insert(s, {k, v})
    end
    table.sort(s, function(a, b)
        return f(a[2], b[2])
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

function smartshop.util.round(x)
    -- approved by kahan
    if x % 2 ~= 0.5 then
        return math.floor(x+0.5)
    else
        return x - 0.5
    end
end

