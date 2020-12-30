----
-- Different method functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Method
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Method = {}

local SDK

local _CLASS

--- Helpers
-- @section helpers

local function AddMethodToAnotherClass(class, dest, src_name, dest_name)
    -- tables may act as functions
    if type(class[src_name]) == "function" or type(class[src_name]) == "table" then
        rawset(dest, dest_name, function(_, ...)
            return class[src_name](class, ...)
        end)
    end
end

local function RemoveMethod(class, name)
    -- tables may act as functions
    if type(class[name]) == "function" or type(class[name]) == "table" then
        class[name] = nil
        local mt = getmetatable(class)
        if mt[name] then
            mt[name] = nil
        end
    end
end

--- General
-- @section general

--- Gets a class.
-- @treturn table
function Method.GetClass()
    return _CLASS
end

--- Sets a class.
-- @tparam table class
-- @treturn SDK.Method
function Method.SetClass(class)
    _CLASS = class
    return Method
end

--- Add
-- @section add

--- Adds a getter.
-- @tparam string field_name Field name
-- @tparam string getter_name Getter name
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddGetter(field_name, getter_name, class)
    class = class ~= nil and class or _CLASS

    class[getter_name] = function()
        return class[field_name]
    end

    return Method
end

--- Adds getters.
-- @tparam table getters Table, keys are fields and values are names
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddGetters(getters, class)
    class = class ~= nil and class or _CLASS

    for k, v in pairs(getters) do
        Method.AddGetter(k, v, class)
    end

    return Method
end

--- Adds a setter.
-- @tparam string field_name Field name
-- @tparam string setter_name Setter name
-- @tparam[opt] boolean is_return_self Should a setter return self?
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddSetter(field_name, setter_name, is_return_self, class)
    class = class ~= nil and class or _CLASS

    class[setter_name] = function(_, value)
        class[field_name] = value
        if is_return_self then
            return class
        end
    end

    return Method
end

--- Adds setters.
-- @tparam table setters Table, keys are fields and values are names
-- @tparam[opt] boolean is_return_self Should setters return self?
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddSetters(setters, is_return_self, class)
    class = class ~= nil and class or _CLASS

    for k, v in pairs(setters) do
        Method.AddSetter(k, v, is_return_self, class)
    end

    return Method
end

--- Adds a method (or methods) to another class.
-- @tparam table dest Destination class to add methods to
-- @tparam string|table methods Method (string) or methods (table)
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddToAnotherClass(dest, methods, class)
    class = class ~= nil and class or _CLASS

    if type(methods) == "string" then
        AddMethodToAnotherClass(class, dest, methods, methods)
    elseif type(methods) == "table" then
        for k, v in pairs(methods) do
            AddMethodToAnotherClass(class, dest, v, type(k) == "number" and v or k)
        end
    end

    return Method
end

--- Adds a __tostring method.
-- @tparam table value Value to return
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.AddToString(value, class)
    class = class ~= nil and class or _CLASS

    local mt = getmetatable(class)
    if mt then
        mt.__tostring = function()
            return value
        end
        return Method
    end

    setmetatable(class, {
        __tostring = function()
            return value
        end,
    })

    return Method
end

--- Remove
-- @section remove

--- Removes methods from a class.
-- @tparam string|table methods Method (string) or methods (table)
-- @tparam[opt] table class
-- @treturn SDK.Method
function Method.Remove(methods, class)
    class = class ~= nil and class or _CLASS

    if type(methods) == "string" then
        RemoveMethod(class, methods)
    elseif type(methods) == "table" then
        for _, v in pairs(methods) do
            RemoveMethod(class, v)
        end
    end

    return Method
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Method
function Method._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Method, "Method")
end

if _G.MOD_SDK_TEST then
    Method._AddMethodToAnotherClass = AddMethodToAnotherClass
    Method._RemoveMethod = RemoveMethod
end

return Method
