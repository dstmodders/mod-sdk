----
-- Handles player vision functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Player.Vision
-- @see SDK.Player
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Vision = {}

local SDK

--- Helpers
-- @section helpers

local function ArgPlayer(...)
    return SDK._ArgPlayer(Vision, ...)
end

local function GetComponent(fn_name, entity, name)
    return SDK._GetComponent(Vision, fn_name, entity, name)
end

--- General
-- @section general

--- Gets `PlayerVision` component.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Vision.GetPlayerVision(player)
    local fn_name = "GetPlayerVision"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    local component = GetComponent(fn_name, player, "playervision")
    if not component then
        return false
    end

    return component
end

--- Gets a colour cubes table.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Vision.GetCCTable(player)
    player = ArgPlayer("GetCCTable", player)

    if not player then
        return false
    end

    local component = Vision.GetPlayerVision(player)
    if component then
        return SDK.Utils.Chain.Get(component, "GetCCTable", true)
    end
end

--- Gets a colour cubes table override.
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Vision.GetCCTableOverride(player)
    player = ArgPlayer("GetCCTableOverride", player)

    if not player then
        return false
    end

    local component = Vision.GetPlayerVision(player)
    if component then
        return component.overridecctable
    end
end

--- Sets a colour cubes table override.
-- @tparam table cct Colour cubes table
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn table
function Vision.SetCCTableOverride(cct, player)
    player = ArgPlayer("SetCCTableOverride", player)

    if not player then
        return false
    end

    local component = Vision.GetPlayerVision(player)
    if component then
        component.overridecctable = cct
        player:PushEvent("ccoverrides", cct)
        return true
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player.Vision
function Vision._DoInit(sdk)
    SDK = sdk
    return Vision
end

return Vision
