----
-- Handles remote player functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Remote.Player
-- @see SDK.Remote
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Player = {}

local SDK
local Remote
local Value

--- Helpers
-- @section helpers

local function ArgPlayer(...)
    return SDK._ArgPlayer(Player, ...)
end

local function ArgPlayerAlive(...)
    return SDK._ArgPlayerAlive(Player, ...)
end

local function ArgPrefab(...)
    return SDK._ArgPrefab(Player, ...)
end

local function ArgRecipe(...)
    return SDK._ArgRecipe(Player, ...)
end

local function DebugErrorFn(...)
    SDK._DebugErrorFn(Player, ...)
end

local function DebugErrorInvalidArg(...)
    SDK._DebugErrorInvalidArg(Player, ...)
end

local function DebugString(...)
    SDK._DebugString("[remote]", "[player]", ...)
end

local function IsValidSetAttributePercent(percent, player, fn_name)
    player = ArgPlayerAlive(fn_name, player)

    if not Value.IsPercent(percent) then
        DebugErrorInvalidArg(fn_name, "percent", "must be a percent")
        return false
    end

    if not player then
        return false
    end

    return true
end

local function SetAttributeComponentPercent(fn_name, options, percent, player)
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    local component = type(options) == "table" and options.component or options
    local debug = type(options) == "table" and options.debug or component:gsub("^%l", string.upper)
    local post_validation_fn = type(options) == "table" and options.post_validation_fn
    local pre_validation_fn = type(options) == "table" and options.pre_validation_fn
    local setter = type(options) == "table" and options.setter or "SetPercent"
    local validation_fn = type(options) == "table" and options.validation_fn

    if
        (pre_validation_fn and not pre_validation_fn())
        or (validation_fn and not validation_fn())
        or (not validation_fn and not IsValidSetAttributePercent(percent, player, fn_name))
        or (post_validation_fn and not post_validation_fn())
    then
        return false
    end

    DebugString(debug .. ":", Value.ToPercentString(percent), "(" .. player:GetDisplayName() .. ")")

    local value = (type(options) == "table" and options.value_fn) and options.value_fn(percent)
        or percent / 100

    return Player.CallFnComponent(component, setter, { math.min(value, 1) }, player)
end

--- General
-- @section general

--- Sends a request to gather players.
-- @treturn boolean
function Player.GatherPlayers()
    DebugString("Gather players")
    Remote.Send("c_gatherplayers()")
    return true
end

--- Sends a request to go next to a certain prefab.
-- @tparam string prefab
-- @treturn boolean
function Player.GoNext(prefab)
    prefab = ArgPrefab("GoNext", prefab)

    if not prefab then
        return false
    end

    DebugString("Go next:", prefab)
    Remote.Send("c_gonext(%s)", { prefab }, true)
    return true
end

--- Attribute
-- @section attribute

--- Sends a request to set a health limit percent.
-- @see SDK.Player.Attribute.SetHealthLimitPercent
-- @tparam number percent Health limit percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthLimitPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthLimitPercent", {
        component = "health",
        debug = "Health limit",
        setter = "SetPenalty",
        value_fn = function(value)
            return 1 - (value / 100)
        end,
    }, percent, player)
end

--- Sends a request to set a health penalty percent.
-- @see SDK.Player.Attribute.SetHealthPenaltyPercent
-- @tparam number percent Health penalty percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthPenaltyPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPenaltyPercent", {
        component = "health",
        debug = "Health penalty",
        setter = "SetPenalty",
    }, percent, player)
end

--- Sends a request to set a health percent.
-- @see SDK.Player.Attribute.SetHealthPercent
-- @tparam number percent Health percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthPercent", "health", percent, player)
end

--- Sends a request to set a hunger percent.
-- @see SDK.Player.Attribute.SetHungerPercent
-- @tparam number percent Hunger percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHungerPercent(percent, player)
    return SetAttributeComponentPercent("SetHungerPercent", "hunger", percent, player)
end

--- Sends a request to set a moisture percent.
-- @see SDK.Player.Attribute.SetMoisturePercent
-- @tparam number percent Moisture percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetMoisturePercent(percent, player)
    return SetAttributeComponentPercent("SetMoisturePercent", "moisture", percent, player)
end

--- Sends a request to set a sanity percent.
-- @see SDK.Player.Attribute.SetSanityPercent
-- @tparam number percent Sanity percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetSanityPercent(percent, player)
    return SetAttributeComponentPercent("SetSanityPercent", "sanity", percent, player)
end

--- Sends a request to set a temperature.
-- @see SDK.Player.Attribute.SetTemperature
-- @tparam number temperature Temperature percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetTemperature(temperature, player)
    local fn_name = "SetTemperature"
    player = ArgPlayerAlive(fn_name, player)

    if not player then
        return false
    end

    if not Value.IsEntityTemperature(temperature) then
        DebugErrorInvalidArg(fn_name, "temperature", "must be an entity temperature")
        return false
    end

    DebugString(
        "Temperature:",
        Value.ToDegreeString(temperature),
        "(" .. player:GetDisplayName() .. ")"
    )

    return Player.CallFnComponent("temperature", "SetTemperature", { temperature }, player)
end

--- Sends a request to set a wereness percent.
-- @see SDK.Player.Attribute.SetWerenessPercent
-- @tparam number percent Wereness percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetWerenessPercent(percent, player)
    return SetAttributeComponentPercent("SetWerenessPercent", {
        component = "wereness",
        post_validation_fn = function()
            if Value.IsPlayer(player) and not player:HasTag("werehuman") then
                DebugErrorFn("SetWerenessPercent", "Player should be a Woodie")
                return false
            end
            return true
        end,
    }, percent, player)
end

--- Call
-- @section call

--- Sends a request to call a function.
--
-- @usage SDK.Remote.Player.CallFn("AddTag", "foobar", ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar"):AddTag("foobar")
--
-- @usage SDK.Remote.Player.CallFn("RemoveFromScene", "nil", ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar"):RemoveFromScene(nil)
--
-- @usage SDK.Remote.Player.CallFn("ReturnToScene", nil, ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar"):ReturnToScene()
--
-- @tparam string name Function name
-- @tparam string args Function arguments
-- @tparam[opt] EntityScript player Player instance (owner by default)
function Player.CallFn(name, args, player)
    local fn_name = "CallFn"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    if args then
        local serialized = Remote.Serialize(args)
        if not serialized then
            DebugErrorInvalidArg(fn_name, "args", "can't be serialized")
            return false
        end

        Remote.Send("%s:%s(%s)", {
            Remote.Serialize(player),
            name,
            type(args) == "table" and table.concat(serialized, ", ") or serialized,
        })

        return true
    end

    Remote.Send("%s:%s()", { Remote.Serialize(player), name })
    return true
end

--- Sends a request to call a component function.
--
-- @usage SDK.Remote.Player.CallFnComponent("temperature", "SetTemperature", 36, ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar").components.temperature:SetTemperature(36)
--
-- @usage SDK.Remote.Player.CallFnComponent("temperature", "SetTemperatureInBelly", { 3, 5 }, ThePlayer)
-- -- LookupPlayerInstByUserID("KU_foobar").components.temperature:SetTemperatureInBelly(3, 5)
--
-- @tparam string component Component name
-- @tparam string name Component function name
-- @tparam string args Component function arguments
-- @tparam[opt] EntityScript player Player instance (owner by default)
function Player.CallFnComponent(component, name, args, player)
    local fn_name = "CallFnComponent"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    if args then
        local serialized = Remote.Serialize(args)
        if not serialized then
            DebugErrorInvalidArg(fn_name, "args", "can't be serialized")
            return false
        end

        Remote.Send("%s.components.%s:%s(%s)", {
            Remote.Serialize(player),
            component,
            name,
            type(args) == "table" and table.concat(serialized, ", ") or serialized,
        })
        return true
    end

    Remote.Send("%s.components.%s:%s()", { Remote.Serialize(player), component, name })
    return true
end

--- Craft
-- @section craft

--- Sends a request to lock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.LockRecipe(recipe, player)
    local fn_name = "LockRecipe"
    recipe = ArgRecipe(fn_name, recipe)
    player = ArgPlayer(fn_name, player)

    if not recipe or not player then
        return false
    end

    DebugString("Lock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
    Remote.Send(
        "player = %s "
            .. "for k, v in pairs(player.components.builder.recipes) do "
            .. 'if v == "%s" then '
            .. "table.remove(player.components.builder.recipes, k) "
            .. "end "
            .. "end "
            .. 'player.replica.builder:RemoveRecipe("%s")',
        {
            Remote.Serialize(player),
            recipe,
            recipe,
        }
    )

    return true
end

--- Sends a request to unlock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.UnlockRecipe(recipe, player)
    local fn_name = "UnlockRecipe"
    recipe = ArgRecipe(fn_name, recipe)
    player = ArgPlayer(fn_name, player)

    if not recipe or not player then
        return false
    end

    DebugString("Unlock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
    Remote.Send(
        "player = %s "
            .. "player.components.builder:AddRecipe(%s) "
            .. 'player:PushEvent("unlockrecipe", %s)',
        {
            player,
            recipe,
            { recipe = recipe },
        },
        true
    )

    return true
end

--- Sends a request to toggle a free crafting.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.ToggleFreeCrafting(player)
    player = ArgPlayer("ToggleFreeCrafting", player)

    if not player then
        return false
    end

    DebugString("Toggle free crafting:", player:GetDisplayName())
    Remote.Send('player = %s player.components.%s:%s() player:PushEvent("techlevelchange")', {
        Remote.Serialize(player),
        "builder",
        "GiveAllRecipes",
    })

    return true
end

--- MiniMap
-- @section minimap

--- Reveals a whole map.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.RevealMiniMap(player)
    player = ArgPlayer("Reveal", player)

    if not player then
        return false
    end

    DebugString("Reveal minimap:", player:GetDisplayName())
    Remote.Send(
        "player = %s width, height = TheWorld.Map:GetSize() "
            .. "for x = -(width * 2), width * 2, 30 do "
            .. "for y = -(height * 2), (height * 2), 30 do "
            .. "player.player_classified.MapExplorer:RevealArea(x, 0, y) "
            .. "end "
            .. "end",
        {
            player,
        },
        true
    )

    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam SDK.Remote parent
-- @treturn SDK.Remote.Player
function Player._DoInit(sdk, parent)
    SDK = sdk
    Remote = parent
    Value = SDK.Utils.Value
    return Player
end

return Player
