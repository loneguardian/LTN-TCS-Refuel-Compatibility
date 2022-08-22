-- debug detection
local debug = (__DebugAdapter and true) or false

-- require
local util = require "util"

-- localise table functions
local table = {
    deepcopy = util.table.deepcopy,
    insert = table.insert
}

-- local variables
local setting_refuel_station_name = settings.global["ltntcsr-refuel-station-name"].value
local setting_refuel_station_inactivity_condition_timeout = settings.global["ltntcsr-refuel-station-inactivity-condition-timeout"].value * 60

local trainById

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

local function initTrainById()
    local t

    global.trainById = {}
    trainById = global.trainById

    for _, f in pairs(game.forces) do
        t = f.get_trains()

        for i = 1, #t do
            trainById[t[i].id] = t[i]
        end
    end
end

-- handlers
local function on_configuration_changed(event)
    initTrainById()
    checkLtnSetting()
end

local function on_delivery_pickup_complete(event)
    -- insert new stop for train announcing delivery_pickup_complete
    local t = trainById[event.train_id]

    if t.valid then
        schedule = table.deepcopy(t.schedule)
        
        table.insert(schedule.records, refuel_station_record)

        t.schedule = schedule
    end
end

local function on_rolling_stock_removed(event)
    local train = event.entity and event.entity.train
    if train and train.valid then
        trainById[train.id] = nil

        if debug then print("handler: on_rolling_stock_removed", train.id) end
    end
end

-- rolling_stock_events switches
local handlers_rolling_stock = {
    [defines.events["on_train_created"]] = function(event)
        -- update trainById dictionary
        -- clear old IDs in dictionary
        if event.old_train_id_1 then trainById[event.old_train_id_1] = nil end
        if event.old_train_id_2 then trainById[event.old_train_id_2] = nil end

        -- create new entry
        trainById[event.train.id] = event.train

        if debug then
            print(
                "handler: on_train_created. Old IDs:",
                event.old_train_id_1,
                event.old_train_id_2,
                "New ID",
                event.train.id
            )
        end
    end,

    [defines.events["on_pre_player_mined_item"]] = on_rolling_stock_removed,

    [defines.events["on_robot_pre_mined"]] = on_rolling_stock_removed,

    [defines.events["on_entity_died"]] = on_rolling_stock_removed,

    [defines.events["script_raised_destroy"]] = on_rolling_stock_removed
}

local function on_rolling_stock_events(event)
    if not event then return end

    handlers_rolling_stock[event.name](event)
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

local filterRollingStock = {{filter = "rolling-stock"}}
script.on_event(defines.events["on_train_created"], on_rolling_stock_events)
script.on_event(defines.events["on_pre_player_mined_item"], on_rolling_stock_events, filterRollingStock)
script.on_event(defines.events["on_robot_pre_mined"], on_rolling_stock_events, filterRollingStock)
script.on_event(defines.events["on_entity_died"], on_rolling_stock_events, filterRollingStock)
script.on_event(defines.events["script_raised_destroy"], on_rolling_stock_events, filterRollingStock)

local function registerCondEvents()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), on_delivery_pickup_complete)
    end
end

script.on_configuration_changed(on_configuration_changed)

script.on_load(function ()
    registerCondEvents()
    trainById = global.trainById
end)

-- init
script.on_init(function ()
    registerCondEvents()
    initTrainById()
    checkLtnSetting()
end)

-- interface
remote.add_interface("ltn-tcs-refuel",
    {
        -- initialise train lookup table, use only if needed
        -- /c remote.call("ltn-tcs-refuel", "initTrainById")
        initTrainById = initTrainById
    }
)