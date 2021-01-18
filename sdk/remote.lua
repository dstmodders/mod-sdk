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

--- Serializes values ready for remote.
--
-- _**NB!** Currently doesn't support tables._
--
-- @usage SDK.Remote.Serialize({ "foo", 0, 1, true, false, _G.ThePlayer }) -- returns:
-- -- {
-- --     '"foo"',
-- --     "0",
-- --     "1",
-- --     "true",
-- --     "false",
-- --     'LookupPlayerInstByUserID("KU_foobar")',
-- -- }
-- @tparam table t Table with values to serialize
-- @treturn table Table with serialized values
function Remote.Serialize(t)
    local serialized = {}
    for _, v in pairs(t) do
        if type(v) == "boolean" then
            table.insert(serialized, tostring(v))
        elseif type(v) == "number" then
            if not Value.IsInteger(v) then
                table.insert(serialized, Value.ToFloatString(v))
            else
                table.insert(serialized, tostring(v))
            end
        elseif type(v) == "string" then
            table.insert(serialized, string.format("%q", v))
        elseif type(v) == "table" then
            if v.userid then
                table.insert(serialized, 'LookupPlayerInstByUserID("' .. v.userid .. '")')
            else
                return
            end
        end
    end
    return serialized
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
