----
-- Handles vision functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Vision
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Vision = {
    is_unfading = false,
}

local SDK
local Chain

--- Helpers
-- @section helpers

local function ArgPlayer(...)
    return SDK._ArgPlayer(Vision, ...)
end

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Vision, fn_name, ...)
end

local function DebugString(...)
    SDK._DebugString("[vision]", ...)
end

local function OnPlayerFadeDirty(inst)
    local hud = Chain.Get(inst, "_parent", "HUD")
    if hud and type(inst.isfadein) == "userdata" and type(inst.fadetime) == "userdata" then
        TheFrontEnd:Fade(true, 0)
        TheFrontEnd:SetFadeLevel(0)
        -- the lines below are not really needed
        inst.isfadein:set_local(true)
        inst.fadetime:set_local(0)
    end
end

--- General
-- @section general


--- Gets an unfading state.
-- @treturn boolean
function Vision.IsUnfading()
    return Vision.is_unfading
end

--- Toggles an unfading state.
--
-- When enabled, disables the front-end black/white screen fading.
--
-- @treturn boolean
function Vision.ToggleUnfading(player)
    local fn_name = "ToggleUnfading"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    local classified = player.player_classified
    if not classified then
        DebugErrorFn(
            fn_name,
            "Player classified is not available",
            player.GetDisplayName and "(" .. player:GetDisplayName() .. ")"
        )
        return false
    end

    Vision.is_unfading = not Vision.is_unfading
    if Vision.is_unfading then
        classified:ListenForEvent("playerfadedirty", OnPlayerFadeDirty)
    else
        classified:RemoveEventCallback("playerfadedirty", OnPlayerFadeDirty)
    end

    DebugString("Unfading:", (Vision.is_unfading and "enabled" or "disabled"))
    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Vision
function Vision._DoInit(sdk)
    SDK = sdk
    Chain = SDK.Utils.Chain
    return SDK._DoInitModule(SDK, Vision, "Vision", "ThePlayer")
end

return Vision
