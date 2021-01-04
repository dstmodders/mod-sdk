----
-- Different remote functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote
-- @see SDK
-- @see SDK.Remote.Player
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

local function DebugErrorInvalidWorldType(explanation, fn_name)
    fn_name = fn_name ~= nil and fn_name or debug.getinfo(2).name
    DebugError(fn_name, "Invalid world type", explanation and "(" .. explanation .. ")")
end

local function DebugString(...)
    if SDK.Debug then
        SDK.Debug.String("[remote]", ...)
    end
end

--- General
-- @section general

--- Sends a request to gather players.
-- @treturn boolean
function Remote.GatherPlayers()
    DebugString("Gather players")
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

    DebugString("Go next:", entity:GetDisplayName())
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

    DebugString("Rollback:", Value.ToDaysString(days))
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
    DebugString("Force precipitation:", tostring(bool))
    Remote.Send('TheWorld:PushEvent("ms_forceprecipitation", %s)', { tostring(bool) })
    return true
end

--- Sends a request to send a lightning strike.
-- @tparam Vector3 pt Point
-- @treturn boolean
function Remote.SendLightningStrike(pt)
    if not TheWorld:HasTag("forest") then
        DebugErrorInvalidWorldType("must be in a forest", "SendLightningStrike")
        return false
    end

    if not Value.IsPoint(pt) then
        DebugErrorInvalidArg("pt", "must be a point", "SendLightningStrike")
        return false
    end

    local pt_string = string.format("Vector3(%0.2f, %0.2f, %0.2f)", pt.x, pt.y, pt.z)
    DebugString("Send lighting strike:", tostring(pt))
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

    DebugString("Season:", tostring(season))
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

    DebugString("Season length:", season, "(" .. Value.ToDaysString(length) .. ")")
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
        DebugString("Snow level:", tostring(delta))
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

    DebugString("World delta moisture:", tostring(delta))
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

    DebugString("World delta wetness:", tostring(delta))
    Remote.Send('TheWorld:PushEvent("ms_deltawetness", %d)', { delta })
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
    Value = SDK.Utils.Value

    submodules = submodules ~= nil and submodules or {
        Player = "sdk/remote/player",
    }

    SDK._SetModuleName(SDK, Remote, "Remote")
    SDK.LoadSubmodules(Remote, submodules)

    return SDK._DoInitModule(SDK, Remote, "Remote", "ThePlayer")
end

return Remote
