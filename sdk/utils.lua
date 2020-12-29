----
-- Different utilities.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Utils
-- @see SDK
-- @see SDK.Utils.Chain
-- @see SDK.Utils.Method
-- @see SDK.Utils.String
-- @see SDK.Utils.Table
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Utils = {}

local SDK

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

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Utils
function Utils._DoInit(sdk)
    SDK = sdk

    SDK._SetModuleName(SDK, Utils, "Utils")
    SDK.LoadSubmodule(Utils, "Chain", "sdk/utils/chain")
    SDK.LoadSubmodule(Utils, "Method", "sdk/utils/method")
    SDK.LoadSubmodule(Utils, "String", "sdk/utils/string")
    SDK.LoadSubmodule(Utils, "Table", "sdk/utils/table")

    return SDK._DoInitModule(SDK, Utils, "Utils")
end

return Utils
