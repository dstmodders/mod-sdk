----
-- Different modmain functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.ModMain
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local ModMain = {}

local SDK

local _GetModInfo

--- General
-- @section general

--- Hide a modinfo changelog.
--
-- Overrides the global `KnownModIndex.GetModInfo` to hide the changelog if it's included in the
-- description.
--
-- @tparam[opt] boolean is_enabled
-- @treturn boolean
function ModMain.HideChangelog(is_enabled)
    is_enabled = is_enabled ~= nil and true or false

    if is_enabled and not _GetModInfo then
        _GetModInfo = KnownModIndex.GetModInfo
        KnownModIndex.GetModInfo = function(self, modname)
            local mod = SDK.Utils.Chain.Get(self, "savedata", "known_mods", modname)
            if modname == ModMain.modname and mod then
                local TrimString = TrimString
                local modinfo = mod.modinfo
                if modinfo and type(modinfo.description) == "string" then
                    local changelog = modinfo.description:find("v" .. modinfo.version, 0, true)
                    if type(changelog) == "number" then
                        modinfo.description = TrimString(modinfo.description:sub(1, changelog - 1))
                    end
                end
            end
            return _GetModInfo(self, modname)
        end
        return true
    end

    KnownModIndex.GetModInfo = _GetModInfo
    _GetModInfo = nil
    return false
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.ModMain
function ModMain._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, ModMain, "ModMain")
end

return ModMain
