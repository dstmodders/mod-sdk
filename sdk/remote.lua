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
local Value

--- Helpers
-- @section helpers

local function DebugErrorInvalidArg(arg_name, explanation)
    SDK.Debug.Error(
        string.format("SDK.Remote.%s():", debug.getinfo(2).name),
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

--- General
-- @section general

--- Sends a request to gather players.
-- @treturn boolean
function Remote.GatherPlayers()
    SDK.Debug.String("[remote]", "Gather players")
    Remote.Send("c_gatherplayers()")
    return true
end

--- Sends a world rollback request to server.
-- @tparam number days
-- @treturn boolean
function Remote.Rollback(days)
    days = days ~= nil and days or 0
    if Value.IsUnsigned(days) and Value.IsInteger(days) then
        SDK.Debug.String("[remote]", "Rollback:", Value.ToDaysString(days))
        Remote.Send("TheNet:SendWorldRollbackRequestToServer(%d)", { days })
        return true
    end
    DebugErrorInvalidArg("days", "must be an unsigned integer")
    return false
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

--- Sends a request to force precipitation.
-- @tparam[opt] boolean bool
-- @treturn boolean
function Remote.ForcePrecipitation(bool)
    bool = bool ~= false and true or false
    SDK.Debug.String("[remote]", "Force precipitation:", tostring(bool))
    Remote.Send('TheWorld:PushEvent("ms_forceprecipitation", %s)', { tostring(bool) })
    return true
end

--- Sends a request to set a season.
-- @tparam string season
-- @treturn boolean
function Remote.Season(season)
    if Value.IsSeason(season) then
        SDK.Debug.String("[remote]", "Season:", tostring(season))
        Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { season })
        return true
    end
    DebugErrorInvalidArg("season", "must be a season: autumn, winter, spring or summer")
    return false
end

--- Sends a request to set a season length.
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function Remote.SeasonLength(season, length)
    if Value.IsSeason(season) then
        if Value.IsUnsigned(length) and Value.IsInteger(length) then
            SDK.Debug.String(
                "[remote]",
                "Season length:",
                season,
                "(" .. Value.ToDaysString(length) .. ")"
            )
            Remote.Send(
                'TheWorld:PushEvent("ms_setseasonlength", { season = "%s", length = %d })',
                { season, length }
            )
            return true
        else
            DebugErrorInvalidArg("length", "must be an unsigned integer")
        end
    else
        DebugErrorInvalidArg("season", "must be a season: autumn, winter, spring or summer")
    end
    return false
end

--- Sends a request to set a world delta moisture.
-- @tparam[opt] number delta
-- @treturn boolean
function Remote.WorldDeltaMoisture(delta)
    delta = delta ~= nil and delta or 0
    if Value.IsNumber(delta) then
        SDK.Debug.String("[remote]", "World delta moisture:", tostring(delta))
        Remote.Send('TheWorld:PushEvent("ms_deltamoisture", %d)', { delta })
        return true
    end
    DebugErrorInvalidArg("delta", "must be a number")
    return false
end

--- Sends a request to set a world delta wetness.
-- @tparam[opt] number delta
-- @treturn boolean
function Remote.WorldDeltaWetness(delta)
    delta = delta ~= nil and delta or 0
    if Value.IsNumber(delta) then
        SDK.Debug.String("[remote]", "World delta wetness:", tostring(delta))
        Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
        return true
    end
    DebugErrorInvalidArg("delta", "must be a number")
    return false
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Remote
function Remote._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return SDK._DoInitModule(SDK, Remote, "Remote")
end

return Remote
