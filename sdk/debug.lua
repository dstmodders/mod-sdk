----
-- Helps with mod debugging.
--
-- As it's a common practice to put different messages throughout your code to see what exactly your
-- function is doing through the console. This enables more transparency over the business logic and
-- simplifies tracking the unexpected behaviour.
--
--    SDK.Debug.Enable()
--    SDK.Debug.String("Hello", "World!") -- prints: [sdk] [your-mod] Hello World!
--
--    SDK.Debug.Disable()
--    SDK.Debug.String("Hello", "World!") -- prints nothing
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Debug
-- @see SDK
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Debug = {}

local SDK

local _START_TIME

local _IS_DEBUG = {}
local _IS_ENABLED = false

--- General
-- @section general

--- Checks if debugging is enabled.
-- @treturn boolean
function Debug.IsEnabled()
    return _IS_ENABLED
end

--- Sets a debugging state.
-- @tparam boolean enable
function Debug.SetIsEnabled(enable)
    _IS_ENABLED = enable
end

--- Enables debugging.
function Debug.Enable()
    _IS_ENABLED = true
end

--- Disables debugging.
function Debug.Disable()
    _IS_ENABLED = false
end

--- Checks if a named debugging is enabled.
-- @tparam string name
-- @treturn boolean
function Debug.IsDebug(name)
    return _IS_DEBUG[name] and true or false
end

--- Adds a named debugging state.
-- @tparam string name
-- @tparam boolean enable
function Debug.SetIsDebug(name, enable)
    enable = enable and true or false
    _IS_DEBUG[name] = enable
end

--- Adds debugging methods to the destination class.
-- @tparam table dest Destination class
function Debug.AddMethods(dest)
    local methods = {
        "Error",
        "Init",
        "ModConfigs",
        "String",
        "StringStart",
        "StringStop",
        "Term",
    }

    for _, method in pairs(methods) do
        dest["Debug" .. method] = function(_, ...)
            if Debug[method] then
                return Debug[method](...)
            end
        end
    end
end

--- Prints
-- @section prints

--- Prints the provided strings.
-- @tparam string ... Strings
function Debug.String(...) -- luacheck: only
    if _IS_ENABLED then
        local task = scheduler:GetCurrentTask()
        local msg = string.format("[sdk] [%s]", SDK.modname)

        if task then
            msg = msg .. " [" .. task.id .. "]"
        end

        for i = 1, arg.n do
            msg = msg .. " " .. tostring(arg[i])
        end

        print(msg)
    end
end

--- Prints the provided strings.
--
-- Unlike the `DebugString` it also starts the timer which later can be stopped using the
-- corresponding `DebugStringStop` method.
--
-- @tparam string ... Strings
function Debug.StringStart(...)
    _START_TIME = os.clock()
    Debug.String(...)
end

--- Prints the provided strings.
--
-- Stops the timer started earlier by the `DebugStringStart` method and prints the provided strings
-- alongside with the time.
--
-- @tparam string ... Strings
function Debug.StringStop(...)
    if _START_TIME then
        local arg = { ... }
        local last = string.gsub(arg[#arg], "%.$", "") .. "."
        arg[#arg] = last
        table.insert(arg, string.format("Time: %0.4f", os.clock() - _START_TIME))
        Debug.String(unpack(arg))
        _START_TIME = nil
    else
        Debug.String(...)
    end
end

--- Prints an initialized method name.
-- @tparam string name Method name
function Debug.Init(name)
    Debug.String("[life_cycle]", "Initialized", name)
end

--- Prints a terminated method name.
-- @tparam string name Method name
function Debug.Term(name)
    Debug.String("[life_cycle]", "Terminated", name)
end

--- Prints the provided error strings.
--
-- Acts just like the `DebugString` but also prepends the "[error]" string.
--
-- @tparam string ... Strings
function Debug.Error(...)
    Debug.String("[error]", ...)
end

--- Prints all mod configurations.
--
-- Should be used to debug mod configurations.
function Debug.ModConfigs()
    local config = KnownModIndex:GetModConfigurationOptions_Internal(SDK.modname, false)
    if config and type(config) == "table" then
        for _, v in pairs(config) do
            if v.name == "" then
                Debug.String("[config]", "[section]", v.label)
            else
                Debug.String(
                    "[config]",
                    v.label .. ":",
                    v.saved == nil and v.default or v.saved
                )
            end
        end
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Debug
function Debug._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Debug, "Debug")
end

return Debug
