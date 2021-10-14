----
-- Handles debug upvalue functionality.
--
-- _**NB!** Should be used with caution and only as a last resort._
--
-- Allows accessing some in-game local variables using `debug` module.
--
--    local fn = TheWorld.net.components.weather.GetDebugString
--    local _moisturefloor = SDK.DebugUpvalue.GetUpvalue(fn, "_moisturefloor")
--    print(_moisturefloor:value()) -- prints a moisture floor value
--
-- Inspired by [UpvalueHacker](https://github.com/rezecib/Rezecib-s-Rebalance/blob/master/scripts/tools/upvaluehacker.lua)
-- created by Rafael Lizarralde ([@rezecib](https://github.com/rezecib)).
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.DebugUpvalue
-- @see SDK
--
-- @author Rafael Lizarralde ([@rezecib](https://github.com/rezecib))
-- @copyright 2020
-- @license MIT
-- @release 0.1
local DebugUpvalue = {}

local SDK

--- Helpers
-- @section helpers

local function GetUpvalue(fn, name)
    local i = 1
    while debug.getupvalue(fn, i) and debug.getupvalue(fn, i) ~= name do
        i = i + 1
    end
    local _, value = debug.getupvalue(fn, i)
    return value, i
end

--- General
-- @section general

--- Gets a function upvalue.
-- @tparam function fn
-- @tparam string ... Strings
function DebugUpvalue.GetUpvalue(fn, ...)
    local previous, i
    for _, var in ipairs({ ... }) do
        previous = fn
        fn, i = GetUpvalue(fn, var)
    end
    return fn, i, previous
end

--- Sets a function upvalue.
-- @tparam function start_fn
-- @tparam function new_fn
-- @tparam string ... Strings
function DebugUpvalue.SetUpvalue(start_fn, new_fn, ...)
    local _, fni, scope_fn = DebugUpvalue.GetUpvalue(start_fn, ...)
    debug.setupvalue(scope_fn, fni, new_fn)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.DebugUpvalue
function DebugUpvalue._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, DebugUpvalue, "DebugUpvalue")
end

return DebugUpvalue
