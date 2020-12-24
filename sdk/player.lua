----
-- Different player functionality.
--
-- Only available when `ThePlayer` global is available.
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

--- Gets a HUD.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Player.GetHUD(player)
    player = player ~= nil and player or ThePlayer
    return player and player.HUD
end

--- Checks if a player is an admin.
-- @tparam[opt] EntityScript player Player instance (owner by default)
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

--- Checks if a player is a ghost.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsGhost(player)
    player = player ~= nil and player or ThePlayer
    return player and player.HasTag and player:HasTag("playerghost")
end

--- Checks if a player is in idle.
-- @tparam[opt] EntityScript player Player instance (owner by default)
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

--- Checks if a player is on a platform.
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn boolean
function Player.IsOnPlatform(player)
    player = player ~= nil and player or ThePlayer
    if Chain.Validate(TheWorld, "Map", "GetPlatformAtPoint")
        and Chain.Validate(player, "GetPosition")
    then
        return TheWorld.Map:GetPlatformAtPoint(Chain.Get(player:GetPosition(), "Get", true))
            and true
            or false
    end
end

--- Checks if a player is over water.
-- @tparam[opt] EntityScript player Player instance (owner by default)
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

--- Checks if a player is an owner.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsOwner(player)
    player = player ~= nil and player or ThePlayer
    return player and ThePlayer and (player.userid == ThePlayer.userid)
end

--- Checks if a player is a real user.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsReal(player)
    player = player ~= nil and player or ThePlayer
    return player and player.userid and string.len(player.userid) > 0 and true or false
end

--- Checks if a player is running.
-- @tparam[opt] EntityScript player Player instance (owner by default)
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

--- Checks if a player is sinking.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsSinking(player)
    player = player ~= nil and player or ThePlayer
    if player and player.AnimState and player.AnimState.IsCurrentAnimation then
        return player.AnimState:IsCurrentAnimation("sink")
            or player.AnimState:IsCurrentAnimation("plank_hop")
    end
end

--- Attributes
-- @section attributes

--- Gets a health value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHealthPercent(player)
    player = player ~= nil and player or ThePlayer
    local health = Chain.Get(player, "replica", "health", "GetPercent", true)
    return health and health * 100
end

--- Gets a health limit value.
--
-- Maximum health when the penalty has been applied.
--
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn number
function Player.GetHealthLimitPercent(player)
    player = player ~= nil and player or ThePlayer
    local penalty = Chain.Get(player, "replica", "health", "GetPenaltyPercent", true)
    return penalty and (1 - penalty) * 100
end

--- Gets a health penalty value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHealthPenaltyPercent(player)
    player = player ~= nil and player or ThePlayer
    local penalty = Chain.Get(player, "replica", "health", "GetPenaltyPercent", true)
    return penalty and penalty * 100
end

--- Gets a hunger value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHungerPercent(player)
    player = player ~= nil and player or ThePlayer
    local hunger = Chain.Get(player, "replica", "hunger", "GetPercent", true)
    return hunger and hunger * 100
end

--- Gets a sanity value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetSanityPercent(player)
    player = player ~= nil and player or ThePlayer
    local sanity = Chain.Get(player, "replica", "sanity", "GetPercent", true)
    return sanity and sanity * 100
end

--- Light Watcher
-- @section light-watcher

--- Gets a time in the dark.
-- @treturn number
function Player.GetTimeInDark(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "GetTimeInDark", true)
end

--- Gets a time in the light.
-- @treturn number
function Player.GetTimeInLight(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "GetTimeInLight", true)
end

--- Checks if a player is in the light.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsInLight(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "LightWatcher", "IsInLight", true)
end

--- Movement Prediction
-- @section movement-prediction

--- Checks if the movement prediction is enabled.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.HasMovementPrediction(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "components", "locomotor") ~= nil
end

--- Enables/Disables the movement prediction.
-- @tparam boolean is_enabled
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetMovementPrediction(is_enabled, player)
    if TheWorld.ismastersim then
        Debug.Error("SDK.Player.SetMovementPrediction: Can't be toggled on the master simulation")
        return false
    end

    is_enabled = is_enabled and true or false
    player = player ~= nil and player or ThePlayer

    local locomotor = Chain.Get(player, "components", "locomotor")
    if is_enabled then
        player:EnableMovementPrediction(true)
    elseif locomotor then
        locomotor:Stop()
        player:EnableMovementPrediction(false)
    end

    Debug.String("Movement prediction:", is_enabled and "enabled" or "disabled")
    TheSim:SetSetting("misc", "movementprediction", tostring(is_enabled))

    return is_enabled
end

--- Toggles the movement prediction.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.ToggleMovementPrediction(player)
    player = player ~= nil and player or ThePlayer
    return Player.SetMovementPrediction(not Player.HasMovementPrediction(player), player)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player
function Player._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(Player, "Player", "ThePlayer")
end

return Player
