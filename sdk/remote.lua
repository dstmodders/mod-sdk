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
local Value

--- Helpers
-- @section helpers

local function DebugError(fn_name, ...)
    if SDK.Debug then
        SDK.Debug.Error(string.format("%s.%s():", tostring(Remote), fn_name), ...)
    end
end

local function DebugErrorInvalidArg(arg_name, explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    DebugError(
        fn_name,
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

local function DebugString(...)
    if SDK.Debug then
        SDK.Debug.String("[remote]", ...)
    end
end

--- General
-- @section general

--- Sends a request to go next to a certain prefab.
-- @tparam string prefab
-- @treturn boolean
function Remote.GoNext(prefab)
    if not Value.IsPrefab(prefab) then
        DebugErrorInvalidArg("prefab", "must be a prefab", "GoNext")
        return false
    end

    DebugString("Go next:", prefab)
    Remote.Send('c_gonext("%s")', { prefab })
    return true
end

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
    Value = SDK.Utils.Value

    submodules = submodules ~= nil and submodules or {
        Player = "sdk/remote/player",
        World = "sdk/remote/world",
    }

    SDK._SetModuleName(SDK, Remote, "Remote")
    SDK.LoadSubmodules(Remote, submodules)

    return SDK._DoInitModule(SDK, Remote, "Remote", "ThePlayer")
end

return Remote
