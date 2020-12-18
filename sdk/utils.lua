----
-- Different mod utilities.
--
-- Includes different utilities used throughout the whole mod.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Utils
-- @see SDK.Utils.Chain
-- @see SDK.Utils.Methods
-- @see SDK.Utils.String
-- @see SDK.Utils.Table
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Utils = {}

Utils.Chain = require "sdk/utils/chain"
Utils.Methods = require "sdk/utils/methods"
Utils.String = require "sdk/utils/string"
Utils.Table = require "sdk/utils/table"

--- Asserts if a field is not missing.
-- @tparam string name
-- @tparam any field
function Utils.AssertRequiredField(name, field)
    assert(field ~= nil, string.format("Required %s is missing", name))
end

--- Checks if value is an integer.
-- @tparam number value
-- @treturn boolean
function Utils.IsInteger(value)
    return value == math.floor(value)
end

return Utils
