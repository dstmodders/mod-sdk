--
-- Packages
--

local preloads = {
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
