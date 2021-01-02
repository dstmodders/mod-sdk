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

local function DebugErrorInvalidArg(arg_name, explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    SDK.Debug.Error(
        string.format("%s.%s():", tostring(Remote), fn_name),
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

local function DebugErrorInvalidWorldType(explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    SDK.Debug.Error(
        string.format("%s.%s():", tostring(Remote), fn_name),
        "Invalid world type",
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

--- Sends a request to go next to a certain prefab.
-- @tparam EntityScript entity
-- @treturn boolean
function Remote.GoNext(entity)
    if not Value.IsEntity(entity) then
        DebugErrorInvalidArg("entity", "must be an entity", "GoNext")
        return false
    end

    SDK.Debug.String("[remote]", "Go next:", entity:GetDisplayName())
    Remote.Send('c_gonext("%s")', { entity.prefab })
    return true
end

--- Sends a world rollback request to server.
-- @tparam number days
-- @treturn boolean
function Remote.Rollback(days)
    days = days ~= nil and days or 0

    if not Value.IsUnsigned(days) or not Value.IsInteger(days) then
        DebugErrorInvalidArg("days", "must be an unsigned integer", "Rollback")
        return false
    end

    SDK.Debug.String("[remote]", "Rollback:", Value.ToDaysString(days))
    Remote.Send("TheNet:SendWorldRollbackRequestToServer(%d)", { days })
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

--- Sends a request to send a lightning strike.
-- @tparam Vector3 pt Point
-- @treturn boolean
function Remote.SendLightningStrike(pt)
    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType("must be in a forest", "SendLightningStrike")
        return false
    end

    if not Value.IsPoint(pt) then
        DebugErrorInvalidArg("pt", "must be a point", "SendLightningStrike")
        return false
    end

    local pt_string = string.format("Vector3(%0.2f, %0.2f, %0.2f)", pt.x, pt.y, pt.z)
    SDK.Debug.String("[remote]", "Send lighting strike:", tostring(pt))
    Remote.Send('TheWorld:PushEvent("ms_sendlightningstrike", %s)', { pt_string })
    return true
end

--- Sends a request to set a season.
-- @tparam string season
-- @treturn boolean
function Remote.SetSeason(season)
    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            "season",
            "must be a season: autumn, winter, spring or summer",
            "SetSeason"
        )
        return false
    end

    SDK.Debug.String("[remote]", "Season:", tostring(season))
    Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { season })
    return true
end

--- Sends a request to set a season length.
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function Remote.SetSeasonLength(season, length)
    if not Value.IsSeason(season) then
        DebugErrorInvalidArg(
            "season",
            "must be a season: autumn, winter, spring or summer",
            "SetSeasonLength"
        )
        return false
    end

    if not Value.IsUnsigned(length) or not Value.IsInteger(length) then
        DebugErrorInvalidArg("length", "must be an unsigned integer", "SetSeasonLength")
        return false
    end

    SDK.Debug.String("[remote]", "Season length:", season, "(" .. Value.ToDaysString(length) .. ")")
    Remote.Send(
        'TheWorld:PushEvent("ms_setseasonlength", { season = "%s", length = %d })',
        { season, length }
    )

    return true
end

--- Sends a request to set a snow level.
-- @tparam number delta
-- @treturn boolean
function Remote.SetSnowLevel(delta)
    delta = delta ~= nil and delta or 0

    if TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType("must be in a forest", "SetSnowLevel")
        return false
    end

    if Value.IsUnitInterval(delta) then
        SDK.Debug.String("[remote]", "Snow level:", tostring(delta))
        Remote.Send('TheWorld:PushEvent("ms_setsnowlevel", %0.2f)', { delta })
        return true
    end

    DebugErrorInvalidArg("delta", "must be a unit interval", "SetSnowLevel")
    return false
end

--- Sends a request to set a world delta moisture.
-- @tparam[opt] number delta
-- @treturn boolean
function Remote.SetWorldDeltaMoisture(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("delta", "must be a number", "SetWorldDeltaMoisture")
        return false
    end

    SDK.Debug.String("[remote]", "World delta moisture:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltamoisture", %d)', { delta })
    return true
end

--- Sends a request to set a world delta wetness.
-- @tparam[opt] number delta
-- @treturn boolean
function Remote.SetWorldDeltaWetness(delta)
    delta = delta ~= nil and delta or 0

    if not Value.IsNumber(delta) then
        DebugErrorInvalidArg("delta", "must be a number", "SetWorldDeltaWetness")
        return false
    end

    SDK.Debug.String("[remote]", "World delta wetness:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Remote
function Remote._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return SDK._DoInitModule(SDK, Remote, "Remote", TheWorld)
end

return Remote
