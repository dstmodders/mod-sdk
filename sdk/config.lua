----
-- Different config functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Config
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Config = {}

local SDK

--- General
-- @section general

--- Gets a mod config data.
-- @tparam string config
-- @treturn any
function Config.GetModConfigData(config)
    return GetModConfigData(config, SDK.modname)
end

--- Gets a mod key config data.
-- @tparam string config
-- @treturn any
function Config.GetModKeyConfigData(config)
    local key = GetModConfigData(config, SDK.modname)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Config
function Config._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Config, "Config")
end

return Config
