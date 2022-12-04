data:extend({
    {
        type = "bool-setting",
        name = "ltntcsr-enable-for-ltn",
        order = "aa",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "ltntcsr-enable-for-cybersyn",
        order = "ab",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "string-setting",
        name = "ltntcsr-refuel-station-name",
        order = "b",
        setting_type = "runtime-global",
        default_value = "Fuel [virtual-signal=refuel-signal]"
    },
    {
        type = "int-setting",
        name = "ltntcsr-refuel-station-inactivity-condition-timeout",
        order = "c",
        setting_type = "runtime-global",
        default_value = 2,
        minimum_value = 1,
        maximum_value = 60
    }
})