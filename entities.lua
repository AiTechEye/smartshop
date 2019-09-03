local debug = false
local cache = {}

local function get_image_from_tile(tile)
    if type(tile) == "string" then
        return tile
    elseif type(tile) == "table" then
        if type(tile.image) == "string" then
            return tile.image
        elseif type(tile.name) == "string" then
            return tile.name
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
    if def.inventory_image and def.inventory_image ~= "" then
        image = def.inventory_image
    elseif tiles then
        local tiles = def.tiles or def.tile_images
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
