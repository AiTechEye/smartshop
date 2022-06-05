local cm = smartshop.resources.craft_materials

if cm.chest_locked and cm.sign_wood and cm.torch then
    minetest.register_craft({
        output = "smartshop:shop",
        recipe = {
            {cm.chest_locked, cm.chest_locked, cm.chest_locked},
            {cm.sign_wood, cm.chest_locked, cm.sign_wood},
            {cm.sign_wood, cm.torch, cm.sign_wood},
        }
    })
end

if cm.mese_fragment and cm.chest_locked and cm.steel_ingot and cm.copper_ingot then
    minetest.register_craft({
        output = "smartshop:storage",
        recipe = {
            {cm.mese_fragment, cm.chest_locked, cm.mese_fragment},
            {cm.mese_fragment, cm.chest_locked, cm.mese_fragment},
            {cm.steel_ingot, cm.copper_ingot, cm.steel_ingot},
        }
    })
end
