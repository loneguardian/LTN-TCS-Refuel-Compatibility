data:extend({
    {
        type = "string-setting",
        name = "tcsltn-refuel-station-name",
        order = "a",
        setting_type = "runtime-global",
        default_value = "Fuel [virtual-signal=refuel-signal]"
    },
    {
        type = "int-setting",
        name = "tcsltn-refuel-station-inactivity-condition-timeout",
        order = "b",
        setting_type = "runtime-global",
        default_value = 2,
        minimum_value = 1,
        maximum_value = 60
    }
})