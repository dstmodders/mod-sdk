----
-- Handles player minimap functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Player.MiniMap
-- @see SDK.Player
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local MiniMap = {}

local SDK

--- Helpers
-- @section helpers

local function ArgPlayer(fn_name, value)
    return SDK._ArgPlayer(MiniMap, fn_name, value)
end

local function DebugString(...)
    SDK._DebugString("[minimap]", ...)
end

local function GetPlayerClassified(...)
    return SDK._GetPlayerClassified(MiniMap, ...)
end

--- General
-- @section general

--- Reveals a whole map.
--
-- Uses the player classified `MapExplorer` to reveal the map.
--
-- @tparam[opt] EntityScript player Player instance (owner by default)
-- @treturn boolean
function MiniMap.Reveal(player)
    local fn_name = "Reveal"
    player = ArgPlayer(fn_name, player)

    if not player then
        return false
    end

    if TheWorld.ismastersim then
        local classified = GetPlayerClassified(fn_name, player)
        if not classified then
            return false
        end

        DebugString("Revealing minimap...", "(" .. player:GetDisplayName() .. ")")
        local width, height = TheWorld.Map:GetSize()
        for x = -(width * 2), width * 2, 30 do
            for y = -(height * 2), (height * 2), 30 do
                classified.MapExplorer:RevealArea(x, 0, y)
            end
        end

        DebugString("Minimap has been revealed", "(" .. player:GetDisplayName() .. ")")
        return true
    end

    return SDK.Remote.Player.RevealMiniMap(player)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Player.MiniMap
function MiniMap._DoInit(sdk)
    SDK = sdk
    return MiniMap
end

return MiniMap
