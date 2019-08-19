local cache = {}
-- https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L5876

minetest.register_entity("smartshop:item", {
    hp_max         = 1,
    visual         = "sprite",
    visual_size    = { x = .40, y = .40 },
    collisionbox   = { 0, 0, 0, 0, 0, 0 },
    physical       = false,
    textures       = { "air" },
    type           = "",
    on_activate    = function(self, staticdata)
        local data = minetest.deserialize(staticdata)
        if not data then
            self.object:remove()
            return
        end
        self.item = data.item
        self.pos  = data.pos
        local def = (
                minetest.registered_items[self.item] or
                minetest.registered_tools[self.item] or
                minetest.registered_nodes[self.item] or
                minetest.registered_craftitems[self.item] or
                {}
        )
        local image
        if def.inventory_image and def.inventory_image ~= '' then
            image = def.inventory_image
        elseif def.tiles then
            if type(def.tiles) == 'string' then
                image = def.tiles
            elseif type(def.tiles) == 'table' and #def.tiles > 0 then
                image = def.tiles[1]
            end
        end

        self.object:set_properties({ textures = { image } })
    end,
    get_staticdata = function(self)
        return minetest.serialize({item=self.item, pos=self.pos})
    end,
})
