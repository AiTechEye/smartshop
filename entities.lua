minetest.register_entity("smartshop:item", {
    hp_max         = 1,
    visual         = "wielditem", -- https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L5876
    visual_size    = { x = .20, y = .20 },
    collisionbox   = { 0, 0, 0, 0, 0, 0 },
    physical       = false,
    textures       = { "air" },  -- TODO should be wield_item, not textures
    smartshop      = true,
    type           = "",
    on_activate    = function(self, staticdata)
        local data = minetest.deserialize(staticdata)
        if not data then
            self.object:remove()
            return
        end
        self.item = data.item
        self.pos  = data.pos
        self.object:set_properties({ textures = { self.item } }) -- TODO should be wield_item, not textures
    end,
    get_staticdata = function(self)
        return minetest.serialize({item=self.item, pos=self.pos})
    end,
})
