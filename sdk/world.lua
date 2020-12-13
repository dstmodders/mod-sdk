----
-- World.
--
-- Includes world functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.World
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Chain = require "sdk/utils/chain"
local DebugUpvalue = require "sdk/debugupvalue"
local Table = require "sdk/utils/table"

local World = {}

local SDK

local _MOISTURE_FLOOR
local _MOISTURE_RATE
local _PEAK_PRECIPITATION_RATE
local _WETNESS_RATE

--- General
-- @section general

--- Gets meta.
-- @tparam[opt] string name Meta name
-- @treturn[1] table Meta table, when no name passed
-- @treturn[2] string Meta value, when the name is passed
function World.GetMeta(name)
    local meta = TheWorld.meta
    return meta and name ~= nil and meta[name] or meta
end

--- Gets seed.
-- @treturn string
function World.GetSeed()
    return World.GetMeta("seed")
end

--- Gets state.
-- @tparam[opt] string name State name
-- @treturn[1] table State table, when no name passed
-- @treturn[2] string State value, when the name is passed
function World.GetState(name)
    local state = TheWorld.state
    if state and name ~= nil and type(state[name]) ~= nil then
        return state[name]
    end
    return state
end

--- Checks if it's a cave world.
-- @treturn boolean
function World.IsCave()
    return TheWorld:HasTag("cave")
end

--- Checks if a master simulated world.
-- @treturn boolean
function World.IsMasterSim()
    return TheWorld.ismastersim
end

--- Phase
-- @section phase

--- Gets day phase.
-- @tparam string phase Phase
-- @treturn number
function World.GetPhase()
    return World.IsCave() and World.GetState("cavephase") or World.GetState("phase")
end

--- Gets next day phase.
--
-- Returns the value based on the following logic:
--
--   - day => dusk
--   - dusk => night
--   - night => day
--
-- @tparam string phase Current phase
-- @treturn string Next phase
function World.GetPhaseNext(phase)
    return Table.NextValue({ "day", "dusk", "night" }, phase)
end

--- Gets the time until the phase.
--
-- This is a convenience method returning:
--
--    TheWorld.net.components.clock:GetTimeUntilPhase(phase)
--
-- @tparam string phase
-- @treturn number
function World.GetTimeUntilPhase(phase)
    local clock = Chain.Get(TheWorld, "net", "components", "clock")
    return clock and clock:GetTimeUntilPhase(phase)
end

--- Weather
-- @section weather

--- Gets moisture floor.
-- @treturn number
function World.GetMoistureFloor()
    return _MOISTURE_FLOOR
end

--- Gets moisture rate.
-- @treturn number
function World.GetMoistureRate()
    return _MOISTURE_RATE
end

--- Gets peak precipitation rate.
-- @treturn number
function World.GetPeakPrecipitationRate()
    return _PEAK_PRECIPITATION_RATE
end

--- Gets weather component.
--
-- Returns the component based on the world type: cave or forest.
--
-- @treturn[1] Weather
-- @treturn[2] CaveWeather
function World.GetWeatherComponent()
    local components = Chain.Get(TheWorld, "net", "components")
    if components then
        return World.IsCave() and components.caveweather or components.weather
    end
    return nil
end

--- Gets wetness rate.
-- @treturn number
function World.GetWetnessRate()
    return _WETNESS_RATE
end

--- Checks if there is precipitation.
-- @treturn boolean
function World.IsPrecipitation()
    return World.GetState("precipitation") ~= "none"
        or World.GetState("moisture") >= World.GetState("moistureceil")
end

--- Overrides `Weather:OnUpdate()`.
-- @tparam Weather|CaveWeather self
function World.WeatherOnUpdate(self)
    local _moisturefloor = DebugUpvalue.GetUpvalue(self.GetDebugString, "_moisturefloor")
    local _moisturerate = DebugUpvalue.GetUpvalue(self.GetDebugString, "_moisturerate")
    local _temperature = DebugUpvalue.GetUpvalue(self.GetDebugString, "_temperature")

    local _peakprecipitationrate = DebugUpvalue.GetUpvalue(
        self.GetDebugString,
        "_peakprecipitationrate"
    )

    local CalculatePrecipitationRate = DebugUpvalue.GetUpvalue(
        self.GetDebugString,
        "CalculatePrecipitationRate"
    )

    local CalculateWetnessRate = DebugUpvalue.GetUpvalue(
        self.GetDebugString,
        "CalculateWetnessRate"
    )

    local precipitation_rate
    if CalculatePrecipitationRate and type(CalculatePrecipitationRate) == "function" then
        precipitation_rate = CalculatePrecipitationRate()
    end

    local wetness_rate
    if CalculatePrecipitationRate and type(CalculatePrecipitationRate) == "function"
        and _temperature and type(_temperature) == "number"
    then
        wetness_rate = CalculateWetnessRate(_temperature, precipitation_rate)
    end

    _WETNESS_RATE = wetness_rate
    _MOISTURE_FLOOR = type(_moisturefloor) == "userdata" and _moisturefloor:value()
    _MOISTURE_RATE = type(_moisturerate) == "userdata" and _moisturerate:value()
    _PEAK_PRECIPITATION_RATE = type(_peakprecipitationrate) == "userdata"
        and _peakprecipitationrate:value()
end

--- Lifecycle
-- @section lifecycle

--- Initializes world.
-- @tparam SDK sdk
-- @treturn SDK.World
function World._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(World, "World", "TheWorld")
end

return World
