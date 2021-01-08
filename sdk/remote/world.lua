----
-- Different remote world functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote.World
-- @see SDK
-- @see SDK.Remote
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local World = {}

local SDK
local Value

--- Helpers
-- @section helpers

local function DebugError(fn_name, ...)
    if SDK.Debug then
        SDK.Debug.Error(string.format("%s.%s():", tostring(World), fn_name), ...)
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

local function DebugString(...)
    if SDK.Debug then
        SDK.Debug.String("[remote]", "[world]", ...)
    end
end

--- General
-- @section general

--- Sends a request to force precipitation.
-- @tparam[opt] boolean bool
-- @treturn boolean
function World.ForcePrecipitation(bool)
    bool = bool ~= false and true or false
    DebugString("Force precipitation:", tostring(bool))
    SDK.Remote.Send('TheWorld:PushEvent("ms_forceprecipitation", %s)', { tostring(bool) })
    return true
end

--- Sends a request to push a certain event.
-- @tparam string event
-- @treturn boolean
function World.PushEvent(event)
    if not Value.IsString(event) then
        DebugErrorInvalidArg("event", "must be a string", "PushEvent")
        return false
    end

    DebugString("Push event:", event)
    SDK.Remote.Send('TheWorld:PushEvent("%s")', { event })
    return true
end

--- Sends a world rollback request to server.
-- @tparam number days
-- @treturn boolean
function World.Rollback(days)
    days = days ~= nil and days or 0

    if not Value.IsUnsigned(days) or not Value.IsInteger(days) then
        DebugErrorInvalidArg("days", "must be an unsigned integer", "Rollback")
        return false
    end

    DebugString("Rollback:", Value.ToDaysString(days))
    SDK.Remote.Send("TheNet:SendWorldRollbackRequestToServer(%d)", { days })
    return true
end

--- Sends a request to send a lightning strike.
-- @tparam Vector3 pt Point
-- @treturn boolean
function World.SendLightningStrike(pt)
    if not TheWorld:HasTag("forest") then
        DebugErrorInvalidWorldType("must be in a forest", "SendLightningStrike")
        return false
    end

    if not Value.IsPoint(pt) then
        DebugErrorInvalidArg("pt", "must be a point", "SendLightningStrike")
        return false
    end

    local pt_string = string.format("Vector3(%0.2f, %0.2f, %0.2f)", pt.x, pt.y, pt.z)
    DebugString("Send lighting strike:", tostring(pt))
    SDK.Remote.Send('TheWorld:PushEvent("ms_sendlightningstrike", %s)', { pt_string })
    return true
end

--- Sends a request to set a delta moisture.
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaMoisture(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("delta", "must be a number", "SetDeltaMoisture")
        return false
    end

    DebugString("Delta moisture:", Value.ToFloatString(delta))
    SDK.Remote.Send('TheWorld:PushEvent("ms_deltamoisture", %d)', { delta })
    return true
end

--- Sends a request to set a delta wetness.
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaWetness(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("delta", "must be a number", "SetDeltaWetness")
        return false
    end

    DebugString("Delta wetness:", Value.ToFloatString(delta))
    SDK.Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
    return true
end

--- Sends a request to set a season.
-- @tparam string season
-- @treturn boolean
function World.SetSeason(season)
    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            "season",
            "must be a season: autumn, winter, spring or summer",
            "SetSeason"
        )
        return false
    end

    DebugString("Season:", tostring(season))
    SDK.Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { season })
    return true
end

--- Sends a request to set a season length.
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function World.SetSeasonLength(season, length)
    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            "season",
            "must be a season: autumn, winter, spring or summer",
            "SetSeasonLength"
        )
        return false
    end

    if not Value.IsUnsigned(length) or not Value.IsInteger(length) then
        DebugErrorInvalidArg("length", "must be an unsigned integer", "SetSeasonLength")
        return false
    end

    DebugString("Season length:", season, "(" .. Value.ToDaysString(length) .. ")")
    SDK.Remote.Send(
        'TheWorld:PushEvent("ms_setseasonlength", { season = "%s", length = %d })',
        { season, length }
    )

    return true
end

--- Sends a request to set a snow level.
-- @tparam number delta
-- @treturn boolean
function World.SetSnowLevel(delta)
    delta = delta ~= nil and delta or 0

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType("must be in a forest", "SetSnowLevel")
        return false
    end

    if Value.IsUnitInterval(delta) then
        DebugString("Snow level:", tostring(delta))
        SDK.Remote.Send('TheWorld:PushEvent("ms_setsnowlevel", %0.2f)', { delta })
        return true
    end

    DebugErrorInvalidArg("delta", "must be a unit interval", "SetSnowLevel")
    return false
end

--- Sends a request to set a time scale.
-- @see SDK.World.Pause
-- @see SDK.World.SetTimeScale
-- @see SDK.World.Resume
-- @tparam string timescale
-- @treturn boolean
function World.SetTimeScale(timescale)
    if not Value.IsUnsigned(timescale) or not Value.IsNumber(timescale) then
        DebugErrorInvalidArg("timescale", "must be an unsigned number", "SetTimeScale")
        return false
    end

    DebugString("Time scale:", Value.ToFloatString(timescale))
    SDK.Remote.Send('TheSim:SetTimeScale(%0.2f)', { timescale })
    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Remote.World
function World._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return World
end

return World
