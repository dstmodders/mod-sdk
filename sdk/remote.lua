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

--- Sends a request to gather players.
function Remote.GatherPlayers()
    SDK.Debug.String("[remote]", "Gather players")
    Remote.Send("c_gatherplayers()")
end

--- Sends a world rollback request to server.
-- @tparam number days
function Remote.Rollback(days)
    days = days ~= nil and days or 0
    SDK.Debug.String("[remote]", "Rollback:", string.format(
        "%d day%s",
        days,
        days == 1 and "" or "s"
    ))
    Remote.Send("TheNet:SendWorldRollbackRequestToServer(%d)", { days })
end

--- Sends a remote command to execute.
-- @tparam string cmd Command to execute
-- @tparam[opt] table data Data to unpack and used alongside with string
-- @treturn table
function Remote.Send(cmd, data)
    local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(string.format(cmd, unpack(data or {})), x, z)
end

--- World
-- @section world

--- Sends a request to set world delta moisture.
-- @tparam number delta
function Remote.WorldDeltaMoisture(delta)
    delta = delta ~= nil and delta or 0
    SDK.Debug.String("[remote]", "World delta moisture:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltamoisture", %d)', { delta })
end

--- Sends a request to set world delta wetness.
-- @tparam number delta
function Remote.WorldDeltaWetness(delta)
    delta = delta ~= nil and delta or 0
    SDK.Debug.String("[remote]", "World delta wetness:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
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
