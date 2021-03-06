---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 10/8/20 2:36 AM
---

data:extend {
    {
        type = "int-setting",
        setting_type = "runtime-per-user",
        name = "path-finding-test-per-tick",
        default_value = 15,
        minimum_value = 1,
        maximum_value = 100
    },
    {
        type = "int-setting",
        setting_type = "runtime-per-user",
        name = "max-path-finding-explore-num",
        default_value = 10000,
        minimum_value = 1000,
        maximum_value = 1000000
    },
    {
        type = "double-setting",
        setting_type = "runtime-per-user",
        name = "greedy-level",
        default_value = 1.1,
        minimum_value = 1,
        maximum_value = 2
    },
    {
        type = "double-setting",
        setting_type = "runtime-per-user",
        name = "prefer-ground-mode-underground-punishment",
        default_value = 5,
    },
    {
        type = "double-setting",
        setting_type = "runtime-per-user",
        name = "turning-punishment",
        default_value = 2,
    },
    {
        type = "bool-setting",
        setting_type = "runtime-per-user",
        name = "force-build",
        default_value = true
    },
    {
        type = "string-setting",
        setting_type = "runtime-per-user",
        default_value = "last-mode",
        name = "waypoint-mode-routing-mode",
        allowed_values = { "last-mode", "prefer-on-ground-mode", "prefer-underground-mode", "no-underground-mode" },
    },
    {
        type = "bool-setting",
        setting_type = "runtime-per-user",
        name = "cheat-mode-place-real-entity",
        default_value = true
    },
    {
        type = "bool-setting",
        setting_type = "runtime-per-user",
        name = "prefer-longest-underground",
        default_value = true
    }
}