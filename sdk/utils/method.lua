----
-- Different methods utilities.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Utils.Method
-- @see SDK.Utils
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Method = {}

--- Adds methods from one class to another.
-- @tparam table src Source class to get methods from
-- @tparam table dest Destination class to add methods to
-- @tparam table methods Methods to add
-- @treturn SDK.Utils.Method
function Method.AddToAnotherClass(src, dest, methods)
    for k, v in pairs(methods) do
        -- we also add tables as they can behave as functions in some cases
        if type(src[v]) == "function" or type(src[v]) == "table" then
            k = type(k) == "number" and v or k
            rawset(dest, k, function(_, ...)
                return src[v](src, ...)
            end)
        end
    end
    return Method
end

--- Adds a __tostring method.
-- @tparam table dest Destination class to add method to
-- @tparam table value Value to return
-- @treturn SDK.Utils.Method
function Method.AddToString(dest, value)
    local mt = getmetatable(dest)
    if mt then
        mt.__tostring = function()
            return value
        end
        return
    end

    setmetatable(dest, {
        __tostring = function()
            return value
        end
    })

    return Method
end

--- Removes methods from a class.
-- @tparam table src Source class from where we remove methods
-- @tparam table methods Methods to remove
-- @treturn SDK.Utils.Method
function Method.RemoveFromAnotherClass(src, methods)
    for _, v in pairs(methods) do
        -- we also add tables as they can behave as functions in some cases
        if type(src[v]) == "function" or type(src[v]) == "table" then
            src[v] = nil
        end
    end
    return Method
end

return Method
