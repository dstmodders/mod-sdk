----
-- Different remote functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote
-- @see SDK
-- @see SDK.Remote.Player
-- @see SDK.Remote.World
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
-- @tparam table submodules
-- @treturn SDK.Remote
function Remote._DoInit(sdk, submodules)
    SDK = sdk

    submodules = submodules ~= nil and submodules or {
        Player = "sdk/remote/player",
        World = "sdk/remote/world",
    }

    SDK._SetModuleName(SDK, Remote, "Remote")
    SDK.LoadSubmodules(Remote, submodules)

    return SDK._DoInitModule(SDK, Remote, "Remote", "ThePlayer")
end

return Remote
