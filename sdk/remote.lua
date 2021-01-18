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
local Table
local Value

--- Helpers
-- @section helpers

local function ArgUnsigned(...)
    return SDK._ArgUnsigned(Remote, ...)
end

local function DebugString(...)
    SDK._DebugString("[remote]", ...)
end

--- General
-- @section general

--- Sends a remote command to execute.
--
-- @usage SDK.Remote.Send(
--     'LookupPlayerInstByUserID("%s").components.temperature:SetTemperature(%d)',
--     { ThePlayer.userid, 36 }
-- )
-- -- LookupPlayerInstByUserID("KU_foobar").components.temperature:SetTemperature(36)
-- @usage SDK.Remote.Send(
--     "%s.components.temperature:SetTemperature(%s)",
--     SDK.Remote.Serialize({ ThePlayer, 36 })
-- )
-- -- LookupPlayerInstByUserID("KU_foobar").components.temperature:SetTemperature(36)
-- @usage SDK.Remote.Send(
--     "%s.components.temperature:SetTemperature(%s)",
--     { ThePlayer, 36 },
--     true
-- )
-- -- LookupPlayerInstByUserID("KU_foobar").components.temperature:SetTemperature(36)
--
-- @see Serialize
-- @tparam string cmd Command to execute
-- @tparam[opt] table data Data to unpack and used alongside with string
-- @tparam[opt] boolean is_serialized Should data be serialized first?
-- @treturn boolean
function Remote.Send(cmd, data, is_serialized)
    if is_serialized then
        local serialized = Remote.Serialize(data)
        if not serialized then
            return false
        end
        data = serialized
    end

    local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(string.format(cmd, unpack(data or {})), x, z)
    return true
end

--- Serializes values ready for remote.
--
-- Returns a table with serialized values for later use in `TheNet.SendRemoteExecute`. If one value
-- can't be serialized, it returns false.
--
-- _**NB!** Tables support is pretty basic so be careful._
--
-- @usage SDK.Remote.Serialize({ "foo", 0, 0.5, true, false })
-- -- { '"foo"', "0", "0.50", "true", "false" }
-- @usage SDK.Remote.Serialize({ { 1, "foo", true, 0.25 } })
-- -- { '{ 1, "foo", true, 0.25 }' }
-- @usage SDK.Remote.Serialize({ { foo = "foo", bar = "bar" } })
-- -- { '{ bar = "bar", foo = "foo" }' }
-- @usage SDK.Remote.Serialize({ ThePlayer })
-- -- { 'LookupPlayerInstByUserID("KU_foobar")' }
-- @usage SDK.Remote.Serialize(ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar")
-- @usage SDK.Remote.Serialize("foo")
-- -- "foo"
--
-- @see Send
-- @tparam any|table t Single or multiple values to serialize
-- @treturn string|table Serialized value(s)
function Remote.Serialize(t)
    local is_single = false
    if type(t) ~= "table" or t.userid then
        is_single = true
        t = { t }
    end

    local serialized = {}
    for _, v in pairs(t) do
        if v == "nil" then
            table.insert(serialized, "nil")
        elseif type(v) == "boolean" then
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
            elseif Value.IsArray(v) then
                local value, serialized_table, serialized_values

                serialized_table = "{"
                if #v > 0 then
                    serialized_table = serialized_table .. " "
                    for i = 1, #v, 1 do
                        value = v[i]
                        serialized_values = Remote.Serialize({ value })
                        if not serialized_values or not serialized_values[1] then
                            return
                        end

                        serialized_table = serialized_table .. serialized_values[1]
                        if i ~= #v then
                            serialized_table = serialized_table .. ", "
                        end
                    end
                    serialized_table = serialized_table .. " "
                end
                serialized_table = serialized_table .. "}"

                table.insert(serialized, serialized_table)
            elseif Value.IsPairedTable(v) then
                local total, serialized_table, serialized_values

                total = Table.Count(v)
                serialized_table = "{ "
                if total > 0 then
                    local i = 0
                    for _k, _v in pairs(v) do
                        i = i + 1
                        serialized_table = serialized_table .. _k .. " = "
                        serialized_values = Remote.Serialize({ _v })
                        if not serialized_values or not serialized_values[1] then
                            return
                        end

                        serialized_table = serialized_table .. serialized_values[1]
                        if i ~= total then
                            serialized_table = serialized_table .. ", "
                        end
                    end
                end
                serialized_table = serialized_table .. " }"

                table.insert(serialized, serialized_table)
            else
                return
            end
        end
    end

    if is_single then
        return serialized[1]
    end

    return serialized
end

--- Sends a request to set a time scale.
--
-- @usage SDK.Remote.SetTimeScale(4)
-- @usage SDK.Remote.SetTimeScale(0.5)
--
-- @see SDK.Pause
-- @see SDK.Resume
-- @see SDK.SetTimeScale
-- @tparam string timescale
-- @treturn boolean
function Remote.SetTimeScale(timescale)
    timescale = ArgUnsigned("SetTimeScale", timescale, "timescale")

    if not timescale then
        return false
    end

    DebugString("Time scale:", Value.ToFloatString(timescale))
    Remote.Send('TheSim:SetTimeScale(%s)', { timescale }, true)
    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam table submodules
-- @treturn SDK.Remote
function Remote._DoInit(sdk, submodules)
    SDK = sdk
    Table = SDK.Utils.Table
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
