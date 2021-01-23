----
-- Handles time functionality.
--
-- _**NB!** Requires_ `SDK.Remote` _to be loaded to work on dedicated servers with administrator
-- rights._
--
-- _**NB!** In gameplay, when calling from the client side, other players will experience time
-- scale mismatch._
--
-- Works in both gameplay and outside of it. During gameplay, in master instances, it tries to set a
-- time scale locally. On non-master instances (dedicated servers) it calls
-- `SDK.Remote.SetTimeScale` function for sending a request to change the time scale.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Time
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Time = {
    time_scale_prev = 1,
}

local SDK
local Value

--- Helpers
-- @section helpers

local function ArgNumber(...)
    return SDK._ArgNumber(Time, ...)
end

local function ArgUnsigned(...)
    return SDK._ArgUnsigned(Time, ...)
end

local function DebugErrorFn(...)
    SDK._DebugErrorFn(Time, ...)
end

local function DebugNoticeTimeScaleMismatch(...)
    SDK._DebugNoticeTimeScaleMismatch(Time, ...)
end

local function DebugString(...)
    SDK._DebugString("[time]", ...)
end

--- Pause
-- @section pause

--- Checks if a game is paused.
-- @treturn boolean
function Time.IsPaused()
    return Time.GetTimeScale() == 0
end

--- Pauses a game.
-- @see SDK.Remote.SetTimeScale
-- @treturn boolean
function Time.Pause()
    if Time.IsPaused() then
        DebugErrorFn("Pause", "Game is already paused")
        return false
    end

    local time_scale = Time.GetTimeScale()

    DebugString("Pause game")
    Time.time_scale_prev = time_scale
    TheSim:SetTimeScale(0)
    SetPause(true, "console")

    if InGamePlay()
        and TheWorld
        and not TheWorld.ismastersim
        and SDK.IsLoaded("Remote")
        and SDK.Remote.SetTimeScale(0)
    then
        DebugNoticeTimeScaleMismatch("Pause")
    end

    return true
end

--- Resumes a game from a pause.
-- @see SDK.Remote.SetTimeScale
-- @treturn boolean
function Time.Resume()
    if not Time.IsPaused() then
        DebugErrorFn("Resume", "Game is already resumed")
        return false
    end

    local time_scale = Time.time_scale_prev or 1

    DebugString("Resume game")
    Time.time_scale_prev = 0
    TheSim:SetTimeScale(time_scale)
    SetPause(false, "console")

    if InGamePlay()
        and TheWorld
        and not TheWorld.ismastersim
        and SDK.IsLoaded("Remote")
        and SDK.Remote.SetTimeScale(time_scale)
    then
        DebugNoticeTimeScaleMismatch("Resume")
    end

    return true
end

--- Toggles a game pause.
-- @see Pause
-- @see Resume
-- @treturn boolean
function Time.TogglePause()
    if Time.IsPaused() then
        return Time.Resume()
    end
    return Time.Pause()
end

--- Time Scale
-- @section time-scale

--- Gets a time scale.
-- @treturn number
function Time.GetTimeScale()
    return TheSim:GetTimeScale()
end

--- Sets a delta time scale.
-- @see SetTimeScale
-- @tparam number delta
-- @treturn boolean
function Time.SetDeltaTimeScale(delta)
    delta = ArgNumber("SetDeltaTimeScale", delta or 0, "delta")

    if not delta then
        return false
    end

    local time_scale
    time_scale = Time.GetTimeScale() + delta
    time_scale = time_scale < 0 and 0 or time_scale
    time_scale = time_scale >= 4 and 4 or time_scale

    DebugString("Delta time scale:", Value.ToFloatString(delta))
    return Time.SetTimeScale(time_scale)
end

--- Sets a time scale.
-- @see SDK.Remote.SetTimeScale
-- @see SetDeltaTimeScale
-- @tparam number time_scale
-- @treturn boolean
function Time.SetTimeScale(time_scale)
    time_scale = ArgUnsigned("SetTimeScale", time_scale, "time_scale")

    if not time_scale then
        return false
    end

    DebugString("Time scale:", Value.ToFloatString(time_scale))
    TheSim:SetTimeScale(time_scale)

    if InGamePlay()
        and TheWorld
        and not TheWorld.ismastersim
        and SDK.IsLoaded("Remote")
        and SDK.Remote.SetTimeScale(time_scale)
    then
        DebugNoticeTimeScaleMismatch("SetTimeScale")
    end

    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Time
function Time._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return SDK._DoInitModule(SDK, Time, "Time")
end

return Time
