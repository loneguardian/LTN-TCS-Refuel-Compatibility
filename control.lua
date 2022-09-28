-- debug detection
local debug = (__DebugAdapter and true) or false

-- require
local util = require "util"

local table = {
    deepcopy = util.table.deepcopy,
    insert = table.insert
}

-- local variables
local setting_refuel_station_name = settings.global["ltntcsr-refuel-station-name"].value
local setting_refuel_station_inactivity_condition_timeout = settings.global["ltntcsr-refuel-station-inactivity-condition-timeout"].value * 60

local schedule
local refuel_station_record = {
    station = setting_refuel_station_name,
    wait_conditions = {
        {   
            compare_type = "and",
            type = "inactivity",
            ticks = setting_refuel_station_inactivity_condition_timeout
        }
    }
}

-- local functions
local function checkLtnSetting()
    if settings.global["ltn-dispatcher-requester-delivery-reset"].value then
        game.print({"console-message.ltn-setting-warning", game.mod_setting_prototypes["ltn-dispatcher-requester-delivery-reset"].localised_name})
    end
end

-- handlers
local function on_configuration_changed()
    -- remove trainById (0.2.0)
    if global.trainById then global.trainById = nil end

    checkLtnSetting()
end

local function on_delivery_pickup_complete(event)
    -- insert new stop for train announcing delivery_pickup_complete
    local t = event.train

    if t.valid then
        schedule = table.deepcopy(t.schedule)
        
        table.insert(schedule.records, refuel_station_record)

        t.schedule = schedule
    end
end

local function on_setting_changed(event)
    local settingName = event.setting

    if settingName == "ltn-dispatcher-requester-delivery-reset" then
        checkLtnSetting()
    elseif settingName == "ltntcsr-refuel-station-name" then
        setting_refuel_station_name = settings.global[settingName].value
        refuel_station_record.station = setting_refuel_station_name
    elseif settingName == "ltntcsr-refuel-station-inactivity-condition-timeout" then
        setting_refuel_station_inactivity_condition_timeout = settings.global[settingName].value * 60
        refuel_station_record.wait_conditions[1].ticks = setting_refuel_station_inactivity_condition_timeout
    end
end

-- register handlers
script.on_event(defines.events["on_runtime_mod_setting_changed"], on_setting_changed)

local function registerCondEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end
end

script.on_configuration_changed(on_configuration_changed)

script.on_load(function ()
    registerCondEvents()
end)

-- init
script.on_init(function ()
    registerCondEvents()
    checkLtnSetting()
end)