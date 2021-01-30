----
-- Handles player craft functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Player.Craft
-- @see SDK.Player
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Craft = {
    character_recipes = {},
}

local SDK
local Value

--- Helpers
-- @section helpers

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(Craft, fn_name, ...)
end

local function DebugString(...)
    SDK._DebugString("[player]", "[craft]", ...)
end

local function ArgPlayer(fn_name, value)
    return SDK._ArgPlayer(Craft, fn_name, value)
end

local function ArgRecipe(fn_name, value)
    return SDK._ArgRecipe(Craft, fn_name, value)
end

local function ArgRecipes(fn_name, value)
    return SDK._ArgRecipes(Craft, fn_name, value)
end

local function GetComponent(fn_name, entity, name)
    return SDK._GetComponent(Craft, fn_name, entity, name)
end

local function GetReplica(fn_name, entity, name)
    return SDK._GetReplica(Craft, fn_name, entity, name)
end

--- Free Crafting
-- @section free-crafting

--- Checks if a player has a free crafting.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Craft.HasFreeCrafting(player)
    player = ArgPlayer("HasFreeCrafting", player)
    return SDK.Utils.Chain.Get(player, "player_classified", "isfreebuildmode", true)
end

--- Sets a temperature value.
-- @see SDK.Remote.Player.ToggleFreeCrafting
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn number
function Craft.ToggleFreeCrafting(player)
    local fn_name = "ToggleFreeCrafting"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    if TheWorld.ismastersim then
        local component = GetComponent(fn_name, player, "builder")
        if not component then
            return false
        end

        DebugString("Toggle free crafting:", player:GetDisplayName())
        component:GiveAllRecipes()
        player:PushEvent("techlevelchange")
        return true
    end

    return SDK.Remote.Player.ToggleFreeCrafting(player)
end

--- Recipe
-- @section recipe

--- Checks if a recipe is learned.
--
-- The learned recipes are retrieved using the `GetLearnedRecipes`.
--
-- **NB!** Free crafting doesn't affect this so it should be handled separately.
--
-- @tparam string recipe Recipe name
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Craft.IsLearnedRecipe(recipe, player)
    local fn_name = "IsLearnedRecipe"
    recipe = ArgRecipe(fn_name, recipe)
    player = ArgPlayer(fn_name, player)
    return recipe and player and SDK.Utils.Table.HasValue(Craft.GetLearnedRecipes(player), recipe)
end

--- Sends a request to lock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Craft.LockRecipe(recipe, player)
    local fn_name = "LockRecipe"
    recipe = ArgRecipe(fn_name, recipe)
    player = ArgPlayer(fn_name, player)

    if not recipe or not player then
        return false
    end

    if TheWorld.ismastersim then
        local component = GetComponent(fn_name, player, "builder")
        if not component then
            return false
        end

        local replica = GetReplica(fn_name, player, "builder")
        if not replica then
            return false
        end

        local recipes = SDK.Utils.Chain.Get(player, "components", "builder", "recipes")
        if not recipes then
            DebugErrorFn(fn_name, "Builder component recipes not found")
            return false
        end

        DebugString("Lock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
        for k, v in pairs(recipes) do
            if v == recipe then
                table.remove(recipes, k)
            end
        end
        replica:RemoveRecipe(recipe)
        return true
    end

    return SDK.Remote.Player.LockRecipe(recipe, player)
end

--- Sends a request to unlock a recipe.
-- @tparam string recipe Valid recipe
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Craft.UnlockRecipe(recipe, player)
    local fn_name = "UnlockRecipe"
    recipe = ArgRecipe(fn_name, recipe)
    player = ArgPlayer(fn_name, player)

    if not recipe or not player then
        return false
    end

    if TheWorld.ismastersim then
        local component = GetComponent(fn_name, player, "builder")
        if not component then
            return false
        end

        DebugString("Unlock recipe:", recipe, "(" .. player:GetDisplayName() .. ")")
        component:AddRecipe(recipe)
        player:PushEvent("unlockrecipe", { recipe = recipe })
        return true
    end

    return SDK.Remote.Player.UnlockRecipe(recipe, player)
end

--- Recipes
-- @section recipes

--- Filters all recipes by a function.
-- @tparam function fn Filter function
-- @tparam[opt] table recipes Recipes to filter (`AllRecipes` by default)
-- @treturn table
function Craft.FilterRecipesBy(fn, recipes)
    recipes = ArgRecipes("FilterRecipesBy", recipes)
    local t = {}
    if type(recipes) == "table" then
        for name, data in pairs(recipes) do
            if fn(name, data) then
                t[name] = data
            end
        end
    end
    return t
end

--- Filters all recipes that have been learned.
-- @tparam[opt] table recipes Recipes to filter (`AllRecipes` by default)
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Craft.FilterRecipesByLearned(recipes, player)
    local fn_name = "FilterRecipesByLearned"
    recipes = ArgRecipes(fn_name, recipes)
    player = ArgPlayer(fn_name, player)

    if not recipes or not player then
        return {}
    end

    return Craft.FilterRecipesBy(function(name)
        return Craft.IsLearnedRecipe(name, player)
    end, recipes)
end

--- Filters all recipes that haven't been learned.
-- @tparam[opt] table recipes Recipes to filter (`AllRecipes` by default)
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Craft.FilterRecipesByNotLearned(recipes, player)
    local fn_name = "FilterRecipesByNotLearned"
    recipes = ArgRecipes(fn_name, recipes)
    player = ArgPlayer(fn_name, player)

    if not recipes or not player then
        return {}
    end

    return Craft.FilterRecipesBy(function(name)
        return not Craft.IsLearnedRecipe(name, player)
    end, recipes)
end

--- Filters all recipes that include a certain field.
-- @tparam string field Field to check
-- @tparam[opt] table recipes Recipes to filter (`AllRecipes` by default)
-- @treturn table
function Craft.FilterRecipesWith(field, recipes)
    recipes = ArgRecipes("FilterRecipesWith", recipes)
    return recipes and Craft.FilterRecipesBy(function(_, data)
        return data[field]
    end, recipes) or {}
end

--- Gets all recipes that exclude a certain field.
-- @tparam string field Field to check
-- @tparam[opt] table recipes Recipes to filter (`AllRecipes` by default)
-- @treturn table
function Craft.FilterRecipesWithout(field, recipes)
    recipes = ArgRecipes("FilterRecipesWithout", recipes)
    return recipes and Craft.FilterRecipesBy(function(_, data)
        return not data[field]
    end, recipes) or {}
end

--- Gets learned recipes.
--
-- **NB!** Free crafting doesn't affect this as it contains only recipes that were learned when it
-- was disabled.
--
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Craft.GetLearnedRecipes(player)
    local fn_name = "GetLearnedRecipes"
    player = ArgPlayer(fn_name, player)

    if not player then
        return
    end

    if TheWorld.ismastersim then
        local component = GetComponent(fn_name, player, "builder")
        return component and component.recipes
    end

    local replica = GetReplica(fn_name, player, "builder")
    if not replica then
        return
    end

    local recipes = SDK.Utils.Chain.Get(replica, "classified", "recipes")
    if not recipes then
        return
    end

    local names = {}
    for name, net_bool in pairs(recipes) do
        if net_bool:value() then
            if Value.IsRecipeValid(name) then
                table.insert(names, name)
            end
        end
    end
    return names
end

--- Locks all character-specific recipes.
--
-- It locks all character-specific recipes except those stored earlier by the
-- `UnlockCharacterRecipes` method.
function Craft.LockAllCharacterRecipes(player)
    player = ArgPlayer("LockAllCharacterRecipes", player)

    if not player then
        return false
    end

    local recipes = Craft.FilterRecipesWith("builder_tag")
    if SDK.Utils.Table.Count(recipes) > 0 then
        DebugString("Locking and restoring all character recipes...")
        for name, _ in pairs(recipes) do
            if not SDK.Utils.Table.HasValue(Craft.character_recipes[player.userid], name) then
                Craft.LockRecipe(name, player)
            end
        end
        Craft.character_recipes[player.userid] = {}
        return true
    end

    DebugErrorFn("LockAllCharacterRecipes", "Character recipes not found")
    return false
end

--- Unlocks all character-specific recipes.
--
-- It stores the originally learned recipes in order to restore them when using the corresponding
-- `LockCharacterRecipes` method and then unlocks all character-specific recipes.
function Craft.UnlockAllCharacterRecipes(player)
    player = ArgPlayer("UnlockAllCharacterRecipes", player)

    if not player then
        return false
    end

    if #Craft.character_recipes[player.userid] == 0 then
        local recipes = Craft.FilterRecipesWith("builder_tag")
        local learned = Craft.FilterRecipesByLearned(recipes, player)
        local learned_total = SDK.Utils.Table.Count(learned)

        if learned_total > 0 then
            DebugString(
                "Storing",
                tostring(learned_total),
                "previously learned character recipes..."
            )

            local t = {}
            for name, _ in pairs(learned) do
                table.insert(t, name)
            end
            Craft.character_recipes[player.userid] = t
        end

        if SDK.Utils.Table.Count(recipes) > 0 then
            DebugString("Unlocking all character recipes...")
            for name, _ in pairs(recipes) do
                Craft.UnlockRecipe(name, player)
            end
        end

        return true
    end

    local total = #Craft.character_recipes[player.userid]
    DebugErrorFn(
        "UnlockAllCharacterRecipes",
        "Already",
        tostring(total),
        (total > 1 or total == 0) and "recipes are stored" or "recipe is stored"
    )

    return false
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player.Craft
function Craft._DoInit(sdk)
    SDK = sdk
    Value = SDK.Utils.Value
    return Craft
end

return Craft
