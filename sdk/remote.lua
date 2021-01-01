----
-- Different remote functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Remote = {}

local SDK

--- General
-- @section general

--- Sends a remote command to execute.
-- @tparam string cmd Command to execute
-- @tparam[opt] table data Data to unpack and used alongside with string
-- @treturn table
function Remote.Send(cmd, data)
    local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(string.format(cmd, unpack(data or {})), x, z)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Remote
function Remote._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Remote, "Remote")
end

return Remote
