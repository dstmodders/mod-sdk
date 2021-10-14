----
-- Handles world save data functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.World.SaveData
-- @see SDK.World
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local SaveData = {}

local SDK
local Chain
local World

local _SAVE_DATA

--- Helpers
-- @section helpers

local function DebugError(...)
    SDK._DebugError("[world]", "[save_data]", ...)
end

local function DebugString(...)
    SDK._DebugString("[world]", "[save_data]", ...)
end

--- General
-- @section general

--- Gets a map persistdata.
-- @treturn table
function SaveData.GetMapPersistData()
    return Chain.Get(_SAVE_DATA, "map", "persistdata")
end

--- Gets a meta.
-- @tparam[opt] string name Meta name
-- @treturn[1] table Meta table, when no name passed
-- @treturn[2] string Meta value, when the name is passed
function SaveData.GetMeta(name)
    local meta = _SAVE_DATA and _SAVE_DATA.meta
    if meta and name ~= nil then
        return meta and meta[name]
    end
    return meta
end

--- Gets a save data path.
--
-- Returns one of the following paths based on the server type:
--
--   - `server_temp/server_save` (master instance)
--   - `client_temp/server_save` (non-master instance)
--
-- @treturn string
function SaveData.GetPath()
    return World.IsMasterSim() and "server_temp/server_save" or "client_temp/server_save"
end

--- Gets a save data.
-- @treturn table
function SaveData.GetSaveData()
    return _SAVE_DATA
end

--- Gets a meta seed.
-- @treturn string
function SaveData.GetSeed()
    return SaveData.GetMeta("seed")
end

--- Gets a meta version.
-- @treturn string
function SaveData.GetVersion()
    return SaveData.GetMeta("saveversion")
end

--- Internal
-- @section internal

--- Loads the save data.
--
-- Returns the data which is stored on the client side.
--
-- @tparam string path
-- @treturn boolean
function SaveData._Load()
    local save_data, success
    local path = SaveData.GetPath()
    DebugString("Path:", path)
    TheSim:GetPersistentString(path, function(is_success, str)
        if is_success then
            DebugString("Loaded successfully")
            success, save_data = RunInSandboxSafe(str)
            if success and save_data and save_data.meta then
                DebugString("Seed:", save_data.meta.seed)
                DebugString("Version:", save_data.meta.saveversion)
                _SAVE_DATA = save_data
                return save_data
            end
            DebugError("Data extraction has failed")
            return false
        else
            DebugError("Load has failed")
            return false
        end
    end)
    return save_data
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam SDK.World parent
-- @treturn SDK.World.SaveData
function SaveData._DoInit(sdk, parent)
    SDK = sdk
    Chain = SDK.Utils.Chain
    World = parent

    SDK.OnLoadWorld(function()
        SaveData._Load()
    end)

    return SaveData
end

return SaveData
