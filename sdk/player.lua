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
local Player = {}

local SDK
local Value

--- Helpers
-- @section helpers

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Player, fn_name, ...)
end

local function DebugErrorInvalidArg(fn_name, arg_name, explanation)
    SDK._DebugErrorInvalidArg(Player, fn_name, arg_name, explanation)
end

local function DebugErrorNoPlayerGhost(fn_name)
    SDK._DebugErrorNoPlayerGhost(Player, fn_name)
end

local function DebugString(...)
    SDK._DebugString("[player]", ...)
end

local function IsValidPlayer(player, fn_name)
    if not Value.IsPlayer(player) then
        DebugErrorInvalidArg(fn_name, "player", "must be a player")
        return false
    end
    return true
end

local function IsValidPlayerAlive(player, fn_name)
    if not IsValidPlayer(player, fn_name) then
        return false
    end

    if player:HasTag("playerghost") then
        DebugErrorNoPlayerGhost(fn_name)
        return false
    end

    return true
end

local function IsValidSetAttributePercent(percent, player, fn_name)
    if not Value.IsPercent(percent) then
        DebugErrorInvalidArg(fn_name, "percent", "must be a percent")
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    return true
end

local function SetAttributeComponentPercent(fn_name, options, percent, player)
    player = player ~= nil and player or ThePlayer

    local component = type(options) == "table" and options.component or options
    local post_validation_fn = type(options) == "table" and options.post_validation_fn
    local pre_validation_fn = type(options) == "table" and options.pre_validation_fn
    local validation_fn = type(options) == "table" and options.validation_fn

    local debug_args = type(options) == "table" and options.debug_args or {
        component:gsub("^%l", string.upper) .. ":",
        Value.ToPercentString(percent),
    }

    local setter_fn = type(options) == "table" and options.setter_fn or function(_component, value)
        _component:SetPercent(math.min(value / 100, 1))
    end

    if (pre_validation_fn and not pre_validation_fn(percent, player))
        or (validation_fn and not validation_fn(percent, player))
        or (not validation_fn and not IsValidSetAttributePercent(percent, player, fn_name))
        or (post_validation_fn and not post_validation_fn(percent, player))
    then
        return false
    end

    local _component = SDK.Utils.Chain.Get(player, "components", component)
    if TheWorld.ismastersim and _component then
        table.insert(debug_args, "(" .. player:GetDisplayName() .. ")")
        DebugString(unpack(debug_args))
        setter_fn(_component, percent)
        return true
    end

    if not TheWorld.ismastersim then
        return SDK.Remote.Player[fn_name](percent, player)
    end

    DebugErrorFn(fn_name, component:gsub("^%l", string.upper) .. " component is not available")
    return false
end

--- General
-- @section general

--- Checks if a key can be handled.
-- @see SDK.FrontEnd.CanHandleKey
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.CanHandleKey(player)
    player = player ~= nil and player or ThePlayer
    return InGamePlay()
        and not Player.IsHUDChatInputScreenOpen(player)
        and not Player.IsHUDConsoleScreenOpen(player)
        and not Player.IsHUDWriteableScreenActive(player)
end

--- Gets a client table.
--
-- Unlike `TheNet.GetClientTable`, a player parameter can be passed which calls
-- `TheNet.GetClientTableForUser` instead. Moreover, a second parameter can be passed to ignore the
-- host.
--
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @tparam[opt] boolean is_host_ignored Should the host be ignored?
-- @treturn table
function Player.GetClientTable(player, is_host_ignored)
    if player and player.userid then
        return TheNet
            and TheNet.GetClientTableForUser
            and TheNet:GetClientTableForUser(player.userid)
    end

    local clients = SDK.Utils.Chain.Get(TheNet, "GetClientTable", true) or {}
    if is_host_ignored
        and type(clients) == "table"
        and not SDK.Utils.Chain.Get(TheNet, "GetServerIsClientHosted", true)
    then
        clients = shallowcopy(clients)
        for k, v in pairs(clients) do
            if v.performance ~= nil then
                table.remove(clients, k) -- remove "host" object
                break
            end
        end
    end

    return clients
end

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

--- Checks if a HUD chat is open.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsHUDChatInputScreenOpen(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "HUD", "IsChatInputScreenOpen", true)
end

--- Checks if a HUD console is open.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsHUDConsoleScreenOpen(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "HUD", "IsConsoleScreenOpen", true)
end

--- Checks if a HUD has an input focus.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsHUDHasInputFocus(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "HUD", "HasInputFocus", true)
end

--- Checks if a HUD writable screen is active.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsHUDWriteableScreenActive(player)
    player = player ~= nil and player or ThePlayer
    local screen = SDK.Utils.Chain.Get(TheFrontEnd, "GetActiveScreen", true)
    if screen then
        local hud = Player.GetHUD(player)
        if hud and screen == hud.writeablescreen then
            return true
        end
    end
    return false
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
    return SDK.Utils.Chain.Get(player, "components", "health", "invincible")
end

--- Checks if a player is on a platform.
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn boolean
function Player.IsOnPlatform(player)
    player = player ~= nil and player or ThePlayer
    if SDK.Utils.Chain.Validate(TheWorld, "Map", "GetPlatformAtPoint")
        and SDK.Utils.Chain.Validate(player, "GetPosition")
    then
        return TheWorld.Map:GetPlatformAtPoint(SDK.Utils.Chain.Get(
            player:GetPosition(),
            "Get",
            true
        )) and true or false
    end
end

--- Checks if a player is over water.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsOverWater(player)
    player = player ~= nil and player or ThePlayer
    local x, y, z = SDK.Utils.Chain.Get(player, "Transform", "GetWorldPosition", true)
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

--- Walks to a certain point.
-- @tparam Vector3 pt Destination point
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.WalkToPoint(pt, player)
    player = player ~= nil and player or ThePlayer
    local playercontroller = SDK.Utils.Chain.Get(player, "components", "playercontroller")
    if playercontroller and playercontroller.locomotor then
        playercontroller:DoAction(BufferedAction(player, nil, ACTIONS.WALKTO, nil, pt))
        return true
    end
    return false
end

--- Attributes
-- @section attributes

--- Gets a health limit percent value.
--
-- Maximum health when the penalty has been applied.
--
-- @tparam[opt] EntityScript player Player instance (the selected one by default)
-- @treturn number
function Player.GetHealthLimitPercent(player)
    player = player ~= nil and player or ThePlayer
    local penalty = SDK.Utils.Chain.Get(player, "replica", "health", "GetPenaltyPercent", true)
    return penalty and (1 - penalty) * 100
end

--- Gets a health penalty percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHealthPenaltyPercent(player)
    player = player ~= nil and player or ThePlayer
    local penalty = SDK.Utils.Chain.Get(player, "replica", "health", "GetPenaltyPercent", true)
    return penalty and penalty * 100
end

--- Gets a health percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHealthPercent(player)
    player = player ~= nil and player or ThePlayer
    local health = SDK.Utils.Chain.Get(player, "replica", "health", "GetPercent", true)
    return health and health * 100
end

--- Gets a hunger percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetHungerPercent(player)
    player = player ~= nil and player or ThePlayer
    local hunger = SDK.Utils.Chain.Get(player, "replica", "hunger", "GetPercent", true)
    return hunger and hunger * 100
end

--- Gets a moisture percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetMoisturePercent(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "GetMoisture", true)
end

--- Gets a sanity percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetSanityPercent(player)
    player = player ~= nil and player or ThePlayer
    local sanity = SDK.Utils.Chain.Get(player, "replica", "sanity", "GetPercent", true)
    return sanity and sanity * 100
end

--- Gets a temperature value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetTemperature(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "GetTemperature", true)
end

--- Gets a wereness percent value.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.GetWerenessPercent(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "player_classified", "currentwereness", "value", true)
end

--- Sets a health limit percent value.
-- @see SDK.Remote.Player.SetHealthLimitPercent
-- @tparam number percent Health limit percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthLimitPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthLimitPercent", {
        component = "health",
        debug_args = { "Health limit:", Value.ToPercentString(percent) },
        setter_fn = function(component, value)
            component:SetPenalty(1 - (value / 100))
        end,
    }, percent, player)
end

--- Sets a health penalty percent value.
-- @see SDK.Remote.Player.SetHealthPenaltyPercent
-- @tparam number percent Health penalty percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthPenaltyPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPenaltyPercent", {
        component = "health",
        debug_args = { "Health penalty:", Value.ToPercentString(percent) },
        setter_fn = function(component, value)
            component:SetPenalty(value / 100)
        end,
    }, percent, player)
end

--- Sets a health percent value.
-- @see SDK.Remote.Player.SetHealthPercent
-- @tparam number percent Health percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetHealthPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPercent", "health", percent, player)
end

--- Sets a hunger percent value.
-- @see SDK.Remote.Player.SetHungerPercent
-- @tparam number percent Hunger percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetHungerPercent(percent, player)
    return SetAttributeComponentPercent("SetHungerPercent", "hunger", percent, player)
end

--- Sets a moisture percent value.
-- @see SDK.Remote.Player.SetMoisturePercent
-- @tparam number percent Moisture percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetMoisturePercent(percent, player)
    return SetAttributeComponentPercent("SetMoisturePercent", "moisture", percent, player)
end

--- Sets a sanity percent value.
-- @see SDK.Remote.Player.SetSanityPercent
-- @tparam number percent Sanity percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetSanityPercent(percent, player)
    return SetAttributeComponentPercent("SetSanityPercent", "sanity", percent, player)
end

--- Sets a temperature value.
-- @see SDK.Remote.Player.SetTemperature
-- @tparam number temperature Temperature
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetTemperature(temperature, player)
    player = player ~= nil and player or ThePlayer

    local fn_name = "SetTemperature"

    if not Value.IsEntityTemperature(temperature) then
        DebugErrorInvalidArg(fn_name, "temperature", "must be an entity temperature")
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    local component = SDK.Utils.Chain.Get(player, "components", "temperature")
    if TheWorld.ismastersim and component then
        DebugString(
            "Temperature:",
            Value.ToDegreeString(temperature),
            "(" .. player:GetDisplayName() .. ")"
        )
        component:SetTemperature(temperature)
        return true
    end

    if not TheWorld.ismastersim then
        return SDK.Remote.Player.SetTemperature(temperature, player)
    end

    DebugErrorFn(fn_name, "Temperature component is not available")
    return false
end

--- Sets a wereness percent value.
-- @see SDK.Remote.Player.SetWerenessPercent
-- @tparam number percent Wereness percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Player.SetWerenessPercent(percent, player)
    return SetAttributeComponentPercent("SetWerenessPercent", {
        component = "wereness",
        post_validation_fn = function(_, _player)
            if not _player:HasTag("werehuman") then
                DebugErrorFn("SetWerenessPercent", "Player should be a Woodie")
                return false
            end
            return true
        end,
    }, percent, player)
end

--- Light Watcher
-- @section light-watcher

--- Gets a time in the dark.
-- @treturn number
function Player.GetTimeInDark(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "LightWatcher", "GetTimeInDark", true)
end

--- Gets a time in the light.
-- @treturn number
function Player.GetTimeInLight(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "LightWatcher", "GetTimeInLight", true)
end

--- Checks if a player is in the light.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsInLight(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "LightWatcher", "IsInLight", true)
end

--- Movement Prediction
-- @section movement-prediction

--- Checks if the movement prediction is enabled.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.HasMovementPrediction(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "components", "locomotor") ~= nil
end

--- Enables/Disables the movement prediction.
-- @tparam boolean is_enabled
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetMovementPrediction(is_enabled, player)
    if TheWorld.ismastersim then
        DebugErrorFn("SetMovementPrediction", "Can't be toggled on the master simulation")
        return false
    end

    is_enabled = is_enabled and true or false
    player = player ~= nil and player or ThePlayer

    local locomotor = SDK.Utils.Chain.Get(player, "components", "locomotor")
    if is_enabled then
        local x, _, z = player.Transform:GetWorldPosition()
        TheNet:SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, x, z)
        player:EnableMovementPrediction(true)
    elseif locomotor then
        locomotor:Stop()
        player:EnableMovementPrediction(false)
    end

    DebugString("Movement prediction:", is_enabled and "enabled" or "disabled")
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
    Value = SDK.Utils.Value
    return SDK._DoInitModule(SDK, Player, "Player", "ThePlayer")
end

return Player
