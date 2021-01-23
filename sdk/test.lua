----
-- Handles test functionality.
--
-- Shouldn't be loaded in production and most only be used for testing. It requires Busted unit
-- testing framework to be loaded and when it's found it will automatically add all corresponding
-- functions globally when SDK is loaded.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Test
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Test = {}

local SDK

local _DEBUG_SPY = {}

--- General
-- @section general

--- Dumps a table.
-- @see SDK.Dump.Table
-- @tparam table obj
-- @tparam number indent
-- @tparam number recurse_levels
-- @tparam table visit_table
-- @tparam boolean is_terse
function Test.dumptable(obj, indent, recurse_levels, visit_table, is_terse)
    SDK.Dump.Table(obj, indent, recurse_levels, visit_table, is_terse)
end

--- Copies a table in a shallow mode.
--
-- Copies the top level value and its direct children.
--
-- [http://lua-users.org/wiki/CopyTable](http://lua-users.org/wiki/CopyTable)
--
-- @tparam table src Source table
-- @tparam[opt] table dest Destination table
-- @treturn table
function Test.shallowcopy(src, dest)
    local copy
    if type(src) == 'table' then
        copy = dest or {}
        for k, v in pairs(src) do
            copy[k] = v
        end
    else -- number, string, boolean, etc
        copy = src
    end
    return copy
end

--- Creates a userdata from table.
-- @tparam table t
-- @treturn table
function Test.userdata(t)
    local proxy = newproxy(true)
    getmetatable(proxy).__index = function(_, key)
        return t[key]
    end
    return proxy
end

--- Asserts
-- @section asserts

--- Asserts a function with chained nil fields.
-- @tparam function fn Function
-- @tparam table src Source itself
-- @tparam string ... Chained fields that will be "nilled"
function Test.AssertChainNil(fn, src, ...)
    if src and (type(src) == "table" or type(src) == "userdata") then
        local args = { ... }
        local start = src
        local previous, key

        for i = 1, #args do
            if start[args[i]] then
                previous = start
                key = args[i]
                start = start[key]
            end
        end

        if previous and src then
            previous[key] = nil
            args[#args] = nil
            fn()
            Test.AssertChainNil(fn, src, unpack(args))
        end
    end
end

--- Asserts a class having a getter.
-- @tparam table class Class to assert
-- @tparam string field Field name
-- @tparam string fn_name Function name
-- @tparam[opt] string test_data Test data (by default: "test")
function Test.AssertClassGetter(class, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    Test.AssertHasFunction(class, fn_name)
    local fn = class[fn_name]
    local msg = string.format(
        "Class getter %s() doesn't return value: %s",
        tostring(fn_name),
        tostring(field)
    )

    local assert = require("busted").assert
    local value = class[field]
    assert.is_equal(class[field], fn(class), msg)
    class[field] = test_data
    assert.is_equal(test_data, fn(class), msg)
    class[field] = value
end

--- Asserts a class having a setter.
-- @tparam table class Class to assert
-- @tparam string field Field name
-- @tparam string fn_name Function name
-- @tparam[opt] boolean is_return_self Assert setter returning self
-- @tparam[opt] string test_data Test data (by default: "test")
function Test.AssertClassSetter(class, field, fn_name, is_return_self, test_data)
    test_data = test_data ~= nil and test_data or "test"

    Test.AssertHasFunction(class, fn_name)
    local fn = class[fn_name]
    local assert = require("busted").assert
    local value = class[field]

    fn(class, test_data)
    assert.is_equal(test_data, class[field], string.format(
        "Class setter %s() doesn't set value: %s",
        tostring(fn_name),
        tostring(field)
    ))

    if is_return_self then
        assert.is_equal(class, fn(class, test_data), string.format(
            "Class setter %s() doesn't return self",
            tostring(fn_name)
        ))
    end

    class[field] = value
end

--- Asserts if a debug spy was called.
--
-- Just a convenience wrapper for:
--
--    SDK.Test.DebugSpyAssert(name).was_called(calls)
--    SDK.Test.DebugSpyAssert(name).was_called_with(match.is_not_nil(), unpack(args))
--
-- @usage SDK.Test.AssertDebugSpyWasCalled("DebugString", 1, "Loaded")
--
-- @usage SDK.Test.AssertDebugSpyWasCalled("DebugError", 1, { "Error:", "not loaded" })
--
-- @tparam string name Spy name
-- @tparam number calls Number of calls
-- @tparam string|table args A single argument as a string or multiple as a table
function Test.AssertDebugSpyWasCalled(name, calls, args)
    local match = require "luassert.match"
    calls = calls ~= nil and calls or 0
    args = args ~= nil and args or {}
    args = type(args) == "string" and { args } or args
    Test.DebugSpyAssert(name).was_called(calls)
    if calls > 0 then
        Test.DebugSpyAssert(name).was_called_with(match.is_not_nil(), unpack(args))
    end
end

--- Asserts a module having a function.
-- @tparam table module Module to assert
-- @tparam string fn_name Function name
function Test.AssertHasFunction(module, fn_name)
    local assert = require("busted").assert
    assert.is_not_nil(module[fn_name], string.format("%s() is missing", tostring(fn_name)))
end

--- Asserts a module not having a function.
-- @tparam table module Module to assert
-- @tparam string fn_name Function name
function Test.AssertHasNoFunction(module, fn_name)
    local assert = require("busted").assert
    assert.is_nil(module[fn_name], string.format("%s() exists", fn_name))
end

--- Asserts a module having a getter.
-- @tparam table module Module to assert
-- @tparam string field Field name
-- @tparam string fn_name Function name
-- @tparam[opt] string test_data Test data (by default: "test")
function Test.AssertModuleGetter(module, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    Test.AssertHasFunction(module, fn_name)
    local fn = module[fn_name]
    local msg = string.format(
        "Module getter %s() doesn't return value: %s",
        tostring(fn_name),
        tostring(field)
    )

    local assert = require("busted").assert
    local value = module[field]
    assert.is_equal(module[field], fn(), msg)
    module[field] = test_data
    assert.is_equal(test_data, fn(), msg)
    module[field] = value
end

--- Asserts a module having a setter.
-- @tparam table module Module to assert
-- @tparam string field Field name
-- @tparam string fn_name Function name
-- @tparam[opt] boolean is_return_self Assert setter returning self
-- @tparam[opt] string test_data Test data (by default: "test")
function Test.AssertModuleSetter(module, field, fn_name, is_return_self, test_data)
    test_data = test_data ~= nil and test_data or "test"

    Test.AssertHasFunction(module, fn_name)
    local fn = module[fn_name]
    local assert = require("busted").assert
    local value = module[field]

    fn(test_data)
    assert.is_equal(test_data, module[field], string.format(
        "Module setter %s() doesn't set value: %s",
        tostring(fn_name),
        tostring(field)
    ))

    if is_return_self then
        assert.is_equal(module, fn(test_data), string.format(
            "Module setter %s() doesn't return self",
            tostring(fn_name)
        ))
    end

    module[field] = value
end

--- Asserts a module returning self.
-- @tparam table module Module to assert
-- @tparam string fn_name Function name
-- @tparam any ... Function arguments
function Test.AssertReturnSelf(module, fn_name, ...)
    local assert = require("busted").assert
    assert.is_equal(
        module,
        module[fn_name](unpack({ ... })),
        string.format("Module function %s() doesn't return self", fn_name)
    )
end

--- Debug
-- @section debug

--- Gets a debug spy.
-- @usage assert.spy(SDK.Test.DebugSpy("DebugString")).was_not_called()
-- @tparam string name Spy name
-- @treturn table
function Test.DebugSpy(name)
    for k, spy in pairs(_DEBUG_SPY) do
        if k == name then
            return spy
        end
    end
end

--- Gets a debug spy assert.
--
-- Just a convenience wrapper for:
--
--    assert.spy(SDK.Test.DebugSpy(name))
--
-- @usage SDK.Test.DebugSpyAssert("DebugString").was_not_called()
-- @tparam string name Spy name
-- @treturn table
function Test.DebugSpyAssert(name)
    local assert = require "luassert.assert"
    return assert.spy(Test.DebugSpy(name))
end

--- Clears a single debug spy or all of them.
-- @tparam[opt] string name Spy name
function Test.DebugSpyClear(name)
    if name ~= nil then
        for _name, method in pairs(_DEBUG_SPY) do
            if _name == name then
                method:clear()
                return
            end
        end
    end

    for _, method in pairs(_DEBUG_SPY) do
        method:clear()
    end
end

--- Initializes debug spies.
function Test.DebugSpyInit()
    local spy = require "luassert.spy"
    local functions = {
        "Error",
        "Init",
        "ModConfigs",
        "String",
        "StringStart",
        "StringStop",
        "Term",
    }

    Test.DebugSpyTerm()

    for _, fn in pairs(functions) do
        if SDK.Debug[fn] and not _DEBUG_SPY[fn] then
            _DEBUG_SPY[fn] = spy.new(Test.Empty)
        end
    end

    SDK.Debug.AddMethods = function(self)
        for _, fn in pairs(functions) do
            if SDK.Debug[fn] and _DEBUG_SPY[fn] and not self["Debug" .. fn] then
                self["Debug" .. fn] = _DEBUG_SPY[fn]
                _DEBUG_SPY["Debug" .. fn] = self["Debug" .. fn]
            end
        end
    end
end

--- Terminates debug spies.
function Test.DebugSpyTerm()
    for name, _ in pairs(_DEBUG_SPY) do
        _DEBUG_SPY[name] = nil
    end
end

--- Returns
-- @section returns

--- Returns nothing.
-- @treturn nil
function Test.Empty()
end

--- Returns a function which returns a value.
-- @tparam any value Value to return
-- @treturn function
function Test.ReturnValueFn(value)
    return function()
        return value
    end
end

--- Returns a function which returns values.
-- @tparam any ... Values to return
-- @treturn function
function Test.ReturnValuesFn(...)
    local args = { ... }
    return function()
        return unpack(args)
    end
end

--- Table
-- @section table

--- Counts the number of elements inside a table.
-- @see SDK.Utils.Table.Count
-- @tparam table t Table
-- @treturn number
function Test.TableCount(t)
    return SDK.Utils.Table.Count(t)
end

--- Checks if a table has the provided value.
-- @see SDK.Utils.Table.HasValue
-- @tparam table t Table
-- @tparam string value
-- @treturn boolean
function Test.TableHasValue(t, value)
    return SDK.Utils.Table.HasValue(t, value)
end

--- Test
-- @section test

--- Tests if returns false.
-- @tparam function fn
function Test.TestReturnFalse(fn)
    local assert = require("busted").assert
    local it = require "busted".it
    it("should return false", function()
        assert.is_false(fn())
    end)
end

--- Tests if returns true.
-- @tparam function fn
function Test.TestReturnTrue(fn)
    local assert = require("busted").assert
    local it = require "busted".it
    it("should return true", function()
        assert.is_true(fn())
    end)
end

--- Tests if returns nil.
-- @tparam function fn
function Test.TestReturnNil(fn)
    local assert = require("busted").assert
    local it = require "busted".it
    it("should return nil", function()
        assert.is_nil(fn())
    end)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Test
function Test._DoInit(sdk)
    SDK = sdk

    local module = SDK._DoInitModule(SDK, Test, "Test")
    local mt = getmetatable(module)
    local __index = mt.__index
    mt.__index = function(...)
        if not package.loaded.busted then
            SDK._Error(tostring(module) .. ":", "Busted testing framework is not loaded")
            return function()
                return nil
            end
        end
        return __index(...)
    end

    if package.loaded.busted then
        _G.AssertChainNil = Test.AssertChainNil
        _G.AssertClassGetter = Test.AssertClassGetter
        _G.AssertClassSetter = Test.AssertClassSetter
        _G.AssertDebugSpyWasCalled = Test.AssertDebugSpyWasCalled
        _G.AssertHasFunction = Test.AssertHasFunction
        _G.AssertHasNoFunction = Test.AssertHasNoFunction
        _G.AssertModuleGetter = Test.AssertModuleGetter
        _G.AssertModuleSetter = Test.AssertModuleSetter
        _G.AssertReturnSelf = Test.AssertReturnSelf
        _G.DebugSpy = Test.DebugSpy
        _G.DebugSpyAssert = Test.DebugSpyAssert
        _G.DebugSpyClear = Test.DebugSpyClear
        _G.DebugSpyInit = Test.DebugSpyInit
        _G.DebugSpyTerm = Test.DebugSpyTerm
        _G.dumptable = Test.dumptable
        _G.Empty = Test.Empty
        _G.ReturnValueFn = Test.ReturnValueFn
        _G.ReturnValuesFn = Test.ReturnValuesFn
        _G.shallowcopy = Test.shallowcopy
        _G.TableCount = Test.TableCount
        _G.TableHasValue = Test.TableHasValue
        _G.TestReturnFalse = Test.TestReturnFalse
        _G.TestReturnNil = Test.TestReturnNil
        _G.TestReturnTrue = Test.TestReturnTrue
        _G.userdata = Test.userdata
    end

    return module
end

return Test
