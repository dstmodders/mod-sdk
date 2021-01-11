----
-- Different front-end functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.FrontEnd
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local FrontEnd = {}

local SDK

--- General
-- @section general

--- Checks if a key can be handled.
-- @see SDK.Player.CanPressKeyInGamePlay
-- @treturn boolean
function FrontEnd.CanHandleKey()
    if ThePlayer then
        if SDK.Utils.Chain.Get(ThePlayer, "HUD", "HasInputFocus", true) then
            return false
        end

        if ThePlayer.HUD and FrontEnd.GetActiveScreen() == ThePlayer.HUD.writeablescreen then
            return false
        end
    end

    return not (FrontEnd.HasModConfigurationScreenInputFocus()
        or FrontEnd.HasTextFocus()
        or FrontEnd.IsScreenOpen("ChatInputScreen")
        or FrontEnd.IsScreenOpen("ConsoleScreen"))
end

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
function FrontEnd.HasImageFocus(texture)
    local widget = FrontEnd.GetFocusWidget()
    if texture ~= nil
        and widget
        and widget.name == "Image"
        and type(widget.texture) == "string"
    then
        return widget.texture:find(texture)
    end
    return widget and widget.name == "Image"
end

--- Checks if a mod config screen has an input focus.
-- @treturn boolean
function FrontEnd.HasModConfigurationScreenInputFocus()
    return FrontEnd.IsScreenOpen("ModConfigurationScreen") and (FrontEnd.HasImageFocus("spinner")
        or FrontEnd.HasImageFocus("arrow")
        or FrontEnd.HasImageFocus("scrollbar"))
end

--- Checks if a text widget is focused.
-- @treturn boolean
function FrontEnd.HasTextFocus()
    local widget = FrontEnd.GetFocusWidget()
    return widget and widget.name == "Text"
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
