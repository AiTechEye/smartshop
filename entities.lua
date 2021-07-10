local debug = false
local cache = {}

local entities_by_pos = {}

local element_dir = {
    vector.new(0, 0, -1),
    vector.new(-1, 0, 0),
    vector.new(0, 0, 1),
    vector.new(1, 0, 0),
}

local element_offset = {
    { vector.new(0.2, 0.2, -0.2), vector.new(-0.2, 0.2, -0.2), vector.new(0.2, -0.2, -0.2), vector.new(-0.2, -0.2, -0.2) },
    { vector.new(-0.2, 0.2, 0.2), vector.new(-0.2, 0.2, -0.2), vector.new(-0.2, -0.2, 0.2), vector.new(-0.2, -0.2, -0.2) },
    { vector.new(-0.2, 0.2, 0.2), vector.new(0.2, 0.2, 0.2), vector.new(-0.2, -0.2, 0.2), vector.new(0.2, -0.2, 0.2) },
    { vector.new(0.2, 0.2, -0.2), vector.new(0.2, 0.2, 0.2), vector.new(0.2, -0.2, -0.2), vector.new(0.2, -0.2, 0.2) },
}

local element_offset_3d = {
    { vector.new(0.2, 0.2, -0.1), vector.new(-0.2, 0.2, -0.1), vector.new(0.2, -0.2, -0.1), vector.new(-0.2, -0.2, -0.1) },
    { vector.new(-0.1, 0.2, 0.2), vector.new(-0.1, 0.2, -0.2), vector.new(-0.1, -0.2, 0.2), vector.new(-0.1, -0.2, -0.2) },
    { vector.new(-0.2, 0.2, 0.1), vector.new(0.2, 0.2, 0.1), vector.new(-0.2, -0.2, 0.1), vector.new(0.2, -0.2, 0.1) },
    { vector.new(0.1, 0.2, -0.2), vector.new(0.1, 0.2, 0.2), vector.new(0.1, -0.2, -0.2), vector.new(0.1, -0.2, 0.2) },
}

local entity_offset = vector.new(0.01, 6.5/16, 0.01)

local function get_image_from_tile(tile)
    if type(tile) == "string" then
        return tile
    elseif type(tile) == "table" then
        local image_name
        if type(tile.image) == "string" then
            image_name = tile.image
        elseif type(tile.name) == "string" then
            image_name = tile.name
        end
        if image_name then
            if tile.animation and tile.animation.type == "vertical_frames" and tile.animation.aspect_w and tile.animation.aspect_h then
                return ("smartshop_animation_mask.png^[resize:%ix%i^[mask:"):format(tile.animation.aspect_w, tile.animation.aspect_h) .. image_name
            elseif tile.animation and tile.animation.type == "sheet_2d" and tile.animation.frames_w and tile.animation.frames_h then
                return image_name .. ("^[sheet:%ix%i:0,0"):format(tile.animation.frames_w, tile.animation.frames_h)
            else
                return image_name
            end
        end
    end
    return "unknown_node.png"
end

local function get_image_cube(tiles)
    if #tiles == 6 then
        return minetest.inventorycube(
            get_image_from_tile(tiles[1]),
            get_image_from_tile(tiles[6]),
            get_image_from_tile(tiles[3])
        )
    elseif #tiles == 4 then
        return minetest.inventorycube(
            get_image_from_tile(tiles[1]),
            get_image_from_tile(tiles[4]),
            get_image_from_tile(tiles[3])
        )
    elseif #tiles == 3 then
        return minetest.inventorycube(
            get_image_from_tile(tiles[1]),
            get_image_from_tile(tiles[3]),
            get_image_from_tile(tiles[3])
        )
    elseif #tiles >= 1 then
        return minetest.inventorycube(
            get_image_from_tile(tiles[1]),
            get_image_from_tile(tiles[1]),
            get_image_from_tile(tiles[1])
        )
    end
    return "unknown_node.png"
end


local function get_image(item)
    local def = (
        minetest.registered_items[item] or
        minetest.registered_tools[item] or
        minetest.registered_nodes[item] or
        minetest.registered_craftitems[item] or
        {}
    )

    local image
    local tiles = def.tiles or def.tile_images
    local inventory_image = def.inventory_image

    if inventory_image and inventory_image ~= "" then
        if type(inventory_image) == "string" then
            image = inventory_image
        elseif type(inventory_image) == "table" and #inventory_image == 1 and type(inventory_image[1]) == "string" then
            image = inventory_image[1]
        else
            smartshop.log("warning", "could not decode inventory image for %s", item)
            image = ""  -- UNKNOWN
        end

    elseif tiles then
        if type(tiles) == "string" then
            image = tiles

        elseif type(tiles) == "table" then
            if (
                (not def.type or def.type == "node") and
                (not def.drawtype or
                 def.drawtype == "normal" or
                 def.drawtype == "allfaces" or
                 def.drawtype == "allfaces_optional" or
                 def.drawtype == "glasslike" or
                 def.drawtype == "glasslike_framed" or
                 def.drawtype == "glasslike_framed_optional" or
                 def.drawtype == "liquid")
            ) then
                image = get_image_cube(tiles)
            else
                image = get_image_from_tile(tiles[1])
            end
        end
    end

    if (debug or not image or image == "unknown_node.png") and not cache[item] then
        smartshop.log("warning", "[smartshop] definition for %s", item)
        for key, value in pairs(def) do
            smartshop.log("warning", "[smartshop]     %q = %q", key, minetest.serialize(value))
        end
        cache[item] = true
    end

    return image or "unknown_node.png"
end

local function on_activate(self, staticdata)
    local data = minetest.deserialize(staticdata)
    if not data then
        self.object:remove()
        return
    end
    self.item  = data.item
    self.pos   = data.pos
    self.index = data.index
    local image = get_image(self.item)
    self.object:set_properties({ textures = { image } })
end

local function on_activate_3d(self, staticdata)
    local data = minetest.deserialize(staticdata)
    if not data then
        self.object:remove()
        return
    end
    self.item  = data.item
    self.pos   = data.pos
    self.index = data.index
    self.object:set_properties({ textures = { self.item } })
end

local function get_staticdata(self)
    return minetest.serialize({item=self.item, pos=self.pos, index=self.index})
end

minetest.register_entity("smartshop:item", {
    hp_max         = 1,
    visual         = "sprite",
    visual_size    = { x = .40, y = .40 },
    collisionbox   = { 0, 0, 0, 0, 0, 0 },
    physical       = false,
    textures       = { "air" },
    smartshop2     = true,
    type           = "",
    on_activate    = on_activate,
    get_staticdata = get_staticdata,
})

-- for nodebox and mesh drawtypes, which can't be drawn well by the above
minetest.register_entity("smartshop:item_3d", {
    hp_max         = 1,
    visual         = "wielditem",
    visual_size    = { x = .20, y = .20 },
    collisionbox   = { 0, 0, 0, 0, 0, 0 },
    physical       = false,
    textures       = { "air" },
    smartshop2     = true,
    type           = "",
    on_activate    = on_activate_3d,
    get_staticdata = get_staticdata,
})

function smartshop.clear_shop_entities(pos)
    local spos       = minetest.pos_to_string(pos)
    local entities = entities_by_pos[spos] or {}
    for _, existing_entity in pairs(entities) do
        existing_entity:remove()
    end
    entities_by_pos[spos] = {}
end

local function add_entity(item, shop_pos, index, param2)
    local def = minetest.registered_items[item]
    local dir = element_dir[param2 + 1]

    local entity_pos
    local entity_type
    if (def.drawtype == "nodebox" or def.drawtype == "mesh") and (not def.inventory_image or def.inventory_image == "") then
        local base_pos = vector.add(shop_pos, vector.multiply(dir, entity_offset))
        local offset = element_offset_3d[param2 + 1][index]
        entity_pos = vector.add(base_pos, offset)
        entity_type = "smartshop:item_3d"

    else
        local base_pos = vector.add(shop_pos, vector.multiply(dir, entity_offset))
        local offset = element_offset[param2 + 1][index]
        entity_pos = vector.add(base_pos, offset)
        entity_type = "smartshop:item"
    end

    local e  = minetest.add_entity(
        entity_pos,
        entity_type,
        get_staticdata({item=item, pos=shop_pos, index=index})
    )
    e:set_yaw((math.pi * 2) - (param2 * math.pi / 2))
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

function smartshop.clear_old_entities(pos)
    for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
        -- "3" was chosen because "2" doesn't work sometimes. it should work w/ "1" but doesn't.
        -- note that we still check that the entity is related to the current shop

        if ob then
            local le = ob:get_luaentity()
            if le then
                if le.smartshop then
                    -- old smartshop entity
                    ob:remove()
                elseif le.pos and type(le.pos) == "table" and vector.equals(pos, vector.round(le.pos)) then
                    -- entities associated w/ the current pos
                    ob:remove()
                end
            end
        end
    end
end

local function update_shop_entity(shop_inv, pos, index, param2)
    local give_stack = shop_inv:get_stack("give" .. index, 1)

    if not give_stack:is_empty() and give_stack:is_known() then
        local e = add_entity(give_stack:get_name(), pos, index, param2)
        set_entity(pos, index, e)

    else
        remove_entity(pos, index)
    end
end

function smartshop.update_shop_entities(pos)
    if not smartshop.is_smartshop(pos) then
        return
    end

    local param2      = minetest.get_node(pos).param2
    if not element_dir[param2 + 1] then return end

    local meta       = minetest.get_meta(pos)
    local shop_inv   = smartshop.get_inventory(meta)

    for index = 1, 4 do
        update_shop_entity(shop_inv, pos, index, param2)
    end
end

minetest.register_on_shutdown(function()
    for _, entities in pairs(entities_by_pos) do
        for _, existing_entity in pairs(entities) do
            existing_entity:remove()
        end
    end
    entities_by_pos = {}
end)
