----
-- Handles utilities.
--
-- On its own doesn't do much and only acts as an entry point to all other utilities.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Utils
-- @see SDK
-- @see SDK.Utils.Chain
-- @see SDK.Utils.Table
-- @see SDK.Utils.Value
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

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam table submodules
-- @treturn SDK.Utils
function Utils._DoInit(sdk, submodules)
    SDK = sdk

    submodules = submodules ~= nil and submodules or {
        Chain = "sdk/utils/chain",
        Table = "sdk/utils/table",
        Value = "sdk/utils/value",
    }

    SDK._SetModuleName(SDK, Utils, "Utils")
    SDK.LoadSubmodules(Utils, submodules)

    return SDK._DoInitModule(SDK, Utils, "Utils")
end

return Utils
