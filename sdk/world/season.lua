----
-- Handles world season.
--
-- _**NB!** Requires_ `SDK.Remote.World` _to be loaded to work on dedicated servers with
-- administrator rights._
--
-- Supports both master and non-master instances. On non-master instances (dedicated servers) it
-- calls the corresponding `SDK.Remote.World` function.
--
--     if SDK.World.Season.GetSeason() == "autumn" then
--         SDK.World.Season.SetSeason("winter")
--     end
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.World.Season
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Season = {}

local SDK
local Value
local World

--- Helpers
-- @section helpers

local function ArgSeason(...)
    return SDK._ArgSeason(Season, ...)
end

local function ArgUnsignedInteger(...)
    return SDK._ArgUnsignedInteger(Season, ...)
end

local function DebugString(...)
    SDK._DebugString("[world]", "[season]", ...)
end

--- General
-- @section general

--- Advances a season.
-- @see SDK.Remote.World.AdvanceSeason
-- @tparam[opt] number days
-- @treturn boolean
function Season.AdvanceSeason(days)
    days = ArgUnsignedInteger("AdvanceSeason", days or 1, "days")

    if not days then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Advance season:", Value.ToDaysString(days))
        for _ = 1, days do
            TheWorld:PushEvent("ms_advanceseason")
        end
        return true
    end

    return SDK.Remote.World.AdvanceSeason(days)
end

--- Retreats a season.
-- @see SDK.Remote.World.RetreatSeason
-- @tparam[opt] number days
-- @treturn boolean
function Season.RetreatSeason(days)
    days = ArgUnsignedInteger("RetreatSeason", days or 1, "days")

    if not days then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Retreat season:", Value.ToDaysString(days))
        for _ = 1, days do
            TheWorld:PushEvent("ms_retreatseason")
        end
        return true
    end

    return SDK.Remote.World.RetreatSeason(days)
end

--- Get
-- @section get

--- Gets a season.
-- @treturn number
function Season.GetSeason()
    return World.GetState("season")
end

--- Gets a season length.
-- @tparam string season
-- @treturn number
function Season.GetSeasonLength(season)
    season = ArgSeason("GetSeasonLength", season)
    if season then
        return World.GetState(season .. "length")
    end
end

--- Set
-- @section set

--- Sets a season.
-- @see SDK.Remote.World.SetSeason
-- @tparam string season
-- @treturn boolean
function Season.SetSeason(season)
    season = ArgSeason("SetSeason", season)

    if not season then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Season:", tostring(season))
        TheWorld:PushEvent("ms_setseason", season)
        return true
    end

    return SDK.Remote.World.SetSeason(season)
end

--- Sets a season length.
-- @see SDK.Remote.World.SetSeasonLength
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function Season.SetSeasonLength(season, length)
    local fn_name = "SetSeasonLength"
    season = ArgSeason(fn_name, season)
    length = ArgUnsignedInteger(fn_name, length, "length")

    if not season or not length then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Season length:", season, "(" .. Value.ToDaysString(length) .. ")")
        TheWorld:PushEvent("ms_setseasonlength", { season = season, length = length })
        return true
    end

    return SDK.Remote.World.SetSeasonLength(season, length)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam SDK.World parent
-- @treturn SDK.World.Weather
function Season._DoInit(sdk, parent)
    SDK = sdk
    Value = SDK.Utils.Value
    World = parent
    return Season
end

return Season