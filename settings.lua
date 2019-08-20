smartshop.settings = {}

local settings = minetest.settings

smartshop.settings.max_wifi_distance = tonumber(settings:get('smartshop.max_wifi_distance')) or 30
smartshop.settings.has_mesecon = minetest.global_exists("mesecon")
smartshop.settings.has_currency = minetest.global_exists("currency")

