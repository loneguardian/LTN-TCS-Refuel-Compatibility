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

local function init_globals()
    global.trains_in_refuel_stop = global.trains_in_refuel_stop or {}
end

-- handlers
local function on_configuration_changed()
    -- remove trainById (0.2.0)
    if global.trainById then global.trainById = nil end

    init_globals()

    if enabled_for_ltn and script.active_mods["logistic-train-network"] then check_ltn_setting() end
    if enabled_for_cybersyn and script.active_mods["cybersyn"] then check_cybersyn_setting() end
end

-- upvalues
local train, train_id, station, schedule, records

local function add_refuel_stop()
    schedule = train.schedule
    records = schedule.records
    records[#records+1] = refuel_station_record
    train.schedule = schedule
end

local function on_ltn_delivery_pickup_complete(event)
    -- insert new stop for train announcing delivery_pickup_complete
    train = event.train
    if train.valid then
        add_refuel_stop()
    end
end

local cybersyn_train
local function on_cybersyn_train_dispatched(event)
    train_id = event.train_id
    cybersyn_train = remote.call("cybersyn", "get_train", train_id)
    if not cybersyn_train then return end
    train = cybersyn_train.entity
    if train and train.valid then
        add_refuel_stop()
    end
end

---@param event EventData.on_train_changed_state
local function on_train_changed_state(event)
    if event.old_state == defines.train_state.arrive_station then -- train is wait_station?
        train = event.train
        station = train.station
        if station and station.backer_name == setting_refuel_station_name then
            -- store train in global
            global.trains_in_refuel_stop[train.id] = true
        end
    elseif event.old_state == defines.train_state.wait_station then -- train is on_the_path / something else
        train = event.train
        train_id = train.id
        -- check if train was in refuel stop
        if global.trains_in_refuel_stop[train_id] then
            remote.call("cybersyn", "add_available_train", train_id)
            global.trains_in_refuel_stop[train_id] = nil
        end
    end
end

local function register_remote_events()
    if remote.interfaces["logistic-train-network"] then
        script.on_event(remote.call("logistic-train-network", "on_delivery_pickup_complete"), enabled_for_ltn and on_ltn_delivery_pickup_complete or nil)
    end
    if remote.interfaces["cybersyn"] then
        script.on_event(defines.events.on_train_changed_state, enabled_for_cybersyn and on_train_changed_state or nil)
        script.on_event(remote.call("cybersyn", "get_on_train_dispatched"), enabled_for_cybersyn and on_cybersyn_train_dispatched or nil)
    end
end

local setting_handler = {
    ["ltntcsr-enable-for-ltn"] = function(setting_name)
        enabled_for_ltn = settings.global[setting_name].value
        register_remote_events()
    end,
    ["ltntcsr-enable-for-cybersyn"] = function(setting_name)
        enabled_for_cybersyn = settings.global[setting_name].value
        register_remote_events()
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

local function on_setting_changed(event)
    local setting_name = event.setting
    local handler = setting_handler[event.setting]
    if handler then handler(setting_name) end
end

-- register handlers
script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)

script.on_configuration_changed(on_configuration_changed)

script.on_load(function ()
    register_remote_events()
end)

-- init
script.on_init(function ()
    init_globals()
    register_remote_events()

    if script.active_mods["logistic-train-network"] then check_ltn_setting() end
    if script.active_mods["cybersyn"] then check_cybersyn_setting() end
end)