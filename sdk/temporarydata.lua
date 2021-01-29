----
-- Handles temporary data functionality.
--
-- A very simple tool for temporary storing any kind of data.
--
--     SDK.TemporaryData.Set("foo", "bar")
--     SDK.TemporaryData.Get("foo") -- returns: "bar"
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.TemporaryData
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local TemporaryData = {
    data = {},
}

local SDK

--- Helpers
-- @section helpers

local function DebugError(...)
    SDK._DebugError("[temporary_data]", ...)
end

local function DebugString(...)
    SDK._DebugString("[temporary_data]", ...)
end

--- General
-- @section general

--- Gets a data field.
-- @tparam string name
-- @treturn any
function TemporaryData.Get(name)
    if TemporaryData.data[name] then
        return TemporaryData.data[name]
    end
    DebugError("[get]", name)
end

--- Checks if a data field exists.
-- @tparam string name
-- @treturn boolean
function TemporaryData.Has(name)
    return TemporaryData.data[name] and true or false
end

--- Sets a data field.
-- @tparam string name
-- @tparam any value
-- @treturn SDK.TemporaryData
function TemporaryData.Set(name, value)
    DebugString("[set]", name .. ":", value)
    TemporaryData.data[name] = value
    return TemporaryData
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.TemporaryData
function TemporaryData._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, TemporaryData, "TemporaryData")
end

return TemporaryData
