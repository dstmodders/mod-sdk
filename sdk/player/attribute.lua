----
-- Handles getting or setting different player attributes.
--
-- _**NB!** Requires_ `SDK.Remote.Player` _to be loaded to work on dedicated servers with
-- administrator rights._
--
-- On master instances, it tries to set an attribute locally by calling the corresponding component
-- function. On non-master instances (dedicated servers) it calls the corresponding
-- `SDK.Remote.Player` function for sending a request to change that attribute.
--
--     if SDK.Player.Attribute.GetTemperature(ThePlayer) <= 0 then
--         SDK.Player.Attribute.SetTemperature(36, ThePlayer)
--     end
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Player.Attribute
-- @see SDK.Player
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Attribute = {}

local SDK
local Value

--- Helpers
-- @section helpers

local function ArgPlayer(fn_name, value)
    return SDK._ArgPlayer(Attribute, fn_name, value)
end

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Attribute, fn_name, ...)
end

local function DebugErrorInvalidArg(fn_name, arg_name, explanation)
    SDK._DebugErrorInvalidArg(Attribute, fn_name, arg_name, explanation)
end

local function DebugErrorNoPlayerGhost(fn_name)
    SDK._DebugErrorNoPlayerGhost(Attribute, fn_name)
end

local function DebugString(...)
    SDK._DebugString("[player]", "[attribute]", ...)
end

local function GetComponent(fn_name, entity, name)
    return SDK._GetComponent(Attribute, fn_name, entity, name)
end

local function GetReplica(fn_name, entity, name)
    return SDK._GetReplica(Attribute, fn_name, entity, name)
end

local function IsValidPlayer(player, fn_name)
    if not Value.IsPlayer(player) then
        DebugErrorInvalidArg(fn_name, "player", "must be a player")
        return false
    end
    return true
end

local function IsValidPlayerAlive(player, fn_name)
    if not IsValidPlayer(player, fn_name) then
        return false
    end

    if player:HasTag("playerghost") then
        DebugErrorNoPlayerGhost(fn_name)
        return false
    end

    return true
end

local function IsValidSetAttributePercent(percent, player, fn_name)
    if not Value.IsPercent(percent) then
        DebugErrorInvalidArg(fn_name, "percent", "must be a percent")
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    return true
end

local function SetAttributeComponentPercent(fn_name, options, percent, player)
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    local component = type(options) == "table" and options.component or options
    local post_validation_fn = type(options) == "table" and options.post_validation_fn
    local pre_validation_fn = type(options) == "table" and options.pre_validation_fn
    local validation_fn = type(options) == "table" and options.validation_fn

    local debug_args = type(options) == "table" and options.debug_args
        or {
            component:gsub("^%l", string.upper) .. ":",
            Value.ToPercentString(percent),
        }

    local setter_fn = type(options) == "table" and options.setter_fn
        or function(_component, value)
            _component:SetPercent(math.min(value / 100, 1))
        end

    if
        (pre_validation_fn and not pre_validation_fn(percent, player))
        or (validation_fn and not validation_fn(percent, player))
        or (not validation_fn and not IsValidSetAttributePercent(percent, player, fn_name))
        or (post_validation_fn and not post_validation_fn(percent, player))
    then
        return false
    end

    if TheWorld.ismastersim then
        local _component = GetComponent(fn_name, player, component)
        if not _component then
            return false
        end

        table.insert(debug_args, "(" .. player:GetDisplayName() .. ")")
        DebugString(unpack(debug_args))
        setter_fn(_component, percent)
        return true
    end

    return SDK.Remote.Player[fn_name](percent, player)
end

--- Get
-- @section get

--- Gets a health limit percent value.
--
-- Maximum health when the penalty has been applied.
--
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn number
function Attribute.GetHealthLimitPercent(player)
    local fn_name = "GetHealthLimitPercent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    local replica = GetReplica(fn_name, player, "health")
    local penalty = SDK.Utils.Chain.Get(replica, "GetPenaltyPercent", true)
    return penalty and (1 - penalty) * 100
end

--- Gets a health penalty percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetHealthPenaltyPercent(player)
    local fn_name = "GetHealthPenaltyPercent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    local replica = GetReplica(fn_name, player, "health")
    local penalty = SDK.Utils.Chain.Get(replica, "GetPenaltyPercent", true)
    return penalty and penalty * 100
end

--- Gets a health percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetHealthPercent(player)
    local fn_name = "GetHealthPercent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    local replica = GetReplica(fn_name, player, "health")
    local health = SDK.Utils.Chain.Get(replica, "GetPercent", true)
    return health and health * 100
end

--- Gets a hunger percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetHungerPercent(player)
    local fn_name = "GetHungerPercent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    local replica = GetReplica(fn_name, player, "hunger")
    local hunger = SDK.Utils.Chain.Get(replica, "GetPercent", true)
    return hunger and hunger * 100
end

--- Gets a moisture percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetMoisturePercent(player)
    player = ArgPlayer("GetMoisturePercent", player)
    return SDK.Utils.Chain.Get(player, "GetMoisture", true)
end

--- Gets a sanity percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetSanityPercent(player)
    local fn_name = "GetSanityPercent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    local replica = GetReplica(fn_name, player, "sanity")
    local sanity = SDK.Utils.Chain.Get(replica, "GetPercent", true)
    return sanity and sanity * 100
end

--- Gets a temperature value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetTemperature(player)
    player = ArgPlayer("GetTemperature", player)
    return SDK.Utils.Chain.Get(player, "GetTemperature", true)
end

--- Gets a wereness percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.GetWerenessPercent(player)
    player = ArgPlayer("GetWerenessPercent", player)
    return SDK.Utils.Chain.Get(player, "player_classified", "currentwereness", "value", true)
end

--- Set
-- @section set

--- Sets a health limit percent value.
-- @see SDK.Remote.Player.SetHealthLimitPercent
-- @tparam number percent Health limit percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Attribute.SetHealthLimitPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthLimitPercent", {
        component = "health",
        debug_args = { "Health limit:", Value.ToPercentString(percent) },
        setter_fn = function(component, value)
            component:SetPenalty(1 - (value / 100))
        end,
    }, percent, player)
end

--- Sets a health penalty percent value.
-- @see SDK.Remote.Player.SetHealthPenaltyPercent
-- @tparam number percent Health penalty percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Attribute.SetHealthPenaltyPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPenaltyPercent", {
        component = "health",
        debug_args = { "Health penalty:", Value.ToPercentString(percent) },
        setter_fn = function(component, value)
            component:SetPenalty(value / 100)
        end,
    }, percent, player)
end

--- Sets a health percent value.
-- @see SDK.Remote.Player.SetHealthPercent
-- @tparam number percent Health percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetHealthPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPercent", "health", percent, player)
end

--- Sets a hunger percent value.
-- @see SDK.Remote.Player.SetHungerPercent
-- @tparam number percent Hunger percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetHungerPercent(percent, player)
    return SetAttributeComponentPercent("SetHungerPercent", "hunger", percent, player)
end

--- Sets a moisture percent value.
-- @see SDK.Remote.Player.SetMoisturePercent
-- @tparam number percent Moisture percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetMoisturePercent(percent, player)
    return SetAttributeComponentPercent("SetMoisturePercent", "moisture", percent, player)
end

--- Sets a sanity percent value.
-- @see SDK.Remote.Player.SetSanityPercent
-- @tparam number percent Sanity percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetSanityPercent(percent, player)
    return SetAttributeComponentPercent("SetSanityPercent", "sanity", percent, player)
end

--- Sets a temperature value.
-- @see SDK.Remote.Player.SetTemperature
-- @tparam number temperature Temperature
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetTemperature(temperature, player)
    local fn_name = "SetTemperature"
    player = ArgPlayer(fn_name, player)

    if not Value.IsEntityTemperature(temperature) then
        DebugErrorInvalidArg(fn_name, "temperature", "must be an entity temperature")
        return false
    end

    if not player then
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    if TheWorld.ismastersim then
        local component = GetComponent(fn_name, player, "temperature")
        if not component then
            return false
        end

        DebugString(
            "Temperature:",
            Value.ToDegreeString(temperature),
            "(" .. player:GetDisplayName() .. ")"
        )
        component:SetTemperature(temperature)
        return true
    end

    return SDK.Remote.Player.SetTemperature(temperature, player)
end

--- Sets a wereness percent value.
-- @see SDK.Remote.Player.SetWerenessPercent
-- @tparam number percent Wereness percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Attribute.SetWerenessPercent(percent, player)
    return SetAttributeComponentPercent("SetWerenessPercent", {
        component = "wereness",
        post_validation_fn = function(_, _player)
            if not _player:HasTag("werehuman") then
                DebugErrorFn("SetWerenessPercent", "Player should be a Woodie")
                return false
            end
            return true
        end,
    }, percent, player)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player.Attribute
function Attribute._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return Attribute
end

return Attribute
