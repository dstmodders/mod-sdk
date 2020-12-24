----
-- Different RPC functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.RPC
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Debug = require "sdk/debug"

local RPC = {}

local _SendRPCToServer

--- General
-- @section general

--- Checks if `SendRPCToServer()` is enabled.
-- @treturn boolean
function RPC.IsSendToServerEnabled()
    return _SendRPCToServer == nil
end

--- Disables `SendRPCToServer()`.
--
-- Only affects the `SendRPCToServer()` wrapper function Utils.and leaves the `TheNet:SendRPCToServer()`
-- as is.
function RPC.DisableSendToServer()
    if not _SendRPCToServer then
        _SendRPCToServer = SendRPCToServer
        SendRPCToServer = function() end
        Debug.String("SendRPCToServer: disabled")
    else
        Debug.String("SendRPCToServer: already disabled")
    end
end

--- Enables `SendRPCToServer()`.
function RPC.EnableSendToServer()
    if _SendRPCToServer then
        SendRPCToServer = _SendRPCToServer
        _SendRPCToServer = nil
        Debug.String("SendRPCToServer: enabled")
    else
        Debug.String("SendRPCToServer: already enabled")
    end
end

return RPC
