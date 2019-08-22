smartshop = {}
smartshop.redo = true
smartshop.version = "1.0.0"

local modname = minetest.get_current_modname()
smartshop.modname = modname
smartshop.modpath = minetest.get_modpath(modname)

function smartshop.log(level, message, ...)
    message = message:format(...)
    minetest.log(level, ("[%s] %s"):format(modname, message))
end

smartshop.player_pos = {}
smartshop.add_storage = {}

dofile(smartshop.modpath .. "/settings.lua")
dofile(smartshop.modpath .. "/util.lua")
dofile(smartshop.modpath .. "/interop.lua")

dofile(smartshop.modpath .. "/shop_display.lua")
dofile(smartshop.modpath .. "/shop_formspec.lua")
dofile(smartshop.modpath .. "/wifi_formspec.lua")
dofile(smartshop.modpath .. "/nodes.lua")
dofile(smartshop.modpath .. "/crafting.lua")
dofile(smartshop.modpath .. "/entities.lua")

minetest.register_on_player_receive_fields(function(player, form, pressed)
    if form == "smartshop.shop_showform" then
        smartshop.shop_receive_fields(player, pressed)
    elseif form == "smartshop.wifi_showform" then
        smartshop.wifi_receive_fields(player, pressed)
    end
end)
