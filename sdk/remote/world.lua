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

local function ArgNumber(...)
    return SDK._ArgNumber(World, ...)
end

local function ArgPoint(...)
    return SDK._ArgPoint(World, ...)
end

local function ArgSeason(...)
    return SDK._ArgSeason(World, ...)
end

local function ArgString(...)
    return SDK._ArgString(World, ...)
end

local function ArgUnitInterval(...)
    return SDK._ArgUnitInterval(World, ...)
end

local function ArgUnsignedInteger(...)
    return SDK._ArgUnsignedInteger(World, ...)
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
    event = ArgString("PushEvent", event, "event")

    if not event then
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
    days = ArgUnsignedInteger("Rollback", days or 0, "days")

    if not days then
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
    pt = ArgPoint(fn_name, pt)

    if not pt then
        return false
    end

    if not TheWorld:HasTag("forest") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
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
    delta = ArgNumber("SetDeltaMoisture", delta or 0, "delta")

    if not delta then
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
    delta = ArgNumber("SetDeltaWetness", delta or 0, "delta")

    if not delta then
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
    season = ArgSeason("SetSeason", season)

    if not season then
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
    season = ArgSeason(fn_name, season)
    length = ArgUnsignedInteger(fn_name, length, "length")

    if not season or not length then
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
    local fn_name = "SetSnowLevel"
    delta = ArgUnitInterval(fn_name, delta or 0, "delta")

    if not delta then
        return false
    end

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    DebugString("Snow level:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_setsnowlevel", %0.2f)', { delta })
    return true
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
