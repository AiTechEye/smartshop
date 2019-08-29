local element_dir = {
    vector.new(0, 0, -1),
    vector.new(-1, 0, 0),
    vector.new(0, 0, 1),
    vector.new(1, 0, 0),
}

local element_pos = {
    { vector.new(0.2, 0.2, -0.2), vector.new(-0.2, 0.2, -0.2), vector.new(0.2, -0.2, -0.2), vector.new(-0.2, -0.2, -0.2) },
    { vector.new(-0.2, 0.2, 0.2), vector.new(-0.2, 0.2, -0.2), vector.new(-0.2, -0.2, 0.2), vector.new(-0.2, -0.2, -0.2) },
    { vector.new(-0.2, 0.2, 0.2), vector.new(0.2, 0.2, 0.2), vector.new(-0.2, -0.2, 0.2), vector.new(0.2, -0.2, 0.2) },
    { vector.new(0.2, 0.2, -0.2), vector.new(0.2, 0.2, 0.2), vector.new(0.2, -0.2, -0.2), vector.new(0.2, -0.2, 0.2) },
}

local entity_offset = vector.new(0.01, 6.5/16, 0.01)

local entities_by_pos = {}

function smartshop.update_shop_info(pos)
    local shop_meta = minetest.get_meta(pos)
    local shop_inv  = shop_meta:get_inventory()
    local owner     = smartshop.get_owner(shop_meta)

	if smartshop.is_unlimited(shop_meta) then
        smartshop.set_infotext(shop_meta, "(Smartshop by %s) Stock is unlimited", owner)
        return
    end

	local inv_totals = {}
	for i = 1, 32 do
		local stack = shop_inv:get_stack("main", i)
		if not stack:is_empty() and stack:is_known() and stack:get_wear() == 0 then
			local name = stack:get_name()
			inv_totals[name] = (inv_totals[name] or 0) + stack:get_count()
		end
	end

	local lines = {("(Smartshop by %s) Purchases left:"):format(owner)}
    for i = 1, 4, 1 do
		local give_stack = shop_inv:get_stack("give" .. i, 1)
		if not give_stack:is_empty() and give_stack:is_known() and give_stack:get_wear() == 0 then
			local name  = give_stack:get_name()
	        local count = give_stack:get_count()
			local stock = inv_totals[name] or 0
			local buy   = math.floor(stock / count)
			if buy ~= 0 then
				local def         = give_stack:get_definition()
				local description = def["description"]
				local message     = ("(%i) %s"):format(buy, description)
				table.insert(lines, message)
			end
		end
    end

    if #lines == 1 then
        smartshop.set_infotext(shop_meta, "(Smartshop by %s)\nThis shop is empty.", owner)
    else
        smartshop.set_infotext(shop_meta, table.concat(lines, "\n"))
    end
end

function smartshop.clear_shop_display(pos)
    local spos       = minetest.pos_to_string(pos)
    local entities = entities_by_pos[spos] or {}
    for _, existing_entity in pairs(entities) do
        existing_entity:remove()
    end
    entities_by_pos[spos] = {}
end

local function add_entity(pos, param2, index, item)
    local ep = element_pos[param2 + 1]
    local e  = minetest.add_entity(
        vector.add(pos, ep[index]),
        "smartshop:item",
        minetest.serialize({item=item, pos=pos, index=index})
    )
    e:set_yaw(math.pi * 2 - param2 * math.pi / 2)
    return e
end

local function set_entity(pos, index, entity)
    local spos     = minetest.pos_to_string(pos)
    local entities = entities_by_pos[spos] or {}
    local existing_entity = entities[index]
    if existing_entity then
        existing_entity:remove()
    end
    entities[index] = entity
    entities_by_pos[spos] = entities
end

local function remove_entity(pos, index)
    local spos     = minetest.pos_to_string(pos)
    local entities = entities_by_pos[spos] or {}
    local existing_entity = entities[index]
    if existing_entity then
        existing_entity:remove()
    end
    entities[index] = nil
    entities_by_pos[spos] = entities
end

local function remove_entities(pos)
    for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
        if ob then
            local le = ob:get_luaentity()
            if le and (le.smartshop or (le.pos and type(le.pos) == "table" and vector.equals(pos, vector.round(le.pos)))) then
                ob:remove()
            end
        end
    end
end

function smartshop.update_shop_display(pos)
    local param2      = minetest.get_node(pos).param2
    local dir         = element_dir[param2 + 1]
    if not dir then return end

    local shop_meta  = minetest.get_meta(pos)
    local shop_inv   = shop_meta:get_inventory()
    local entity_pos = vector.add(pos, vector.multiply(dir, entity_offset))

    for index = 1, 4 do
        local give_stack = shop_inv:get_stack("give" .. index, 1)
        if not give_stack:is_empty() and give_stack:is_known() then
            local e = add_entity(entity_pos, param2, index, give_stack:get_name())
            set_entity(pos, index, e)
        else
            remove_entity(pos, index)
        end
    end
end

minetest.register_lbm({
	name = "smartshop:load_shop",
	nodenames = {
        "smartshop:shop",
        "smartshop:shop_full",
        "smartshop:shop_empty",
        "smartshop:shop_used",
        "smartshop:shop_admin"
    },
    run_at_every_load = true,
	action = function(pos, node)
        smartshop.clear_shop_display(pos)
        remove_entities(pos)
        smartshop.update_shop_display(pos)
        smartshop.update_shop_info(pos)
        smartshop.update_shop_color(pos)
        local meta = minetest.get_meta(pos)
        local metatable = meta:to_table() or {}
        if metatable.creative == 1 then
            if metatable.type == 0 then
                metatable.unlimited = 1
                metatable.item_send = nil
                metatable.item_refill = nil
            elseif metatable.type == 1 then
                metatable.unlimited = 0
            end
            if metatable.type then
                metatable.type = nil
            end
        end
        meta:from_table(metatable)
	end,
})

minetest.register_lbm({
      name              = "smartshop:repay_lost_stuff",
      nodenames         = {
          "smartshop:shop",
          "smartshop:shop_empty",
          "smartshop:shop_full",
          "smartshop:shop_used",
      },
      run_at_every_load = false,
      action            = function(pos, node)
          -- recoup lost inventory items if possible
          local meta = minetest.get_meta(pos)
          if smartshop.is_creative(meta) then return end
          local inv = meta:get_inventory()
          for index = 1, 4 do
              local pay_stack = inv:get_stack("pay" .. index, 1)
              if not pay_stack:is_empty() and inv:room_for_item("main", pay_stack) then
                  inv:add_item("main", pay_stack)
              end
              local give_stack = inv:get_stack("give" .. index, 1)
              if not give_stack:is_empty() and inv:room_for_item("main", give_stack) then
                  inv:add_item("main", give_stack)
              end
          end
      end,
})

minetest.register_on_shutdown(function()
    for _, entities in pairs(entities_by_pos) do
        for _, existing_entity in pairs(entities) do
            existing_entity:remove()
        end
    end
    entities_by_pos = {}
end)
