----
-- Inventory.
--
-- Includes inventory functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Inventory
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Chain = require "sdk/utils/chain"
local Constant = require "sdk/utils/constant"
local Debug = require "sdk/utils/debug"

local Inventory = {}

local SDK

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

    local _SendRPCToServer = is_using_the_net and function(...)
        return TheNet:SendRPCToServer(...)
    end or SendRPCToServer

    if item:HasTag("_equippable") then
        if Chain.Get(item, "replica", "equippable", "EquipSlot", true) then
            _SendRPCToServer(RPC.SwapEquipWithActiveItem)
        end
        _SendRPCToServer(RPC.EquipActiveItem)
        return true
    else
        Debug.Error(
            "SDK.Inventory.EquipActiveItem():",
            "not equippable",
            "(" ..  Constant.GetStringName(item.prefab) .. ")"
        )
    end

    return false
end

--- Gets an active item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetActiveItem(player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetActiveItem()
end

--- Gets an inventory.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetInventory(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "replica", "inventory")
end

--- Gets inventory items.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetItems(player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetItems()
end

--- Gets an equipped item by slot.
-- @tparam string slot `EQUIPSLOTS`
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedItem(slot, player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.GetInventory(player)
    return inventory and inventory:GetEquippedItem(slot)
end

--- Gets an equipped body item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBodyItem(player)
    player = player ~= nil and player or ThePlayer
    return Inventory.GetEquippedItem(EQUIPSLOTS.BODY, player)
end

--- Gets an equipped hands item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedHandsItem(player)
    player = player ~= nil and player or ThePlayer
    return Inventory.GetEquippedItem(EQUIPSLOTS.HANDS, player)
end

--- Gets an equipped head item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedHeadItem(player)
    player = player ~= nil and player or ThePlayer
    return Inventory.GetEquippedItem(EQUIPSLOTS.HEAD, player)
end

--- Checks if having an equipped item with a certain tag.
-- @tparam string slot `EQUIPSLOTS`
-- @tparam string tag Tag
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function Inventory.HasEquippedItemWithTag(slot, tag, player)
    player = player ~= nil and player or ThePlayer
    local item = Inventory.GetEquippedItem(slot)
    return item and item.HasTag and item:HasTag(tag)
end

--- Backpack
-- @section backpack

--- Gets an equipped backpack.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpack(player)
    player = player ~= nil and player or ThePlayer
    local item = Inventory.GetEquippedBodyItem(player)
    return item and item:HasTag("backpack") and item
end

--- Gets an equipped backpack container.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpackContainer(player)
    local backpack = Inventory.GetEquippedBackpack(player)
    if backpack then
        return SDK.World.IsMasterSim()
            and Chain.Get(backpack, "components", "container")
            or Chain.Get(backpack, "replica", "container", "classified")
    end
end

--- Gets an equipped backpack items.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpackItems(player)
    local container = Inventory.GetEquippedBackpackContainer(player)
    return container and SDK.World.IsMasterSim() and container.slots or container:GetItems()
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Inventory
function Inventory._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(Inventory, "Inventory", "ThePlayer")
end

return Inventory
