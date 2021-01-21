----
-- Handles world weather.
--
-- _**NB!** Requires_ `SDK.Remote.World` _to be loaded to work on dedicated servers with
-- administrator rights._
--
-- Supports both master and non-master instances. On non-master instances (dedicated
-- servers) it calls the corresponding `SDK.Remote.World` function.
--
--     if SDK.World.Weather.HasPrecipitation() then
--         SDK.World.Weather.SetPrecipitation(false)
--     end
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.World.Weather
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Weather = {}

local SDK
local Value
local World

local _MOISTURE_FLOOR
local _MOISTURE_RATE
local _PEAK_PRECIPITATION_RATE
local _WETNESS_RATE

--- Helpers
-- @section helpers

local function ArgNumber(...)
    return SDK._ArgNumber(Weather, ...)
end

local function ArgPlayer(...)
    return SDK._ArgPlayer(Weather, ...)
end

local function ArgPoint(...)
    return SDK._ArgPoint(Weather, ...)
end

local function ArgUnitInterval(...)
    return SDK._ArgUnitInterval(Weather, ...)
end

local function ArgUnsigned(...)
    return SDK._ArgUnsigned(Weather, ...)
end

local function ArgUnsignedInteger(...)
    return SDK._ArgUnsignedInteger(Weather, ...)
end

local function DebugErrorInvalidWorldType(...)
    SDK._DebugErrorInvalidWorldType(Weather, ...)
end

local function DebugString(...)
    SDK._DebugString("[world]", "[weather]", ...)
end

--- General
-- @section general

--- Gets `weather` component.
--
-- Returns the component based on the world type: cave or forest.
--
-- @treturn[1] Weather
-- @treturn[2] CaveWeather
function Weather.GetWeatherComponent()
    local components = SDK.Utils.Chain.Get(TheWorld, "net", "components")
    if components then
        return TheWorld:HasTag("cave") and components.caveweather or components.weather
    end
end

--- Sends a lightning strike.
-- @tparam Vector3 pt Point
-- @treturn boolean
function Weather.SendLightningStrike(pt)
    local fn_name = "SendLightningStrike"
    pt = ArgPoint(fn_name, pt)

    if not pt then
        return false
    end

    if not TheWorld:HasTag("forest") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Send lighting strike:", tostring(pt))
        TheWorld:PushEvent("ms_sendlightningstrike", pt)
        return true
    end

    return SDK.Remote.World.SendLightningStrike(pt)
end

--- Sends a mini earthquake.
-- @tparam[opt] number radius Default: 20
-- @tparam[opt] number amount Default: 20
-- @tparam[opt] number duration Default: 2.5
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Weather.SendMiniEarthquake(radius, amount, duration, player)
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

    if TheWorld.ismastersim then
        DebugString("Send mini earthquake:", player:GetDisplayName())
        TheWorld:PushEvent("ms_miniquake", {
            target = player,
            num = amount,
            rad = radius,
            duration = duration,
        })
        return true
    end

    return SDK.Remote.World.SendMiniEarthquake(radius, amount, duration, player)
end

--- Get
-- @section get

--- Gets a moisture value.
-- @treturn number
function Weather.GetMoisture()
    return World.GetState("moisture")
end

--- Gets a moisture ceil value.
-- @treturn number
function Weather.GetMoistureCeil()
    return World.GetState("moistureceil")
end

--- Gets a moisture floor value.
-- @treturn number
function Weather.GetMoistureFloor()
    return _MOISTURE_FLOOR
end

--- Gets a moisture rate value.
-- @treturn number
function Weather.GetMoistureRate()
    return _MOISTURE_RATE
end

--- Gets a peak precipitation rate.
-- @treturn number
function Weather.GetPeakPrecipitationRate()
    return _PEAK_PRECIPITATION_RATE
end

--- Gets a snow level value.
-- @treturn number
function Weather.GetSnowLevel()
    return World.GetState("snowlevel")
end

--- Gets a wetness value.
-- @treturn number
function Weather.GetWetness()
    return World.GetState("wetness")
end

--- Gets a wetness rate value.
-- @treturn number
function Weather.GetWetnessRate()
    return _WETNESS_RATE
end

--- Checks precipitation state.
-- @treturn boolean
function Weather.HasPrecipitation()
    return World.GetState("precipitation") ~= "none"
        or World.GetState("moisture") >= World.GetState("moistureceil")
end

--- Set
-- @section set

--- Sets a delta moisture.
-- @tparam[opt] number delta
-- @treturn boolean
function Weather.SetDeltaMoisture(delta)
    delta = ArgNumber("SetDeltaMoisture", delta or 0, "delta")

    if not delta then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Delta moisture:", Value.ToFloatString(delta))
        TheWorld:PushEvent("ms_deltamoisture", delta)
        return true
    end

    return SDK.Remote.World.SetDeltaMoisture(delta)
end

--- Sets a delta wetness.
-- @tparam[opt] number delta
-- @treturn boolean
function Weather.SetDeltaWetness(delta)
    delta = ArgNumber("SetDeltaWetness", delta or 0, "delta")

    if not delta then
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Delta wetness:", Value.ToFloatString(delta))
        TheWorld:PushEvent("ms_deltawetness", delta)
        return true
    end

    return SDK.Remote.World.SetDeltaWetness(delta)
end

--- Sets a precipitation state.
-- @tparam[opt] boolean bool
-- @treturn boolean
function Weather.SetPrecipitation(bool)
    bool = bool ~= false and true or false

    if TheWorld.ismastersim then
        DebugString("Precipitation:", tostring(bool))
        TheWorld:PushEvent("ms_forceprecipitation", bool)
        return true
    end

    return SDK.Remote.World.SetPrecipitation(bool)
end

--- Sets a snow level.
-- @tparam number level
-- @treturn boolean
function Weather.SetSnowLevel(level)
    local fn_name = "SetSnowLevel"
    level = ArgUnitInterval(fn_name, level or 0, "level")

    if not level then
        return false
    end

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a forest")
        return false
    end

    if TheWorld.ismastersim then
        DebugString("Snow level:", Value.ToFloatString(level))
        TheWorld:PushEvent("ms_setsnowlevel", level)
        return true
    end

    return SDK.Remote.World.SetSnowLevel(level)
end

--- Override
-- @section override

--- Overrides `Weather:OnUpdate()`.
-- @tparam Weather|CaveWeather self
function Weather.OverrideOnUpdate(self)
    local GetUpvalue = SDK.DebugUpvalue.GetUpvalue

    local _moisturefloor = GetUpvalue(self.GetDebugString, "_moisturefloor")
    local _moisturerate = GetUpvalue(self.GetDebugString, "_moisturerate")
    local _temperature = GetUpvalue(self.GetDebugString, "_temperature")
    local _peakprecipitationrate = GetUpvalue(self.GetDebugString, "_peakprecipitationrate")

    local fn, precipitation_rate, wetness_rate

    fn = GetUpvalue(self.GetDebugString, "CalculatePrecipitationRate")
    if type(fn) == "function" then
        precipitation_rate = fn()
    end

    fn = GetUpvalue(self.GetDebugString, "CalculateWetnessRate")
    if type(fn) == "function" and type(_temperature) == "number" then
        wetness_rate = fn(_temperature, precipitation_rate)
    end

    _WETNESS_RATE = wetness_rate
    _MOISTURE_FLOOR = type(_moisturefloor) == "userdata" and _moisturefloor:value()
    _MOISTURE_RATE = type(_moisturerate) == "userdata" and _moisturerate:value()
    _PEAK_PRECIPITATION_RATE = type(_peakprecipitationrate) == "userdata"
        and _peakprecipitationrate:value()
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam SDK.World parent
-- @treturn SDK.World.Weather
function Weather._DoInit(sdk, parent)
    SDK = sdk
    Value = SDK.Utils.Value
    World = parent
    return Weather
end

return Weather
