----
-- Different value utilities.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Utils.Value
-- @see SDK.Utils
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Value = {}

--- Checkers
-- @section checkers

--- Checks if a value is a boolean.
-- @tparam any value
-- @treturn boolean
function Value.IsBoolean(value)
    return type(value) == "boolean"
end

--- Checks if a value is a temperature.
-- @tparam any value
-- @treturn boolean
function Value.IsEntityTemperature(value)
    return Value.IsNumber(value)
        and value >= TUNING.MIN_ENTITY_TEMP
        and value <= TUNING.MAX_ENTITY_TEMP
end

--- Checks if a value is an integer.
-- @tparam any value
-- @treturn boolean
function Value.IsInteger(value)
    return Value.IsNumber(value) and value == math.floor(value)
end

--- Checks if a value is a number.
-- @tparam any value
-- @treturn boolean
function Value.IsNumber(value)
    return type(value) == "number"
end

--- Checks if a value is a percent.
-- @tparam any value
-- @treturn boolean
function Value.IsPercent(value)
    return Value.IsNumber(value) and value >= 0 and value <= 100
end

--- Checks if a value is a point.
-- @tparam any value
-- @treturn boolean
function Value.IsPoint(value)
    return type(value) == "table" and value.x and value.y and value.z and true or false
end

--- Checks if a value is a season.
-- @tparam any value
-- @treturn boolean
function Value.IsSeason(value)
    return value == "autumn" or value == "spring" or value == "summer" or value == "winter"
end

--- Checks if a value is a string.
-- @tparam any value
-- @treturn boolean
function Value.IsString(value)
    return type(value) == "string"
end

--- Checks if a value is a unit interval.
--
-- [https://en.wikipedia.org/wiki/Unit_interval](https://en.wikipedia.org/wiki/Unit_interval)
--
-- @tparam any value
-- @treturn boolean
function Value.IsUnitInterval(value)
    return Value.IsNumber(value) and value >= 0 and value <= 1
end

--- Converters
-- @section converters

--- Converts a number into a clock.
-- @tparam number|string seconds Seconds
-- @treturn string Hours
-- @treturn string Minutes
-- @treturn string Seconds
function Value.ToClock(seconds)
    seconds = tonumber(seconds)
    if seconds then
        local h = math.floor(seconds / 3600)
        local m = math.floor(seconds / 60 - (h * 60))
        local s = math.floor(seconds - h * 3600 - m * 60)
        return h, m, s
    end
end

--- Converts a number into a clock string.
-- @tparam number|string seconds Seconds
-- @tparam boolean has_no_hours Should hours be hidden?
-- @treturn string|nil
function Value.ToClockString(seconds, has_no_hours)
    seconds = tonumber(seconds)
    if seconds then
        local h, m, s = Value.ToClock(seconds)
        h = string.format("%02.f", h)
        m = string.format("%02.f", m)
        s = string.format("%02.f", s)
        return table.concat(has_no_hours and { m, s } or { h, m, s }, ":")
    end
end

--- Converts a number into a days string.
-- @tparam number|string value
-- @treturn string|nil
-- @todo Consider making a complete pluralization solution
function Value.ToDaysString(value)
    value = tonumber(value)
    return Value.IsNumber(value) and string.format(
        "%s day%s",
        tostring(value),
        (value >= -1 and value <= 1 and value ~= 0) and "" or "s"
    ) or nil
end

--- Converts a number into a float string.
-- @tparam number|string value
-- @treturn string|nil
function Value.ToFloatString(value)
    value = tonumber(value)
    return Value.IsNumber(value) and string.format("%0.2f", value) or nil
end

--- Converts a number into a percentage string.
-- @tparam number|string value
-- @treturn string|nil
function Value.ToPercentString(value)
    value = tonumber(value)
    return Value.IsNumber(value) and string.format("%0.2f", value) .. "%" or nil
end

--- Converts a number into a degree string.
-- @tparam number|string value
-- @treturn string|nil
function Value.ToDegreeString(value)
    value = tonumber(value)
    return Value.IsNumber(value) and string.format("%0.2f°", value) or nil
end

return Value
