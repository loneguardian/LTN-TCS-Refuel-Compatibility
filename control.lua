-- settings
local enabled_for_ltn = settings.global["ltntcsr-enable-for-ltn"].value
local enabled_for_cybersyn = settings.global["ltntcsr-enable-for-cybersyn"].value
local setting_refuel_station_name = settings.global["ltntcsr-refuel-station-name"].value
local setting_refuel_station_inactivity_condition_timeout = settings.global["ltntcsr-refuel-station-inactivity-condition-timeout"].value * 60

-- refuel stop record
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

-- check setting
local function check_ltn_setting()
    local key = "ltn-dispatcher-requester-delivery-reset"
    if settings.global[key].value then
        game.print({"console-message.ltn-setting-warning", game.mod_setting_prototypes[key].localised_name})
    end
end

local function check_cybersyn_setting()
    local key = "cybersyn-depot-bypass-threshold"
    local value = settings.global[key].value
    if value and value < 1 then
        game.print({"console-message.cybersyn-setting-warning", game.mod_setting_prototypes[key].localised_name})
    end
end

-- handlers
local function add_refuel_stop(train)
    if train and train.valid then
        local schedule = train.schedule
        local records = schedule.records
        records[#records+1] = refuel_station_record
        train.schedule = schedule
    end
end

local function on_ltn_delivery_pickup_complete(event)
    add_refuel_stop(event.train)
end

local global_trains
local function on_cybersyn_train_dispatched(event)
    local cybersyn_train = remote.call("cybersyn", "get_train", event.train_id)
    if not cybersyn_train then return end
    local train_entity = cybersyn_train.entity
    global_trains[event.train_id] = {
        train = train_entity,
        mod = "cybersyn",
        is_in_refuel_stop = false,
        dispatched_at = game.tick
    }
    add_refuel_stop(train_entity)
end

---@param event EventData.on_train_changed_state
local function on_train_changed_state(event)
    local train = event.train
    local train_state = train.state
    if train_state == defines.train_state.wait_station then
        local station = train.station
        if station and station.backer_name == setting_refuel_station_name then
            local refuel_train = global_trains[train.id]
            -- update refuel_train state
            if refuel_train then
                refuel_train.is_in_refuel_stop = true
            end
        end
    elseif event.old_state == defines.train_state.wait_station then
        local train_id = train.id
        local refuel_train = global_trains[train_id]
        -- check if train was in refuel stop
        if refuel_train and refuel_train.is_in_refuel_stop then
            -- state can be cleared once a train is no longer waiting at refuel stop
            global_trains[train_id] = nil
            -- post refuel behaviour
            if enabled_for_cybersyn and refuel_train.mod == "cybersyn" then
                remote.call("cybersyn", "add_available_train", train_id)
            end
        end
    end
end

local function register_remote_events(arg)
    if (arg == nil or arg == "ltn") and remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), enabled_for_ltn and on_ltn_delivery_pickup_complete or nil)
    end
    if (arg == nil or arg == "cybersyn") and remote.interfaces["cybersyn"] then
        script.on_event(defines.events.on_train_changed_state, enabled_for_cybersyn and on_train_changed_state or nil)
        script.on_event(remote.call("cybersyn", "get_on_train_dispatched"), enabled_for_cybersyn and on_cybersyn_train_dispatched or nil)
    end
end

local setting_handler = {
    ["ltntcsr-enable-for-ltn"] = function(setting_name)
        enabled_for_ltn = settings.global[setting_name].value
        register_remote_events("ltn")
    end,
    ["ltntcsr-enable-for-cybersyn"] = function(setting_name)
        enabled_for_cybersyn = settings.global[setting_name].value
        register_remote_events("cybersyn")
    end,
    ["ltn-dispatcher-requester-delivery-reset"] = function()
        check_ltn_setting()
    end,
    ["cybersyn-depot-bypass-threshold"] = function()
        check_cybersyn_setting()
    end,
    ["ltntcsr-refuel-station-name"] = function(setting_name)
        setting_refuel_station_name = settings.global[setting_name].value
        refuel_station_record.station = setting_refuel_station_name
    end,
    ["ltntcsr-refuel-station-inactivity-condition-timeout"] = function(setting_name)
        setting_refuel_station_inactivity_condition_timeout = settings.global[setting_name].value * 60
        refuel_station_record.wait_conditions[1].ticks = setting_refuel_station_inactivity_condition_timeout
    end,
}

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local setting_name = event.setting
    local handler = setting_handler[setting_name]
    if handler then handler(setting_name) end
end)

local function check_other_mods_setting()
    if enabled_for_ltn and script.active_mods["logistic-train-network"] then check_ltn_setting() end
    if enabled_for_cybersyn and script.active_mods["cybersyn"] then check_cybersyn_setting() end
end
local function localise_global()
    global_trains = global.trains
end
local function on_load()
    register_remote_events()
    localise_global()
end
local function init_globals()
    global.trains = global.trains or {}
    localise_global()
end
script.on_init(function ()
    init_globals()
    on_load()
    check_other_mods_setting()
end)
script.on_load(on_load)

local function on_configuration_changed()
    -- remove trainById (0.2.0)
    global.trainById = nil

    -- remove trains_in_refuel_stop (0.3.0.internal)
    global.trains_in_refuel_stop = nil

    init_globals()
    check_other_mods_setting()
end
script.on_configuration_changed(on_configuration_changed)

-- clean up global every 10 minutes
local timeout = 36000
script.on_nth_tick(timeout, function(event)
    for train_id, state in pairs(global_trains) do
        if not (state.train and state.train.valid)
        or (event.tick - state.dispatched_at >= timeout) then
            global_trains[train_id] = nil
        end
    end
end)