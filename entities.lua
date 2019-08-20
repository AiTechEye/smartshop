local debug = false
local cache = {}
-- https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L5876

--[[
TODO: PROBLEMS
titanium:titanium_in_ground
titanium:glass
tubelib_addons3:pushing_chest
]]--


local function get_image(item)
    local def = (
        minetest.registered_items[item] or
        minetest.registered_tools[item] or
        minetest.registered_nodes[item] or
        minetest.registered_craftitems[item] or
        {}
    )

    if debug then
        if not cache[item] then
            minetest.log('warning', ('[smartshop:debug] definition for %s'):format(item))
            for key, value in pairs(def) do
                minetest.log('warning', ('[smartshop:debug]     %q = %q'):format(key, minetest.serialize(value)))
            end
            cache[item] = true
        end
    end

    local image
    if def.inventory_image and def.inventory_image ~= '' then
        image = def.inventory_image
    elseif def.tiles then
        if type(def.tiles) == 'string' then
            image = def.tiles
        elseif type(def.tiles) == 'table' then
            if (
                (not def.type or def.type == "node") and
                (not def.drawtype or def.drawtype == "normal" or def.drawtype == "allfaces" or def.drawtype == "allfaces_optional" or def.drawtype == "glasslike" or def.drawtype == "glasslike_framed" or def.drawtype == "glasslike_framed_optional" or def.drawtype == "liquid")
            ) then
                if type(def.tiles[1]) == "string" then
                    if #def.tiles == 6 and type(def.tiles[1]) == "string" and type(def.tiles[3]) == "string" and type(def.tiles[5]) == "string" then
                        image = minetest.inventorycube(def.tiles[1], def.tiles[3], def.tiles[5])
                    elseif #def.tiles == 3 and type(def.tiles[1]) == "string" and type(def.tiles[3]) == "string" then
                        image = minetest.inventorycube(def.tiles[1], def.tiles[3], def.tiles[3])
                    elseif type(def.tiles[1]) == "string" then
                        image = minetest.inventorycube(def.tiles[1], def.tiles[1], def.tiles[1])
                    end
                elseif type(def.tiles[1]) == "table" then
                    if #def.tiles == 6 and type(def.tiles[1]) == "table" and type(def.tiles[1].name) == "string" and type(def.tiles[3]) == "table" and type(def.tiles[3].name) == "string" and type(def.tiles[5]) == "table" and type(def.tiles[5].name) == "string" then
                        image = minetest.inventorycube(def.tiles[1].name, def.tiles[3].name, def.tiles[5].name)
                    elseif #def.tiles == 3 and type(def.tiles[1]) == "table" and type(def.tiles[1].name) == "string" and type(def.tiles[3]) == "table" and type(def.tiles[3].name) == "string" then
                        image = minetest.inventorycube(def.tiles[1].name, def.tiles[3].name, def.tiles[3].name)
                    elseif type(def.tiles[1]) == "table" and type(def.tiles[1].name) == "string" then
                        image = minetest.inventorycube(def.tiles[1].name, def.tiles[1].name, def.tiles[1].name)
                    end
                end
            else
                image = def.tiles[1]
            end
        end
    end

    if type(image) == "table" then
        image = image.name
    end

    if not image and not cache[item] then
        minetest.log('warning', ('[smartshop] definition for %s'):format(item))
        for key, value in pairs(def) do
            minetest.log('warning', ('[smartshop]     %q = %q'):format(key, minetest.serialize(value)))
        end
        cache[item] = true
    end

    return image
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
    on_activate    = function(self, staticdata)
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
    end,
    get_staticdata = function(self)
        return minetest.serialize({item=self.item, pos=self.pos, index=self.index})
    end,
})
