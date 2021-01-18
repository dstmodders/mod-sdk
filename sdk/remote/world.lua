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
local Remote
local Value

--- Helpers
-- @section helpers

local function DebugErrorInvalidArg(...)
    SDK._DebugErrorInvalidArg(World, ...)
end

local function DebugErrorInvalidWorldType(...)
    SDK._DebugErrorInvalidWorldType(World, ...)
end

local function DebugString(...)
    SDK._DebugString("[remote]", "[world]", ...)
end

--- General
-- @section general

--- Sends a request to force precipitation.
-- @tparam[opt] boolean bool
-- @treturn boolean
function World.ForcePrecipitation(bool)
    bool = bool ~= false and true or false
    DebugString("Force precipitation:", tostring(bool))
    Remote.Send('TheWorld:PushEvent("ms_forceprecipitation", %s)', { tostring(bool) })
    return true
end

--- Sends a request to push a certain event.
--
-- @usage SDK.Remote.World.PushEvent("ms_advanceseason")
-- -- TheWorld:PushEvent("ms_advanceseason")
--
-- @usage SDK.Remote.World.PushEvent("ms_forceprecipitation", true)
-- -- TheWorld:PushEvent("ms_advanceseason", true)
--
-- @usage SDK.Remote.World.PushEvent("ms_setseasonlength", { season = "autumn", length = 20 })
-- -- TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 20 })
--
-- @tparam string event
-- @tparam[opt] table options
-- @treturn boolean
function World.PushEvent(event, options)
    if not Value.IsString(event) then
        DebugErrorInvalidArg("PushEvent", "event", "must be a string")
        return false
    end

    if options then
        Remote.Send('TheWorld:PushEvent(%s, %s)', { event, options }, true)
        return true
    end

    Remote.Send('TheWorld:PushEvent("%s")', { event })
    return true
end

--- Sends a world rollback request to server.
-- @tparam number days
-- @treturn boolean
function World.Rollback(days)
    days = days ~= nil and days or 0

    if not Value.IsUnsigned(days) or not Value.IsInteger(days) then
        DebugErrorInvalidArg("Rollback", "days", "must be an unsigned integer")
        return false
    end

    DebugString("Rollback:", Value.ToDaysString(days))
    Remote.Send("TheNet:SendWorldRollbackRequestToServer(%d)", { days })
    return true
end

--- Sends a request to send a lightning strike.
-- @tparam Vector3 pt Point
-- @treturn boolean
function World.SendLightningStrike(pt)
    local fn_name = "SendLightningStrike"

    if not TheWorld:HasTag("forest") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    if not Value.IsPoint(pt) then
        DebugErrorInvalidArg(fn_name, "pt", "must be a point")
        return false
    end

    local pt_string = string.format("Vector3(%0.2f, %0.2f, %0.2f)", pt.x, pt.y, pt.z)
    DebugString("Send lighting strike:", tostring(pt))
    Remote.Send('TheWorld:PushEvent("ms_sendlightningstrike", %s)', { pt_string })
    return true
end

--- Sends a request to set a delta moisture.
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaMoisture(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("SetDeltaMoisture", "delta", "must be a number")
        return false
    end

    DebugString("Delta moisture:", Value.ToFloatString(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltamoisture", %d)', { delta })
    return true
end

--- Sends a request to set a delta wetness.
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaWetness(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("SetDeltaWetness", "delta", "must be a number")
        return false
    end

    DebugString("Delta wetness:", Value.ToFloatString(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
    return true
end

--- Sends a request to set a season.
-- @tparam string season
-- @treturn boolean
function World.SetSeason(season)
    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            "SetSeason",
            "season",
            "must be a season: autumn, winter, spring or summer"
        )
        return false
    end

    DebugString("Season:", tostring(season))
    Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { season })
    return true
end

--- Sends a request to set a season length.
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function World.SetSeasonLength(season, length)
    local fn_name = "SetSeasonLength"

    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            fn_name,
            "season",
            "must be a season: autumn, winter, spring or summer"
        )
        return false
    end

    if not Value.IsUnsigned(length) or not Value.IsInteger(length) then
        DebugErrorInvalidArg(fn_name, "length", "must be an unsigned integer")
        return false
    end

    DebugString("Season length:", season, "(" .. Value.ToDaysString(length) .. ")")
    Remote.Send(
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

    local fn_name = "SetSnowLevel"

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    if Value.IsUnitInterval(delta) then
        DebugString("Snow level:", tostring(delta))
        Remote.Send('TheWorld:PushEvent("ms_setsnowlevel", %0.2f)', { delta })
        return true
    end

    DebugErrorInvalidArg(fn_name, "delta", "must be a unit interval")
    return false
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam SDK.Remote parent
-- @treturn SDK.Remote.World
function World._DoInit(sdk, parent)
    SDK = sdk
    Remote = parent
    Value = SDK.Utils.Value
    return World
end

return World
