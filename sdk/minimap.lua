----
-- Handles minimap functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.MiniMap
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local MiniMap = {}

local SDK

--- General
-- @section general

--- Gets zoom.
-- @treturn number Zoom
function MiniMap.GetZoom()
    return TheWorld.minimap.MiniMap:GetZoom()
end

--- Gets is shown state.
-- @treturn boolean
function MiniMap.IsShown()
    return TheWorld.minimap.MiniMap.shown
end

--- Translates map position to world position.
-- @tparam number x X-axis map value
-- @tparam number y Y-axis map value
-- @tparam number z Z-axis map value
-- @treturn number X-axis world value
-- @treturn number Y-axis world value
-- @treturn number Z-axis world value
function MiniMap.MapPosToWorldPos(x, y, z)
    return TheWorld.minimap.MiniMap:MapPosToWorldPos(x, y, z)
end

--- Translates world position to map position.
-- @tparam number x X-axis world value
-- @tparam number y Y-axis world value
-- @tparam number z Z-axis world value
-- @treturn number X-axis map value
-- @treturn number Y-axis map value
-- @treturn number Z-axis map value
function MiniMap.WorldPosToMapPos(x, y, z)
    return TheWorld.minimap.MiniMap:WorldPosToMapPos(x, y, z)
end

--- Translates world position to screen position.
-- @tparam number x X-axis world value
-- @tparam number z Z-axis world value
-- @treturn number X-axis screen value
-- @treturn number Z-axis screen value
function MiniMap.WorldPosToScreenPos(x, z)
    local sw, sh = TheSim:GetScreenSize()
    local hx, hy = RESOLUTION_X / 2, RESOLUTION_Y / 2
    local mx, my = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local sx = ((mx * hx) + hx) / RESOLUTION_X * sw
    local sy = ((my * hy) + hy) / RESOLUTION_Y * sh
    return sx, sy
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.MiniMap
function MiniMap._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, MiniMap, "MiniMap", "TheWorld")
end

return MiniMap