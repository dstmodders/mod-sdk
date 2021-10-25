----
-- Handles input functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Input
-- @see SDK
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Input = {}

local SDK

--- Helpers
-- @section helpers

local function DebugErrorFn(...)
    SDK._DebugErrorFn(Input, ...)
end

local function DebugErrorKey(fn_name, key, ...)
    DebugErrorFn(fn_name, "[" .. key .. "]", ...)
end

local function DebugErrorOptions(fn_name, key, msg)
    if msg ~= nil then
        DebugErrorKey(fn_name, key, "Invalid options passed (" .. msg .. ")")
        return
    end
    DebugErrorKey(fn_name, key, "Invalid options passed")
end

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config, SDK.modname)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

local function PrepareOptions(fn_name, key, options)
    if type(options) ~= "table" then
        DebugErrorOptions(fn_name, key, "must be a table")
        return false
    end

    if options.ignore_screens ~= nil and type(options.ignore_screens) ~= "table" then
        DebugErrorOptions(fn_name, key, "ignore_screens must be a table")
        return false
    elseif options.ignore_screens == nil then
        options.ignore_screens = {}
    end

    if options.ignore_console_screen ~= nil
        and type(options.ignore_console_screen) ~= "boolean"
    then
        DebugErrorOptions(fn_name, key, "ignore_console_screen must be a boolean")
        return false
    end

    if options.ignore_map_screen ~= nil
        and type(options.ignore_map_screen) ~= "boolean"
    then
        DebugErrorOptions(fn_name, key, "ignore_map_screen must be a boolean")
        return false
    end

    if options.ignore_has_input_focus ~= nil
        and type(options.ignore_has_input_focus) ~= "boolean"
    then
        DebugErrorOptions(fn_name, key, "ignore_has_input_focus must be a boolean")
        return false
    end

    if options.ignore_console_screen == true then
        table.insert(options.ignore_screens, "ConsoleScreen")
    end

    if options.ignore_map_screen == true then
        table.insert(options.ignore_screens, "MapScreen")
    end

    return options
end

--- General
-- @section general

--- Checks if it's a move control.
-- @tparam number control
-- @treturn number
function Input.IsControlMove(control)
    return control == CONTROL_MOVE_UP
        or control == CONTROL_MOVE_DOWN
        or control == CONTROL_MOVE_LEFT
        or control == CONTROL_MOVE_RIGHT
end

--- Adds a config key handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] table options
function Input.AddConfigKeyHandler(config, fn, options)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        local fn_name = "AddConfigKeyHandler"
        options = PrepareOptions(fn_name, config, options)
        TheInput:AddKeyHandler(function(key, down)
            if key == config_key then
                if options.ignore_has_input_focus ~= true and SDK.FrontEnd.HasInputFocus() then
                    return
                end

                for _, screen in pairs(options.ignore_screens) do
                    if SDK.FrontEnd.IsScreenOpen(screen) then
                        return
                    end
                end

                fn(down)
            end
        end)
    end
end

--- Adds a config key down handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] table options
function Input.AddConfigKeyDownHandler(config, fn, options)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        local fn_name = "AddConfigKeyDownHandler"
        options = PrepareOptions(fn_name, config, options)
        TheInput:AddKeyDownHandler(config_key, function()
            if options.ignore_has_input_focus ~= true and SDK.FrontEnd.HasInputFocus() then
                return
            end

            for _, screen in pairs(options.ignore_screens) do
                if SDK.FrontEnd.IsScreenOpen(screen) then
                    return
                end
            end

            return fn()
        end)
    end
end

--- Adds a config key up handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] table options
function Input.AddConfigKeyUpHandler(config, fn, options)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        local fn_name = "AddConfigKeyUpHandler"
        options = PrepareOptions(fn_name, config, options)
        TheInput:AddKeyUpHandler(config_key, function()
            if options.ignore_has_input_focus ~= true and SDK.FrontEnd.HasInputFocus() then
                return
            end

            for _, screen in pairs(options.ignore_screens) do
                if SDK.FrontEnd.IsScreenOpen(screen) then
                    return
                end
            end

            return fn()
        end)
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Input
function Input._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Input, "Input")
end

return Input
