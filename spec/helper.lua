--
-- Packages
--

_G.MOD_SDK_TEST = true

require "spec/vector3"

local preloads = {
    ["yoursubdirectory/sdk/sdk/utils"] = "./sdk/utils",
    class = "spec/class",
}

package.path = "./sdk/?.lua;" .. package.path
for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

--
-- General
--

-- http://lua-users.org/wiki/CopyTable
function shallowcopy(orig, dest)
    local copy
    if type(orig) == 'table' then
        copy = dest or {}
        for k, v in pairs(orig) do
            copy[k] = v
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Empty()
end

function ReturnValueFn(value)
    return function()
        return value
    end
end

function ReturnValuesFn(...)
    local args = { ... }
    return function()
        return unpack(args)
    end
end

function TableCount(t)
    local result = 0
    for _, _ in pairs(t) do
        result = result + 1
    end
    return result
end

function TableHasValue(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

--
-- Asserts
--

function AssertChainNil(fn, src, ...)
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
            AssertChainNil(fn, src, unpack(args))
        end
    end
end

function AssertHasFunction(module, fn_name)
    local assert = require("busted").assert
    assert.is_not_nil(module[fn_name], string.format("%s() is missing", tostring(fn_name)))
end

function AssertHasNoFunction(module, fn_name)
    local assert = require("busted").assert
    assert.is_nil(module[fn_name], string.format("%s() exists", fn_name))
end

function AssertModuleGetter(module, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    AssertHasFunction(module, fn_name)
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

function AssertModuleSetter(module, field, fn_name, is_return_self, test_data)
    test_data = test_data ~= nil and test_data or "test"

    AssertHasFunction(module, fn_name)
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

function AssertReturnSelf(module, fn_name, ...)
    local assert = require("busted").assert
    assert.is_equal(
        module,
        module[fn_name](unpack({ ... })),
        string.format("Module function %s() doesn't return self", fn_name)
    )
end
