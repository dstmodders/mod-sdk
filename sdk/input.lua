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
    if options == nil then
        options = {}
    end

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

    local ignore = options.ignore_has_input_focus
    if ignore ~= nil and (type(ignore) ~= "boolean" and type(ignore) ~= "table") then
        DebugErrorOptions(fn_name, key, "ignore_has_input_focus must be a boolean or a table")
        return false
    end

    return options
end

local function HandleKey(options, fn)
    if type(options) == "table" and SDK.FrontEnd.HasInputFocus() then
        if options.ignore_has_input_focus == nil or options.ignore_has_input_focus == false then
            return
        elseif
            type(options.ignore_has_input_focus) == "table"
            and not SDK.Utils.Table.HasValue(
                options.ignore_has_input_focus,
                SDK.FrontEnd.GetActiveScreenName()
            )
        then
            return
        end
    end

    if type(options) == "table" and type(options.ignore_screens) == "table" then
        for _, screen in pairs(options.ignore_screens) do
            if SDK.FrontEnd.IsScreenOpen(screen) then
                return
            end
        end
    end

    return fn()
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
-- @usage SDK.Input.AddConfigKeyHandler("key_test", function()
--     print("Hello World!")
-- end, {
--     ignore_has_input_focus = { "OptionsScreen" }, -- ignores SDK.FrontEnd.HasInputFocus() in OptionsScreen
--     -- ignore_has_input_focus = true, -- ignores SDK.FrontEnd.HasInputFocus() everywhere
--     ignore_screens = { "ConsoleScreen", "MapScreen" },
-- })
-- @see SDK.FrontEnd.HasInputFocus
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
                return HandleKey(options, function()
                    fn(down)
                end)
            end
        end)
    end
end

--- Adds a config key down handler.
-- @usage SDK.Input.AddConfigKeyDownHandler("key_test", function()
--     print("Hello World!")
-- end, {
--     ignore_has_input_focus = { "OptionsScreen" }, -- ignores SDK.FrontEnd.HasInputFocus() in OptionsScreen
--     -- ignore_has_input_focus = true, -- ignores SDK.FrontEnd.HasInputFocus() everywhere
--     ignore_screens = { "ConsoleScreen", "MapScreen" },
-- })
-- @see SDK.FrontEnd.HasInputFocus
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] table options
function Input.AddConfigKeyDownHandler(config, fn, options)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        local fn_name = "AddConfigKeyDownHandler"
        options = PrepareOptions(fn_name, config, options)
        TheInput:AddKeyDownHandler(config_key, function()
            return HandleKey(options, fn)
        end)
    end
end

--- Adds a config key up handler.
-- @usage SDK.Input.AddConfigKeyUpHandler("key_test", function()
--     print("Hello World!")
-- end, {
--     ignore_has_input_focus = { "OptionsScreen" }, -- ignores SDK.FrontEnd.HasInputFocus() in OptionsScreen
--     -- ignore_has_input_focus = true, -- ignores SDK.FrontEnd.HasInputFocus() everywhere
--     ignore_screens = { "ConsoleScreen", "MapScreen" },
-- })
-- @see SDK.FrontEnd.HasInputFocus
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] table options
function Input.AddConfigKeyUpHandler(config, fn, options)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        local fn_name = "AddConfigKeyUpHandler"
        options = PrepareOptions(fn_name, config, options)
        TheInput:AddKeyUpHandler(config_key, function()
            return HandleKey(options, fn)
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

if _G.MOD_SDK_TEST then
    Input._HandleKey = HandleKey
    Input._PrepareOptions = PrepareOptions
end

return Input
