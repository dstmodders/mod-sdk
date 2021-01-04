----
-- Different remote player functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote.Player
-- @see SDK
-- @see SDK.Remote
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Player = {}

local SDK
local Value

--- Helpers
-- @section helpers

local function DebugError(fn_name, ...)
    if SDK.Debug then
        SDK.Debug.Error(string.format("%s.%s():", tostring(Player), fn_name), ...)
    end
end

local function DebugErrorInvalidArg(arg_name, explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    DebugError(
        fn_name,
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

local function DebugErrorInvalidWorldType(explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    DebugError(fn_name, "Invalid world type", explanation and "(" .. explanation .. ")")
end

local function DebugErrorPlayerIsGhost(fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    DebugError(fn_name, "Player shouldn't be a ghost")
end

local function DebugString(...)
    if SDK.Debug then
        SDK.Debug.String("[remote]", "[player]", ...)
    end
end

local function IsValidPlayerAlive(player, fn_name)
    if not Value.IsPlayer(player) then
        DebugErrorInvalidArg("player", "must be a player", fn_name)
        return false
    end

    if player:HasTag("playerghost") then
        DebugErrorPlayerIsGhost(fn_name)
        return false
    end

    return true
end

local function IsValidSetPlayerAttributePercent(percent, player, fn_name)
    if not Value.IsPercent(percent) then
        DebugErrorInvalidArg("percent", "must be a percent", fn_name)
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    return true
end

--- General
-- @section general

--- Sends a request to send a mini earthquake.
-- @tparam[opt] number radius Default: 20
-- @tparam[opt] number amount Default: 20
-- @tparam[opt] number duration Default: 2.5
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SendMiniEarthquake(radius, amount, duration, player)
    radius = radius ~= nil and radius or 20
    amount = amount ~= nil and amount or 20
    duration = duration ~= nil and duration or 2.5
    player = player ~= nil and player or ThePlayer

    if not TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType("must be in a cave", "SendMiniEarthquake")
        return false
    end

    if not Value.IsPlayer(player) then
        DebugErrorInvalidArg("player", "must be a player", "SendMiniEarthquake")
        return false
    end

    if not Value.IsUnsigned(radius) or not Value.IsInteger(radius) then
        DebugErrorInvalidArg("radius", "must be an unsigned integer", "SendMiniEarthquake")
        return false
    end

    if not Value.IsUnsigned(amount) or not Value.IsInteger(amount) then
        DebugErrorInvalidArg("amount", "must be an unsigned integer", "SendMiniEarthquake")
        return false
    end

    if not Value.IsUnsigned(duration) or not Value.IsNumber(duration) then
        DebugErrorInvalidArg("duration", "must be an unsigned number", "SendMiniEarthquake")
        return false
    end

    DebugString("Send mini earthquake:", player:GetDisplayName())
    SDK.Remote.Send(
        'TheWorld:PushEvent("ms_miniquake", { target = LookupPlayerInstByUserID("%s"), rad = %d, num = %d, duration = %0.2f })', -- luacheck: only
        { player.userid, radius, amount, duration }
    )

    return true
end

--- Attributes
-- @section attributes

--- Sends a request to set a health limit percent.
-- @tparam number percent Health limit percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthLimitPercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetHealthLimitPercent") then
        return false
    end

    DebugString(
        "Player health limit:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.health then player.components.health:SetPenalty(%0.2f) end', -- luacheck: only
        { player.userid, 1 - (percent / 100) }
    )

    return true
end

--- Sends a request to set a health percent.
-- @tparam number percent Health percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthPercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetHealthPercent") then
        return false
    end

    DebugString(
        "Player health:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.health then player.components.health:SetPercent(math.min(%0.2f, 1)) end', -- luacheck: only
        { player.userid, percent / 100 }
    )

    return true
end

--- Sends a request to set a hunger percent.
-- @tparam number percent Hunger percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHungerPercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetHungerPercent") then
        return false
    end

    DebugString(
        "Player hunger:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.hunger then player.components.hunger:SetPercent(math.min(%0.2f, 1)) end', -- luacheck: only
        { player.userid, percent / 100 }
    )

    return true
end

--- Sends a request to set a moisture percent.
-- @tparam number percent Moisture percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetMoisturePercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetMoisturePercent") then
        return false
    end

    DebugString(
        "Player moisture:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.moisture then player.components.moisture:SetPercent(math.min(%0.2f, 1)) end', -- luacheck: only
        { player.userid, percent / 100 }
    )

    return true
end

--- Sends a request to set a sanity percent.
-- @tparam number percent Sanity percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetSanityPercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetSanityPercent") then
        return false
    end

    DebugString(
        "Player sanity:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.sanity then player.components.sanity:SetPercent(math.min(%0.2f, 1)) end', -- luacheck: only
        { player.userid, percent / 100 }
    )

    return true
end

--- Sends a request to set a temperature.
-- @tparam number temperature Temperature percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetTemperature(temperature, player)
    player = player ~= nil and player or ThePlayer

    if not Value.IsEntityTemperature(temperature) then
        DebugErrorInvalidArg("value", "must be an entity temperature", "SetTemperature")
        return false
    end

    if not IsValidPlayerAlive(player, "SetTemperature") then
        return false
    end

    DebugString(
        "Player temperature:",
        Value.ToDegreeString(temperature),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.temperature then player.components.temperature:SetTemperature(%0.2f) end', -- luacheck: only
        { player.userid, temperature }
    )

    return true
end

--- Sends a request to set a wereness percent.
-- @tparam number percent Wereness percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetWerenessPercent(percent, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidSetPlayerAttributePercent(percent, player, "SetWerenessPercent") then
        return false
    end

    if not player:HasTag("werehuman") then
        DebugError("SetWerenessPercent", "Player should be a Woodie")
        return false
    end

    DebugString(
        "Player wereness:",
        Value.ToPercentString(percent),
        "(" .. player:GetDisplayName() .. ")"
    )

    SDK.Remote.Send(
        'player = LookupPlayerInstByUserID("%s") if player.components.wereness then player.components.wereness:SetPercent(math.min(%0.2f, 1)) end', -- luacheck: only
        { player.userid, percent / 100 }
    )

    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Remote.Player
function Player._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return Player
end

return Player
