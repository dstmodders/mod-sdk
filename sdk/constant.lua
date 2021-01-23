----
-- Handles constant functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Constant
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Constant = {}

local SDK

--- General
-- @section general

--- Add string names to the values table.
-- @tparam table t Values table
-- @tparam[opt] boolean is_sorted Should be sorted alphabetically?
-- @treturn table
function Constant.AddStringNamesToTable(t, is_sorted)
    local result = {}

    for _, v in pairs(t) do
        table.insert(result, {
            name = Constant.GetStringName(v),
            value = v,
        })
    end

    if is_sorted then
        table.sort(result, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
    end

    return result
end

--- Gets a skin index.
-- @see GetStringSkinName
-- @see GetStringName
-- @tparam string prefab
-- @tparam number skin
-- @treturn string
function Constant.GetSkinIndex(prefab, skin)
    return PREFAB_SKINS_IDS[prefab] and PREFAB_SKINS_IDS[prefab][skin]
end

--- Gets a string skin name.
-- @see GetSkinIndex
-- @see GetStringName
-- @tparam number skin
-- @treturn string
function Constant.GetStringSkinName(skin)
    return STRINGS.SKIN_NAMES[skin]
end

--- Gets a string name.
-- @see GetSkinIndex
-- @see GetStringSkinName
-- @tparam string name
-- @treturn string
function Constant.GetStringName(name)
    return STRINGS.NAMES[string.upper(name)]
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Constant
function Constant._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Constant, "Constant")
end

return Constant
