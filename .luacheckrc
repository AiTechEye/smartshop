unused_args = false

globals = {
    "minetest",
    "smartshop"
}

read_globals = {
    string = {fields = {"split"}},
    table = {fields = {"copy", "getn", "insert_all"}},

    -- Builtin
    "vector", "ItemStack",
    "dump", "DIR_DELIM", "VoxelArea", "Settings",
}
