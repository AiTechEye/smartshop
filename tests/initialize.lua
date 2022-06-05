
-- a mapblock
local function get_box(pos)
    pos = vector.round(pos)
    local x0 = pos.x - (pos.x % 16)
    local x1 = x0 + 16
    local y0 = pos.y - (pos.y % 16)
    local y1 = y0 + 16
    local z0 = pos.z - (pos.z % 16)
    local z1 = z0 + 16
    local cur_pos = {x=x0, y=y0, z=z0}
    return function()
        if not cur_pos then
            return
        end
        local to_return = table.copy(cur_pos)
        cur_pos.x = cur_pos.x + 1
        if cur_pos.x == x1 then
            cur_pos.x = x0
            cur_pos.y = cur_pos.y + 1
        end
        if cur_pos.y == y1 then
            cur_pos.y = y0
            cur_pos.z = cur_pos.z + 1
        end
        if cur_pos.z == z1 then
            cur_pos = nil
        end
        return to_return
    end
end

local function get_center(pos)
    pos = vector.round(pos)
    return vector.new(
        pos.x - (pos.x % 16) + 7,
        pos.y - (pos.y % 16) + 7,
        pos.y - (pos.y % 16) + 7
    )
end

table.insert(smartshop.tests.tests, {
    name = "initialize test region",
    func = function(player, state)
        local ppos = player:get_pos()
        local center = get_center(ppos)

        player:set_physics_override({
            speed = 0,
            jump = 0,
            gravity = 0,
        })
        local v = player:get_velocity()
        player:add_velocity(-v)
        player:set_pos(vector.add(center, vector.new(0, 0.501, 0)))
        player:set_look_horizontal(0)
        player:set_look_vertical(0)
        player:get_inventory():set_list("main", {})

        minetest.forceload_block(ppos, true)

        for pos in get_box(ppos) do
            minetest.remove_node(pos)
        end
        local place_shop_against = vector.add(center, vector.new(0, 2, 2))
        minetest.swap_node(
            place_shop_against,
            {name = "smartshop:node"}
        )
        minetest.set_player_privs(player:get_player_name(), {
            interact = true,
            server = true,
        })

        state.place_shop_against = place_shop_against
        return state
    end
})
