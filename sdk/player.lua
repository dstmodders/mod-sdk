----
-- Player.
--
-- Includes player functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Player
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Chain = require "sdk/utils/chain"
local Debug = require "sdk/debug"

local Player = {}

local SDK

--- General
-- @section general

--- Checks if the player is an admin.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsAdmin(player)
    player = player ~= nil and player or ThePlayer

    if not TheNet or not TheNet.GetClientTable then
        return
    end

    local client_table = TheNet:GetClientTable()
    if type(client_table) == "table" then
        if player and player.userid then
            for _, v in pairs(client_table) do
                if v.userid == player.userid then
                    return v.admin and true or false
                end
            end
        end
    end
end

--- Checks if the player is in idle.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsIdle(player)
    player = player ~= nil and player or ThePlayer
    if player and (player.sg or player.AnimState) then
        if player.sg and player.sg.HasStateTag and player.sg:HasStateTag("idle") then
            return true
        end

        if player.AnimState and not player.AnimState.IsCurrentAnimation then
            return nil
        end

        return player.AnimState:IsCurrentAnimation("idle_loop")
    end
end

--- Checks if a player is invincible.
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn boolean
function Player.IsInvincible(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "components", "health", "invincible")
end

--- Checks if the player is over water.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsOverWater(player)
    player = player ~= nil and player or ThePlayer
    local x, y, z = Chain.Get(player, "Transform", "GetWorldPosition", true)
    if TheWorld and TheWorld.Map and x and y and z then
        return not TheWorld.Map:IsVisualGroundAtPoint(x, y, z)
            and TheWorld.Map:GetTileAtPoint(x, y, z) ~= GROUND.INVALID
            and player:GetCurrentPlatform() == nil
    end
end

--- Checks if the player is the mod owner.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsOwner(player)
    player = player ~= nil and player or ThePlayer
    return player and ThePlayer and (player.userid == ThePlayer.userid)
end

--- Checks if the player is a real user.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsReal(player)
    player = player ~= nil and player or ThePlayer
    return player and player.userid and string.len(player.userid) > 0 and true or false
end

--- Checks if the player is running.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsRunning(player)
    player = player ~= nil and player or ThePlayer
    if player and (player.sg or player.AnimState) then
        if player.sg and player.sg.HasStateTag then
            return player.sg:HasStateTag("run")
        end

        if player.AnimState and not player.AnimState.IsCurrentAnimation then
            return nil
        end

        return player.AnimState:IsCurrentAnimation("run_pre")
            or player.AnimState:IsCurrentAnimation("run_loop")
            or player.AnimState:IsCurrentAnimation("run_pst")
    end
end

--- Light Watcher
-- @section light-watcher

--- Gets the owner time in the dark.
-- @treturn number
function Player.GetTimeInDark(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "GetTimeInDark", true)
end

--- Gets the owner time in the light.
-- @treturn number
function Player.GetTimeInLight(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "GetTimeInLight", true)
end

--- Checks if the owner is in the light.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.IsInLight(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "IsInLight", true)
end

--- Movement Prediction
-- @section movement-prediction

--- Checks if movement prediction is enabled.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.HasMovementPrediction(player)
    player = player ~= nil and player or ThePlayer
    if type(player.components) == "table" then
        return Chain.Get(player, "components", "locomotor") ~= nil
    end
    return false
end

--- Enables/Disables the movement prediction.
-- @tparam boolean is_enabled
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function Player.SetMovementPrediction(is_enabled, player)
    is_enabled = is_enabled and true or false
    player = player ~= nil and player or ThePlayer

    if TheWorld.ismastersim then
        Debug.Error("SDK.Player.SetMovementPrediction: Can't be toggled on the master simulation")
        return false
    end

    if is_enabled then
        player:EnableMovementPrediction(true)
    elseif player.components and player.components.locomotor then
        player.components.locomotor:Stop()
        player:EnableMovementPrediction(false)
    end

    Debug.String("Movement prediction:", is_enabled and "enabled" or "disabled")
    TheSim:SetSetting("misc", "movementprediction", tostring(is_enabled))

    return is_enabled
end

--- Lifecycle
-- @section lifecycle

--- Initializes player.
-- @tparam SDK sdk
-- @treturn SDK.Player
function Player._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(Player, "Player", "ThePlayer")
end

return Player
