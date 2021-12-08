----
-- Handles remote world functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Remote.World
-- @see SDK.Remote
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
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

local function ArgPlayer(...)
    return SDK._ArgPlayer(World, ...)
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

local function ArgUnsigned(...)
    return SDK._ArgUnsigned(World, ...)
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

    if options ~= nil then
        Remote.Send("TheWorld:PushEvent(%s, %s)", { event, options }, true)
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

--- Season
-- @section season

--- Sends a request to advance a season.
-- @see SDK.World.Season.AdvanceSeason
-- @tparam[opt] number days
-- @treturn boolean
function World.AdvanceSeason(days)
    days = ArgUnsignedInteger("AdvanceSeason", days or 1, "days")

    if not days then
        return false
    end

    DebugString("Advance season:", Value.ToDaysString(days))
    for _ = 1, days do
        World.PushEvent("ms_advanceseason")
    end
    return true
end

--- Sends a request to retreat a season.
-- @see SDK.World.Season.RetreatSeason
-- @tparam[opt] number days
-- @treturn boolean
function World.RetreatSeason(days)
    days = ArgUnsignedInteger("RetreatSeason", days or 1, "days")

    if not days then
        return false
    end

    DebugString("Retreat season:", Value.ToDaysString(days))
    for _ = 1, days do
        World.PushEvent("ms_retreatseason")
    end
    return true
end

--- Sends a request to set a season.
-- @see SDK.World.Season.SetSeason
-- @tparam string season
-- @treturn boolean
function World.SetSeason(season)
    season = ArgSeason("SetSeason", season)

    if not season then
        return false
    end

    DebugString("Season:", tostring(season))
    World.PushEvent("ms_setseason", season)
    return true
end

--- Sends a request to set a season length.
-- @see SDK.World.Season.SetSeasonLength
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
    World.PushEvent("ms_setseasonlength", { season = season, length = length })
    return true
end

--- Weather
-- @section weather

--- Sends a request to send a lightning strike.
-- @see SDK.World.Weather.SendLightningStrike
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

    DebugString("Send lighting strike:", tostring(pt))
    World.PushEvent("ms_sendlightningstrike", pt)
    return true
end

--- Sends a request to send a mini earthquake.
-- @see SDK.World.Weather.SendMiniEarthquake
-- @tparam[opt] number radius Default: 20
-- @tparam[opt] number amount Default: 20
-- @tparam[opt] number duration Default: 2.5
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function World.SendMiniEarthquake(radius, amount, duration, player)
    local fn_name = "SendMiniEarthquake"
    radius = ArgUnsignedInteger(fn_name, radius or 20, "radius")
    amount = ArgUnsignedInteger(fn_name, amount or 20, "amount")
    duration = ArgUnsigned(fn_name, duration or 2.5, "duration")
    player = ArgPlayer(fn_name, player)

    if not radius or not amount or not duration or not player then
        return false
    end

    if not TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a cave")
        return false
    end

    DebugString("Send mini earthquake:", player:GetDisplayName())
    World.PushEvent("ms_miniquake", {
        target = player,
        num = amount,
        rad = radius,
        duration = duration,
    })

    return true
end

--- Sends a request to set a delta moisture.
-- @see SDK.World.Weather.SetDeltaMoisture
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaMoisture(delta)
    delta = ArgNumber("SetDeltaMoisture", delta or 0, "delta")

    if not delta then
        return false
    end

    DebugString("Delta moisture:", Value.ToFloatString(delta))
    World.PushEvent("ms_deltamoisture", delta)
    return true
end

--- Sends a request to set a delta wetness.
-- @see SDK.World.Weather.SetDeltaWetness
-- @tparam[opt] number delta
-- @treturn boolean
function World.SetDeltaWetness(delta)
    delta = ArgNumber("SetDeltaWetness", delta or 0, "delta")

    if not delta then
        return false
    end

    DebugString("Delta wetness:", Value.ToFloatString(delta))
    World.PushEvent("ms_deltawetness", delta)
    return true
end

--- Sends a request to set precipitation.
-- @see SDK.World.Weather.SetPrecipitation
-- @tparam[opt] boolean bool
-- @treturn boolean
function World.SetPrecipitation(bool)
    bool = bool ~= false and true or false
    DebugString("Precipitation:", tostring(bool))
    World.PushEvent("ms_forceprecipitation", bool)
    return true
end

--- Sends a request to set a snow level.
-- @see SDK.World.Weather.SetSnowLevel
-- @tparam number level
-- @treturn boolean
function World.SetSnowLevel(level)
    local fn_name = "SetSnowLevel"
    level = ArgUnitInterval(fn_name, level or 0, "level")

    if not level then
        return false
    end

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    DebugString("Snow level:", Value.ToFloatString(level))
    World.PushEvent("ms_setsnowlevel", level)
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
