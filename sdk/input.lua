----
-- Input.
--
-- Includes input functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Input
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Input = {}

local SDK

--- Helpers
-- @section helpers

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config, SDK.modname)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

--- General
-- @section general

--- Checks if move control.
-- @tparam number control
-- @treturn number
function Input.IsControlMove(control)
    return control == CONTROL_MOVE_UP
        or control == CONTROL_MOVE_DOWN
        or control == CONTROL_MOVE_LEFT
        or control == CONTROL_MOVE_RIGHT
end

--- Adds config key handler.
-- @tparam string config
-- @tparam function fn
function Input.AddConfigKeyHandler(config, fn)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyHandler(function(key, down)
            if key == config_key then
                fn(down)
            end
        end)
    end
end

--- Adds config key down handler.
-- @tparam string config
-- @tparam function fn
function Input.AddConfigKeyDownHandler(config, fn)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyDownHandler(config_key, fn)
    end
end

--- Adds config key up handler.
-- @tparam string config
-- @tparam function fn
function Input.AddConfigKeyUpHandler(config, fn)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyUpHandler(config_key, function()
            fn()
        end)
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes input.
-- @tparam SDK sdk
-- @treturn SDK.Input
function Input._DoInit(sdk)
    SDK = sdk
    return Input
end

return Input
