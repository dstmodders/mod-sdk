----
-- Handles front-end functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.FrontEnd
-- @see SDK
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local FrontEnd = {}

local SDK

--- General
-- @section general

--- Gets an active screen
-- @treturn boolean
function FrontEnd.GetActiveScreen()
    return SDK.Utils.Chain.Get(TheFrontEnd, "GetActiveScreen", true)
end

--- Gets a focused widget.
-- @treturn Widget
function FrontEnd.GetFocusWidget()
    return SDK.Utils.Chain.Get(TheFrontEnd, "GetFocusWidget", true)
end

--- Checks if an image widget is focused.
--
-- Supports an optional `texture` parameter which will match an image texture using `string.find`
-- and return if the focused image matches it.
--
-- @tparam[opt] string texture Texture name (can be only a part of the name)
-- @treturn boolean
function FrontEnd.HasImageWidgetFocus(texture)
    local widget = FrontEnd.GetFocusWidget()
    if texture ~= nil
        and widget
        and widget.name == "Image"
        and type(widget.texture) == "string"
    then
        return widget.texture:find(texture) and true or false
    end
    return widget and widget.name == "Image" or false
end

--- Checks if a text widget is focused.
-- @treturn boolean
function FrontEnd.HasTextWidgetFocus()
    local widget = FrontEnd.GetFocusWidget()
    return widget and widget.name == "Text" or false
end

--- Checks if has a UI input focus.
--
-- When `ThePlayer` is available, it gets `ThePlayer.HUD:HasInputFocus()` value. In other cases it
-- checks for which widget is focused and acts accordingly.
--
-- @see SDK.Input.AddConfigKeyDownHandler
-- @see SDK.Input.AddConfigKeyHandler
-- @see SDK.Input.AddConfigKeyUpHandler
-- @treturn boolean
function FrontEnd.HasInputFocus()
    if ThePlayer then
        return SDK.Utils.Chain.Get(ThePlayer, "HUD", "HasInputFocus", true)
    end
    return FrontEnd.HasTextWidgetFocus()
        or FrontEnd.HasImageWidgetFocus("spinner")
        or FrontEnd.HasImageWidgetFocus("arrow")
        or FrontEnd.HasImageWidgetFocus("scrollbar")
end

--- Checks if a certain screen is open.
-- @tparam string name
-- @treturn boolean
function FrontEnd.IsScreenOpen(name)
    local screen = FrontEnd.GetActiveScreen()
    return screen and screen.name == name or false
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.FrontEnd
function FrontEnd._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, FrontEnd, "FrontEnd", "TheFrontEnd")
end

return FrontEnd
