local settings = minetest.settings

smartshop.settings = {
	history_max = tonumber(settings:get("smartshop.history_max")) or 60,
    storage_max_distance = tonumber(settings:get("smartshop.storage_max_distance")) or 30,
	storage_link_time = tonumber(settings:get("smartshop.storage_link_time")) or 30,
    entity_reaction_distance_xz = tonumber(settings:get("smartshop.entity_reaction_distance_xz")) or 8,
    entity_reaction_distance_y = tonumber(settings:get("smartshop.entity_reaction_distance_y")) or 3,

    change_currency = settings:get_bool("smartshop.change_currency", true),
	enable_refund = settings:get_bool("smartshop.enable_refund", true),

	admin_shop_priv = settings:get("smartshop.admin_shop_priv") or "smartshop_admin",

    -- crash, announce, log
    error_behavior = settings:get("smartshop.error_behavior") or "announce",

    enable_tests = settings:get_bool("smartshop.enable_tests", false),
}

if not minetest.registered_privileges[smartshop.settings.admin_shop_priv] then
    minetest.register_privilege(smartshop.settings.admin_shop_priv, {
        description = "Smartshop admin",
        give_to_singleplayer = false,
        give_to_admin = false,
    })
end
