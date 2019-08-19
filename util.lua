smartshop.util = {}

function smartshop.util.string_to_pos(spos)
    -- can't just use minetest.string_to_pos for sake of backward compatibility
    if not spos or type(spos) ~= "string" then return nil end
    local x, y, z = re.match('^%s*%(%s*(%d+)[%s,]+(%d+)[%s,]+(%d+)%s*%)%s*$')
    if x and y and z then
        return {x=tonumber(x), y=tonumber(y), z=tonumber(z)}
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
        minetest.get_meta(pos):get_string("owner") == player_name or
        minetest.check_player_privs(player_name, { protection_bypass = true })
    )
end
