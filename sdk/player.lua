----
-- Handles player functionality.
--
-- Only available when `ThePlayer` global is available.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Player
-- @see SDK
-- @see SDK.Player.Attribute
-- @see SDK.Player.Craft
-- @see SDK.Player.Inventory
-- @see SDK.Player.Vision
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Player = {}

local SDK

--- Helpers
-- @section helpers

local function ArgPlayer(fn_name, value)
    return SDK._ArgPlayer(Player, fn_name, value)
end

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Player, fn_name, ...)
end

local function DebugString(...)
    SDK._DebugString("[player]", ...)
end

local function GetPlayerClassified(...)
    return SDK._GetPlayerClassified(Player, ...)
end

--- General
-- @section general

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
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.IsInvincible(player)
    player = player ~= nil and player or ThePlayer
    return SDK.Utils.Chain.Get(player, "components", "health", "invincible")
end

--- Checks if a player is on a platform.
-- @tparam[opt] EntityScript player Player instance (owner by default)
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

--- Reveals the whole map.
--
-- Uses the player classified `MapExplorer` to reveal the map.
--
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.Reveal(player)
    local fn_name = "Reveal"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    local classified = GetPlayerClassified(fn_name, player)
    if not classified then
        return false
    end

    DebugString("Revealing map...", "(" .. player:GetDisplayName() .. ")")
    local width, height = TheWorld.Map:GetSize()
    for x = -(width * 2), width * 2, 30 do
        for y = -(height * 2), (height * 2), 30 do
            classified.MapExplorer:RevealArea(x, 0, y)
        end
    end
    DebugString("Map has been revealed", "(" .. player:GetDisplayName() .. ")")
    return true
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
-- @tparam table submodules
-- @treturn SDK.Player
function Player._DoInit(sdk, submodules)
    SDK = sdk

    submodules = submodules ~= nil and submodules or {
        Attribute = "sdk/player/attribute",
        Craft = "sdk/player/craft",
        Inventory = "sdk/player/inventory",
        Vision = "sdk/player/vision",
    }

    SDK._SetModuleName(SDK, Player, "Player")
    SDK.LoadSubmodules(Player, submodules)

    return SDK._DoInitModule(SDK, Player, "Player", "ThePlayer")
end

return Player
