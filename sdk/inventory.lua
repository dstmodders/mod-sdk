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

local Inventory = {}

local SDK

--- General
-- @section general

--- Gets an inventory.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.Get(player)
    player = player ~= nil and player or ThePlayer
    return Chain.Get(player, "replica", "inventory")
end

--- Gets an active item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetActiveItem(player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.Get(player)
    return inventory and inventory:GetActiveItem()
end

--- Gets inventory items.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetItems(player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.Get(player)
    return inventory and inventory:GetItems()
end

--- Gets an equipped item by slot.
-- @tparam string slot `EQUIPSLOTS`
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedItem(slot, player)
    player = player ~= nil and player or ThePlayer
    local inventory = Inventory.Get(player)
    return inventory and inventory:GetEquippedItem(slot)
end

--- Gets a backpack.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBackpack(player)
    player = player ~= nil and player or ThePlayer
    local item = Inventory.GetEquippedBodyItem(player)
    return item and item:HasTag("backpack") and item
end

--- Gets an equipped body item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedBodyItem(player)
    player = player ~= nil and player or ThePlayer
    return Inventory.GetEquippedHeadItem(EQUIPSLOTS.BODY, player)
end

--- Gets an equipped head item.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Inventory.GetEquippedHeadItem(player)
    player = player ~= nil and player or ThePlayer
    return Inventory.GetEquippedHeadItem(EQUIPSLOTS.HEAD, player)
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
