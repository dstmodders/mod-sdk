----
-- Different remote player functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Remote.Player
-- @see SDK
-- @see SDK.Remote
--
-- @author Victor Popkov
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

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Player, fn_name, ...)
end

local function DebugErrorInvalidArg(fn_name, arg_name, explanation)
    SDK._DebugErrorInvalidArg(Player, fn_name, arg_name, explanation)
end

local function DebugErrorInvalidWorldType(fn_name, explanation)
    SDK._DebugErrorInvalidWorldType(Player, fn_name, explanation)
end

local function DebugErrorNoPlayerGhost(fn_name)
    SDK._DebugErrorNoPlayerGhost(Player, fn_name)
end

local function DebugString(...)
    SDK._DebugString("[remote]", "[player]", ...)
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

local function IsValidRecipe(recipe, fn_name)
    if not Value.IsRecipeValid(recipe) then
        DebugErrorInvalidArg(fn_name, "recipe", "must be a valid recipe")
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
    local debug = type(options) == "table" and options.debug or component:gsub("^%l", string.upper)
    local post_validation_fn = type(options) == "table" and options.post_validation_fn
    local pre_validation_fn = type(options) == "table" and options.pre_validation_fn
    local setter = type(options) == "table" and options.setter or "SetPercent(math.min(%0.2f, 1))"
    local validation_fn = type(options) == "table" and options.validation_fn

    if (pre_validation_fn and not pre_validation_fn())
        or (validation_fn and not validation_fn())
        or (not validation_fn and not IsValidSetAttributePercent(percent, player, fn_name))
        or (post_validation_fn and not post_validation_fn())
    then
        return false
    end

    DebugString(debug .. ":", Value.ToPercentString(percent), "(" .. player:GetDisplayName() .. ")")

    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. 'if player.components.' .. component .. ' then '
            .. 'player.components.' .. component .. ':' .. setter .. ' '
        .. 'end',
        {
            player.userid,
            (type(options) == "table" and options.value_fn)
                and options.value_fn(percent)
                or percent / 100,
        })

    return true
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
    if not Value.IsPrefab(prefab) then
        DebugErrorInvalidArg("GoNext", "prefab", "must be a prefab")
        return false
    end

    DebugString("Go next:", prefab)
    Remote.Send('c_gonext("%s")', { prefab })
    return true
end

--- Sends a request to send a mini earthquake.
-- @tparam[opt] number radius Default: 20
-- @tparam[opt] number amount Default: 20
-- @tparam[opt] number duration Default: 2.5
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SendMiniEarthquake(radius, amount, duration, player)
    radius = radius ~= nil and radius or 20
    amount = amount ~= nil and amount or 20
    duration = duration ~= nil and duration or 2.5
    player = player ~= nil and player or ThePlayer

    local fn_name = "SendMiniEarthquake"

    if not TheWorld:HasTag("cave") then
        DebugErrorInvalidWorldType(fn_name, "must be in a cave")
        return false
    end

    if not Value.IsUnsigned(radius) or not Value.IsInteger(radius) then
        DebugErrorInvalidArg(fn_name, "radius", "must be an unsigned integer")
        return false
    end

    if not Value.IsUnsigned(amount) or not Value.IsInteger(amount) then
        DebugErrorInvalidArg(fn_name, "amount", "must be an unsigned integer")
        return false
    end

    if not Value.IsUnsigned(duration) or not Value.IsNumber(duration) then
        DebugErrorInvalidArg(fn_name, "duration", "must be an unsigned number")
        return false
    end

    if not IsValidPlayer(player, fn_name) then
        return false
    end

    DebugString("Send mini earthquake:", player:GetDisplayName())
    Remote.Send('TheWorld:PushEvent("ms_miniquake", { '
            .. 'target = LookupPlayerInstByUserID("%s"), '
            .. 'rad = %d, '
            .. 'num = %d, '
            .. 'duration = %0.2f '
        .. '})',
        { player.userid, radius, amount, duration })

    return true
end

--- Sends a request to toggle a free crafting.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.ToggleFreeCrafting(player)
    player = player ~= nil and player or ThePlayer

    if not IsValidPlayer(player, "ToggleFreeCrafting") then
        return false
    end

    DebugString("Toggle free crafting:", player:GetDisplayName())
    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. 'player.components.builder:GiveAllRecipes() '
        .. 'player:PushEvent("techlevelchange")',
        { player.userid })

    return true
end

--- Attributes
-- @section attributes

--- Sends a request to set a health limit percent.
-- @see SDK.Player.Attribute.SetHealthLimitPercent
-- @tparam number percent Health limit percent
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.SetHealthLimitPercent(percent, player)
    return SetAttributeComponentPercent("SetHealthLimitPercent", {
        component = "health",
        debug = "Health limit",
        setter = "SetPenalty(%0.2f)",
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
        setter = "SetPenalty(%0.2f)",
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
    player = player ~= nil and player or ThePlayer

    local fn_name = "SetTemperature"

    if not Value.IsEntityTemperature(temperature) then
        DebugErrorInvalidArg(fn_name, "temperature", "must be an entity temperature")
        return false
    end

    if not IsValidPlayerAlive(player, fn_name) then
        return false
    end

    DebugString(
        "Temperature:",
        Value.ToDegreeString(temperature),
        "(" .. player:GetDisplayName() .. ")"
    )

    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. 'if player.components.temperature then '
            .. 'player.components.temperature:SetTemperature(%0.2f) '
        .. 'end',
        { player.userid, temperature })

    return true
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
            if not player:HasTag("werehuman") then
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
-- @tparam string name Function name
-- @tparam string args Function arguments
-- @tparam[opt] EntityScript player Player instance (owner by default)
function Player.CallFn(name, args, player)
    player = player ~= nil and player or ThePlayer

    local serialized = Remote.Serialize(args)
    if not serialized then
        DebugErrorInvalidArg("CallFn", "args", "can't be serialized")
        return false
    end

    Remote.Send('player = LookupPlayerInstByUserID("%s") player:' .. name .. "(%s)", {
        player.userid,
        table.concat(serialized, ", "),
    })

    return true
end

--- Sends a request to call a component function.
-- @tparam string component Component name
-- @tparam string name Component function name
-- @tparam string args Component function arguments
-- @tparam[opt] EntityScript player Player instance (owner by default)
function Player.CallFnComponent(component, name, args, player)
    player = player ~= nil and player or ThePlayer

    local serialized = Remote.Serialize(args)
    if not serialized then
        DebugErrorInvalidArg("CallFnComponent", "args", "can't be serialized")
        return false
    end

    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. "player.components." .. component .. ":" .. name .. "(%s)", {
        player.userid,
        table.concat(serialized, ", "),
    })

    return true
end

--- Sends a request to call a replica function.
-- @tparam string replica Replica name
-- @tparam string name Replica function name
-- @tparam string args Replica function arguments
-- @tparam[opt] EntityScript player Player instance (owner by default)
function Player.CallFnReplica(replica, name, args, player)
    player = player ~= nil and player or ThePlayer

    local serialized = Remote.Serialize(args)
    if not serialized then
        DebugErrorInvalidArg("CallFnReplica", "args", "can't be serialized")
        return false
    end

    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. "player.replica." .. replica .. ":" .. name .. "(%s)", {
        player.userid,
        table.concat(serialized, ", "),
    })

    return true
end

--- Recipes
-- @section recipes

--- Sends a request to lock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.LockRecipe(recipe, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidRecipe(recipe, "LockRecipe") or not IsValidPlayer(player, "LockRecipe") then
        return false
    end

    DebugString("Lock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. 'for k, v in pairs(player.components.builder.recipes) do '
            .. 'if v == "%s" then '
                .. 'table.remove(player.components.builder.recipes, k) '
            .. 'end '
        .. 'end '
        .. 'player.replica.builder:RemoveRecipe("%s")',
        { player.userid, recipe, recipe })

    return true
end

--- Sends a request to unlock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Player.UnlockRecipe(recipe, player)
    player = player ~= nil and player or ThePlayer

    if not IsValidRecipe(recipe, "UnlockRecipe") or not IsValidPlayer(player, "UnlockRecipe") then
        return false
    end

    DebugString("Unlock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
    Remote.Send('player = LookupPlayerInstByUserID("%s") '
        .. 'player.components.builder:AddRecipe("%s") '
        .. 'player:PushEvent("unlockrecipe", { recipe = "%s" })',
        { player.userid, recipe, recipe })

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
