----
-- Different dump functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Dump
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Dump = {}

local SDK

--- Helpers
-- @section helpers

local function PrintDumpValues(table, title, name, prepend)
    prepend = prepend ~= nil and prepend .. " " or ""

    print(prepend .. (name
        and string.format('Dumping "%s" %s...', name, title)
        or string.format('Dumping %s...', title)))

    if #table > 0 then
        for _, v in pairs(table) do
            print(prepend .. type(v) == "string" and v)
        end
    else
        print(prepend .. "No " .. title)
    end
end

local function SortByTypeAndValue(a, b)
    local a_type, b_type = type(a), type(b)
    return a_type < b_type or (
        a_type ~= "table"
            and b_type ~= "table"
            and a_type == b_type
            and a < b
    )
end

--- General
-- @section general

--- Gets a table on all entity components.
-- @usage dumptable(GetComponents(ThePlayer))
-- @see GetEventListeners
-- @see GetFields
-- @see GetFunctions
-- @see GetReplicas
-- @tparam EntityScript entity
-- @tparam[opt] boolean is_sorted
-- @treturn table
function Dump.GetComponents(entity, is_sorted)
    local result = {}
    if type(entity) == "table" or type(entity) == "userdata" then
        if type(entity.components) == "table" then
            for k, _ in pairs(entity.components) do
                table.insert(result, k)
            end
        end
    end
    return is_sorted and SDK.Utils.Table.SortAlphabetically(result) or result
end

--- Gets a table on all entity event listeners.
-- @usage dumptable(GetEventListeners(ThePlayer))
-- @see GetComponents
-- @see GetFields
-- @see GetFunctions
-- @see GetReplicas
-- @tparam EntityScript entity
-- @tparam[opt] boolean is_sorted
-- @treturn table
function Dump.GetEventListeners(entity, is_sorted)
    local result = {}
    if type(entity) == "table" or type(entity) == "userdata" then
        if type(entity.event_listeners) == "table" then
            for k, _ in pairs(entity.event_listeners) do
                table.insert(result, k)
            end
        end
    end
    return is_sorted and SDK.Utils.Table.SortAlphabetically(result) or result
end

--- Gets a table on all entity fields.
-- @usage dumptable(GetFields(ThePlayer))
-- @see GetComponents
-- @see GetEventListeners
-- @see GetFunctions
-- @see GetReplicas
-- @tparam EntityScript entity
-- @tparam[opt] boolean is_sorted
-- @treturn table
function Dump.GetFields(entity, is_sorted)
    local result = {}
    if type(entity) == "table" then
        for k, v in pairs(entity) do
            if entity and type(v) ~= "function" then
                table.insert(result, k)
            end
        end
    end
    return is_sorted and SDK.Utils.Table.SortAlphabetically(result) or result
end

--- Gets a table on all entity functions.
-- @usage dumptable(GetFunctions(ThePlayer))
-- @see GetComponents
-- @see GetEventListeners
-- @see GetFields
-- @see GetReplicas
-- @tparam EntityScript entity
-- @tparam[opt] boolean is_sorted
-- @treturn table
function Dump.GetFunctions(entity, is_sorted)
    local result = {}
    local metatable = getmetatable(entity)

    if metatable and type(metatable["__index"]) == "table" then
        for k, _ in pairs(metatable["__index"]) do
            table.insert(result, k)
        end
    end

    if type(entity) == "table" and #result == 0 then
        for k, v in pairs(entity) do
            if type(v) == "function" then
                table.insert(result, k)
            end
        end
    end

    return is_sorted and SDK.Utils.Table.SortAlphabetically(result) or result
end

--- Gets a table on all entity replicas.
-- @usage dumptable(GetReplicas(ThePlayer))
-- @see GetComponents
-- @see GetEventListeners
-- @see GetFields
-- @see GetFunctions
-- @tparam EntityScript entity
-- @tparam[opt] boolean is_sorted
-- @treturn table
function Dump.GetReplicas(entity, is_sorted)
    local result = {}
    if entity.replica and type(entity.replica._) == "table" then
        for k, _ in pairs(entity.replica._) do
            table.insert(result, k)
        end
    end
    return is_sorted and SDK.Utils.Table.SortAlphabetically(result) or result
end

--- Dump
-- @section dump

--- Dumps all entity components.
-- @usage DumpComponents(ThePlayer, "ThePlayer")
-- @see EventListeners
-- @see Fields
-- @see Functions
-- @see Replicas
-- @tparam EntityScript entity
-- @tparam[opt] string name The name of the dumped entity
-- @tparam[opt] string prepend The prepend string on each line
-- @treturn table
function Dump.Components(entity, name, prepend)
    PrintDumpValues(Dump.GetComponents(entity, true), "Components", name, prepend)
end

--- Dumps all entity event listeners.
-- @usage DumpEventListeners(ThePlayer, "ThePlayer")
-- @see Components
-- @see Fields
-- @see Functions
-- @see Replicas
-- @tparam EntityScript entity
-- @tparam[opt] string name The name of the dumped entity
-- @tparam[opt] string prepend The prepend string on each line
-- @treturn table
function Dump.EventListeners(entity, name, prepend)
    PrintDumpValues(Dump.GetEventListeners(entity, true), "Event Listeners", name, prepend)
end

--- Dumps all entity fields.
-- @usage DumpFields(ThePlayer, "ThePlayer")
-- @see Components
-- @see EventListeners
-- @see Functions
-- @see Replicas
-- @tparam EntityScript entity
-- @tparam[opt] string name The name of the dumped entity
-- @tparam[opt] string prepend The prepend string on each line
-- @treturn table
function Dump.Fields(entity, name, prepend)
    PrintDumpValues(Dump.GetFields(entity, true), "Fields", name, prepend)
end

--- Dumps all entity functions.
-- @usage DumpFunctions(ThePlayer, "ThePlayer")
-- @see Components
-- @see EventListeners
-- @see Fields
-- @see Replicas
-- @tparam EntityScript entity
-- @tparam[opt] string name The name of the dumped entity
-- @tparam[opt] string prepend The prepend string on each line
-- @treturn table
function Dump.Functions(entity, name, prepend)
    PrintDumpValues(Dump.GetFunctions(entity, true), "Functions", name, prepend)
end

--- Dumps all entity replicas.
-- @usage DumpReplicas(ThePlayer, "ThePlayer")
-- @see Components
-- @see EventListeners
-- @see Fields
-- @see Functions
-- @tparam EntityScript entity
-- @tparam[opt] string name The name of the dumped entity
-- @tparam[opt] string prepend The prepend string on each line
-- @treturn table
function Dump.Replicas(entity, name, prepend)
    PrintDumpValues(Dump.GetReplicas(entity, true), "Replicas", name, prepend)
end

--- Dumps a table.
--
-- The same as the original `dumptable` from the `debugtools` module. The only difference is in the
-- local `SortByTypeAndValue` which avoids comparing tables to avoid non-sandbox crashes and entity
-- type is checked.
--
-- @tparam table obj
-- @tparam number indent
-- @tparam number recurse_levels
-- @tparam table visit_table
-- @tparam boolean is_terse
function Dump.Table(obj, indent, recurse_levels, visit_table, is_terse)
    local is_top_level = visit_table == nil
    if visit_table == nil then
        visit_table = {}
    end

    indent = indent or 1
    local i_recurse_levels = recurse_levels or 5
    if obj then
        local dent = string.rep("\t", indent)

        if type(obj) == type("") then
            print(obj)
            return
        end

        if type(obj) == "table" then
            if visit_table[obj] ~= nil then
                print(dent .. "(Already visited", obj, "-- skipping.)")
                return
            else
                visit_table[obj] = true
            end
        end

        local keys = {}

        for k, _ in pairs(obj) do
            table.insert(keys, k)
        end

        table.sort(keys, SortByTypeAndValue)

        if not is_terse and is_top_level and #keys == 0 then
            print(dent .. "(empty)")
        end

        for _, k in ipairs(keys) do
            local v = obj[k]
            if type(v) == "table" and i_recurse_levels > 0 then
                if type(v.entity) == "table" and v.entity:GetGUID() then
                    print(dent .. "K: ", k, " V: ", v, "(Entity -- skipping.)")
                else
                    print(dent .. "K: ", k, " V: ", v)
                    Dump.Table(v, indent + 1, i_recurse_levels - 1, visit_table)
                end
            else
                print(dent .. "K: ", k, " V: ", v)
            end
        end
    elseif not is_terse then
        print("nil")
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Dump
function Dump._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Dump, "Dump")
end

return Dump
