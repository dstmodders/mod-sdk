----
-- Handles player inventory functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Player.Inventory
-- @see SDK.Player
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Inventory = {}

local SDK

--- Helpers
-- @section helpers

local function ArgPlayer(fn_name, value)
    return SDK._ArgPlayer(Inventory, fn_name, value)
end

local function ArgRecipe(fn_name, value)
    return SDK._ArgRecipe(Inventory, fn_name, value)
end

--- General
-- @section general

--- Equips an active item.
-- @tparam boolean is_using_the_net Use `TheNet:SendRPCToServer()` instead of the `SendRPCToServer()`
-- @treturn boolean
function Inventory.EquipActiveItem(is_using_the_net)
    local item = Inventory.GetActiveItem()
    if not item then
        return false
    end

    local _SendRPCToServer = is_using_the_net
            and function(...)
                return TheNet:SendRPCToServer(...)
            end
        or SendRPCToServer

    if item:HasTag("_equippable") then
        if SDK.Utils.Chain.Get(item, "replica", "equippable", "EquipSlot", true) then
            _SendRPCToServer(RPC.SwapEquipWithActiveItem)
        end
        _SendRPCToServer(RPC.EquipActiveItem)
        return true
    end

    SDK.Debug.Error(
        "SDK.Inventory.EquipActiveItem():",
        "not equippable",
        "(" .. SDK.Constant.GetStringName(item.prefab) .. ")"
    )

    return false
end

--- Gets an active item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetActiveItem(player)
    player = ArgPlayer("GetActiveItem", player)

    if not player then
        return
    end

    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetActiveItem()
end

--- Gets an inventory.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetInventory(player)
    player = ArgPlayer("GetInventory", player)

    if not player then
        return
    end

    return SDK.Utils.Chain.Get(player, "replica", "inventory")
end

--- Gets inventory items.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetInventoryItems(player)
    player = ArgPlayer("GetInventoryItems", player)

    if not player then
        return
    end

    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetItems()
end

--- Gets an equipped item by slot.
-- @tparam string slot `EQUIPSLOTS`
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedItem(slot, player)
    player = ArgPlayer("GetEquippedItem", player)

    if not player then
        return
    end

    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetEquippedItem(slot)
end

--- Gets an equipped body item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBodyItem(player)
    player = ArgPlayer("GetEquippedBodyItem", player)

    if not player then
        return
    end

    return Inventory.GetEquippedItem(EQUIPSLOTS.BODY, player)
end

--- Gets an equipped hands item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedHandsItem(player)
    player = ArgPlayer("GetEquippedHandsItem", player)

    if not player then
        return
    end

    return Inventory.GetEquippedItem(EQUIPSLOTS.HANDS, player)
end

--- Gets an equipped head item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedHeadItem(player)
    player = ArgPlayer("GetEquippedHeadItem", player)

    if not player then
        return
    end

    return Inventory.GetEquippedItem(EQUIPSLOTS.HEAD, player)
end

--- Checks if having an equipped item with a certain tag.
-- @tparam string slot `EQUIPSLOTS`
-- @tparam string tag Tag
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Inventory.HasEquippedItemWithTag(slot, tag, player)
    player = ArgPlayer("HasEquippedItemWithTag", player)

    if not player then
        return
    end

    local item = Inventory.GetEquippedItem(slot, player)
    return item and item:HasTag(tag)
end

--- Checks if enough ingredients to craft from an item.
--
-- **NB!** Free crafting doesn't affect this so it should be handled separately.
--
-- @see SDK.Player.Inventory.HasIngredientsForRecipe
-- @tparam string name Item name
-- @treturn boolean
function Inventory.HasIngredientsForItem(name)
    return Inventory.HasIngredientsForRecipe(GetValidRecipe(name))
end

--- Checks if enough ingredients to craft from a recipe.
--
-- **NB!** Free crafting doesn't affect this so it should be handled separately.
--
-- @see SDK.Player.Inventory.HasIngredientsForItem
-- @tparam table recipe
-- @treturn boolean
function Inventory.HasIngredientsForRecipe(recipe)
    recipe = ArgRecipe("HasIngredientsForRecipe", recipe)

    if not recipe then
        return false
    end

    local inventory = Inventory.GetInventory()
    if not inventory then
        return false
    end

    for _, ingredient in pairs(recipe.ingredients) do
        if not inventory:Has(ingredient.type, ingredient.amount) then
            return false
        end
    end

    return true
end

--- Backpack
-- @section backpack

--- Gets an equipped backpack.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpack(player)
    player = ArgPlayer("GetEquippedBackpack", player)

    if not player then
        return
    end

    local item = Inventory.GetEquippedBodyItem(player)
    return item and item:HasTag("backpack") and item
end

--- Gets an equipped backpack container.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpackContainer(player)
    player = ArgPlayer("GetEquippedBackpackContainer", player)

    if not player then
        return
    end

    local backpack = Inventory.GetEquippedBackpack(player)
    if not backpack then
        return
    end

    local container = SDK.World.IsMasterSim()
            and SDK.Utils.Chain.Get(backpack, "components", "container")
        or SDK.Utils.Chain.Get(backpack, "replica", "container", "classified")

    if not container then
        SDK.Debug.Error("SDK.Inventory.GetEquippedBackpackContainer():", "container not available")
    end
end

--- Gets an equipped backpack items.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpackItems(player)
    player = ArgPlayer("GetEquippedBackpackItems", player)

    if not player then
        return
    end

    local container = Inventory.GetEquippedBackpackContainer(player)
    return container and SDK.World.IsMasterSim() and container.slots or container:GetItems()
end

--- Checks if an equipped backpack is full.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.IsEquippedBackpackFull(player)
    player = ArgPlayer("IsEquippedBackpackFull", player)

    if not player then
        return
    end

    local container = Inventory.GetEquippedBackpackContainer(player)
    return container and container:IsFull()
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player.Inventory
function Inventory._DoInit(sdk)
    SDK = sdk
    return Inventory
end

return Inventory
