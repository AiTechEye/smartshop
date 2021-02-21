smartshop = {}
smartshop.redo = true
smartshop.version = "20210220.0"

local modname = minetest.get_current_modname()
smartshop.modname = modname
smartshop.modpath = minetest.get_modpath(modname)

function smartshop.log(level, message, ...)
    message = message:format(...)
    minetest.log(level, ("[%s] %s"):format(modname, message))
end

smartshop.player_pos = {}
smartshop.add_storage = {}  -- used for linking shops to external storage

dofile(smartshop.modpath .. "/settings.lua")
dofile(smartshop.modpath .. "/util.lua")

dofile(smartshop.modpath .. "/metadata.lua")

-- interop that affects the API
dofile(smartshop.modpath .. "/interop/currency.lua")
dofile(smartshop.modpath .. "/interop/mesecons.lua")

dofile(smartshop.modpath .. "/entities.lua")

dofile(smartshop.modpath .. "/shop_node.lua")
dofile(smartshop.modpath .. "/shop_display.lua")
dofile(smartshop.modpath .. "/shop_formspec.lua")
dofile(smartshop.modpath .. "/shop_color.lua")

dofile(smartshop.modpath .. "/storage_node.lua")
dofile(smartshop.modpath .. "/storage_formspec.lua")

dofile(smartshop.modpath .. "/crafting.lua")

-- interop that doesn't affect the API
dofile(smartshop.modpath .. "/interop/pipeworks.lua")
dofile(smartshop.modpath .. "/interop/tubelib.lua")

dofile(smartshop.modpath .. "/refunds.lua")


minetest.register_on_player_receive_fields(function(player, form, pressed)
    if form == "smartshop.shop_showform" then
        smartshop.shop_receive_fields(player, pressed)
    elseif form == "smartshop.wifi_showform" then
        smartshop.wifi_receive_fields(player, pressed)
    end
end)
