----
-- Handles storing any data for later access.
--
-- **How it works?**
--
-- First of all, load and set the mode you want to work in (by default, `DEFAULT` mode is used).
-- Then you can use either `Get` or `Set` to either retrieve or store your data respectively. Once
-- the data changes, `is_dirty` field becomes `true` and the data can be either saved or reset to
-- its original state. After saving or resetting `is_dirty` changes back to `false`.
--
-- The data itself is stored as `JSON` using `SavePersistentString`.
--
-- **Modes**
--
-- - **DEFAULT** (default): data is stored in a non-server specific way, meaning that it can be
--   accessed outside of gameplay and/or no matter in which server you are. The data doesn't become
--   stale and is stored permanently until it's cleared manually.
--
-- - **SERVER**: data is stored in a server specific way, meaning that it can only be accessed
--   during gameplay and only on a certain server. When the data has not been accessed or stored for
--   a certain amount of time (by default, 30 days) it's removed during the next load.
--
--    -- optional, the data is loaded automatically when SDK is loaded
--    SDK.PersistentData.Load()
--
--    -- general data (can be accessed in every server or outside of gameplay)
--    SDK.PersistentData.SetMode(SDK.PersistentData.DEFAULT)
--    SDK.PersistentData.Set("foo", "bar")
--    SDK.PersistentData.Get("foo") -- returns: "bar"
--
--    -- server data (can be accessed only on a certain server during gameplay)
--    SDK.PersistentData.SetMode(SDK.PersistentData.SERVER)
--    SDK.PersistentData.Set("foo", "bar")
--    SDK.PersistentData.Get("foo") -- returns: "bar"
--
--    -- same, but in chained
--    print(SDK.PersistentData
--        .Load()
--        .SetMode(SDK.PersistentData.DEFAULT)
--        .Set("foo", "bar")
--        .Get("foo")) -- prints: "bar"
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.PersistentData
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local _DEFAULT_PERSIST_DATA = { general = {}, servers = {} }

local PersistentData = {
    -- general
    data = _DEFAULT_PERSIST_DATA,
    data_original = _DEFAULT_PERSIST_DATA,
    is_dirty = true,
    is_encoded = ENCODE_SAVES,
    mode = 0,
    name = "PersistentData",
    save_name = nil,
    server_expire_time = USER_HISTORY_EXPIRY_TIME,
    server_id = nil,

    -- constants
    DEFAULT = 0,
    SERVER = 1,
}

local SDK

--- Helpers
-- @section helpers

local function DebugError(...)
    SDK._DebugError("[persistent_data]", ...)
end

local function DebugString(...)
    SDK._DebugString("[persistent_data]", ...)
end

local function RefreshLastSeen(server)
    if server and server.lastseen then
        server.lastseen = os.time()
    end
end

--- General
-- @section general

--- Gets a data.
-- @treturn table
function PersistentData.GetData()
    return PersistentData.data
end

--- Gets an original data.
-- @treturn table
function PersistentData.GetDataOriginal()
    return PersistentData.data_original
end

--- Gets the current mode.
-- @treturn boolean
function PersistentData.GetMode()
    return PersistentData.mode
end

--- Gets a module name.
-- @treturn string
function PersistentData.GetName()
    return PersistentData.name
end

--- Gets a save name.
-- @treturn string
function PersistentData.GetSaveName()
    return PersistentData.save_name
        or (BRANCH ~= "dev" and SDK.env.modname or (SDK.env.modname .. "_" .. BRANCH))
end

--- Gets a server expire time.
-- @treturn number
function PersistentData.GetServerExpireTime()
    return PersistentData.server_expire_time
end

--- Checks if in a dirty state.
-- @treturn boolean
function PersistentData.IsDirty()
    return PersistentData.is_dirty
end

--- Checks if in encoded state.
-- @treturn boolean
function PersistentData.IsEncoded()
    return PersistentData.is_encoded
end

--- Resets to the original state.
-- @treturn SDK.PersistentData
function PersistentData.Reset()
    PersistentData.data = PersistentData.data_original
    PersistentData.is_dirty = true
    return PersistentData
end

--- Sets dirty state.
-- @tparam boolean is_dirty
-- @treturn SDK.PersistentData
function PersistentData.SetIsDirty(is_dirty)
    PersistentData.is_dirty = is_dirty
    return PersistentData
end

--- Sets encoded state.
--
-- Whether the stored data should be encoded or not. By default, `ENCODE_SAVES` global is used as
-- a value.
--
-- @tparam boolean is_encoded
-- @treturn SDK.PersistentData
function PersistentData.SetIsEncoded(is_encoded)
    PersistentData.is_encoded = is_encoded
    return PersistentData
end

--- Sets a save name.
-- @tparam string save_name
-- @treturn SDK.PersistentData
function PersistentData.SetSaveName(save_name)
    PersistentData.save_name = save_name
    return PersistentData
end

--- Sets a server expire time.
-- @treturn SDK.PersistentData
function PersistentData.SetServerExpireTime(server_expire_time)
    PersistentData.server_expire_time = server_expire_time
    return PersistentData
end

--- Sets the current mode.
--
-- Modes:
--
-- - `SDK.PersistentData.DEFAULT`
-- - `SDK.PersistentData.SERVER`
--
-- @tparam boolean mode
-- @treturn SDK.PersistentData
function PersistentData.SetMode(mode)
    PersistentData.mode = mode
    return PersistentData
end

--- Data
-- @section data

--- Gets a data field.
--
-- Can optionally set a retrieved value to the destination table as well.
--
-- @usage SDK.PersistentData.Get("foo") -- returns: "bar" (if it has been set earlier of course)
-- @usage SDK.PersistentData.Get("foo", YourTable, "foo") -- also, sets value to YourTable.foo
-- @tparam string key Field name
-- @tparam[opt] table dest Destination class
-- @tparam[opt] string field Destination class field name
-- @treturn any
function PersistentData.Get(key, dest, field)
    if PersistentData.mode == PersistentData.DEFAULT and PersistentData.data then
        if PersistentData.data and not PersistentData.data.general then
            PersistentData.data.general = {}
        end

        local value = PersistentData.data.general[key]
        if value then
            DebugString("[get]", key)
            if dest then
                field = field ~= nil and field or key
                dest[field] = value
            end
            return value
        end

        DebugError("[get]", key)
    elseif PersistentData.mode == PersistentData.SERVER then
        local server = PersistentData.GetServer()
        if not server or not server.data then
            return
        end

        local value = server.data[key]
        if value then
            DebugString("[get]", "[" .. PersistentData.server_id .. "]", key)
            if dest then
                field = field ~= nil and field or key
                dest[field] = value
            end
            return value
        end

        DebugError("[get]", "[" .. PersistentData.server_id .. "]", key)
    end
end

--- Sets a data field.
--
-- The `Save` should be called separately.
--
-- @usage SDK.PersistentData.Set("foo", "bar")
-- @tparam string key Field name
-- @tparam any value Field value
-- @treturn SDK.PersistentData
function PersistentData.Set(key, value)
    if PersistentData.mode == PersistentData.DEFAULT and PersistentData.data then
        if not PersistentData.data.general then
            PersistentData.data.general = {}
        end

        DebugString("[set]", key .. ":", value)
        PersistentData.data.general[key] = value
        PersistentData.is_dirty = true
    elseif PersistentData.mode == PersistentData.SERVER then
        local data = PersistentData.GetServerData()
        if data then
            DebugString("[set]", "[" .. PersistentData.server_id .. "]", key .. ":", value)
            PersistentData.data.servers[PersistentData.server_id].data[key] = value
            PersistentData.is_dirty = true
        end
    end
    return PersistentData
end

--- Server
-- @section server

--- Cleans stale servers.
--
-- Cleans all servers that haven't been seen for the `USER_HISTORY_EXPIRY_TIME` (30 days).
--
-- @treturn SDK.PersistentData
function PersistentData.CleanServers()
    local servers = SDK.Utils.Chain.Get(PersistentData, "data", "servers")
    if type(servers) == "table" then
        local i = 0
        local time = os.time()
        for id, server in pairs(servers) do
            i = i + 1
            if server and server.lastseen then
                if os.difftime(time, server.lastseen) > PersistentData.server_expire_time then
                    DebugString("[remove]", "[" .. id .. "]")
                    PersistentData.data.servers[id] = nil
                    PersistentData.is_dirty = true
                end
            end
        end
    end
    return PersistentData
end

--- Gets a server data.
-- @treturn table
function PersistentData.GetServer()
    PersistentData.server_id = PersistentData.GetServerID()
    if PersistentData.server_id then
        if PersistentData.data and PersistentData.data.servers then
            local server = PersistentData.data.servers[PersistentData.server_id]
            if not server then
                server = {
                    data = {},
                    lastseen = os.time(),
                }
            end

            RefreshLastSeen(server)
            PersistentData.data.servers[PersistentData.server_id] = server
            PersistentData.is_dirty = true

            return server
        end
    end
    DebugError("No server data")
end

--- Gets a server ID.
--
-- Gets a unique server identifier: `TheWorld.net.components.shardstate:GetMasterSessionId()`.
--
-- @treturn string
-- @todo Investigate uniqueness of `GetMasterSessionId()` and possible collisions
function PersistentData.GetServerID()
    return SDK.Utils.Chain.Get(
        TheWorld,
        "net",
        "components",
        "shardstate",
        "GetMasterSessionId",
        true
    )
end

--- Gets a server last seen time.
--
-- Just a convenience method of the `GetServer().lastseen`.
--
-- @treturn number
function PersistentData.GetServerLastSeen()
    local server = PersistentData.GetServer()
    return server and server.lastseen
end

--- Gets the server data.
--
-- Just a convenience method of the `GetServer().data`.
--
-- @treturn table
function PersistentData.GetServerData()
    local server = PersistentData.GetServer()
    return server and server.data
end

--- Refreshes the server last seen time.
--
-- The `Save` should be called separately.
--
-- @treturn SDK.PersistentData
function PersistentData.ServerRefreshLastSeen()
    local server = PersistentData.GetServer()
    if server and server.lastseen then
        RefreshLastSeen(server)
        PersistentData.is_dirty = true
    end
    return PersistentData
end

--- Loading
-- @section loading

--- Loads.
--
-- Gets the data string from a save file and calls the `OnLoad` where the loading is actually
-- handled.
--
-- @tparam[opt] function cb Callback
function PersistentData.Load(cb)
    DebugString("[load]", string.format("Loading %s...", PersistentData.GetSaveName()))
    TheSim:GetPersistentString(PersistentData.GetSaveName(), function(_, str)
        PersistentData.OnLoad(str, cb)
    end, false)

    return PersistentData
end

--- Handles loading.
--
-- Decodes the JSON string into both `data_original` (so we could reset the data state if needed)
-- and `data` (the actual data) fields.
--
-- @tparam string str Data string
-- @tparam[opt] function cb Callback
function PersistentData.OnLoad(str, cb)
    if str == nil or string.len(str) == 0 then
        DebugError("[load]", "Failure", "(empty string)")
        if cb then
            cb(false)
        end
        return
    end

    DebugString("[load]", "Success", "(length: " .. #str .. ")")

    local data = TrackedAssert(
        "TheSim:GetPersistentString " .. PersistentData.name,
        json.decode,
        str
    )

    if not data then
        data = _DEFAULT_PERSIST_DATA
        PersistentData.is_dirty = true
    else
        PersistentData.is_dirty = false
    end

    PersistentData.data_original = data
    PersistentData.data = data
    PersistentData.CleanServers() -- sets the dirty to true as well
    PersistentData.Save()

    if cb then
        cb(true)
    end
end

--- Saving
-- @section saving

--- Saves.
-- @tparam[opt] function cb Callback
-- @tparam[opt] string name Debug name
function PersistentData.Save(cb, name)
    if PersistentData.is_dirty then
        DebugString("[save]", name ~= nil and string.format("Saved (%s)", name) or "Saved")

        SavePersistentString(
            PersistentData.GetSaveName(),
            json.encode(PersistentData.data),
            PersistentData.is_encoded,
            cb
        )

        PersistentData.is_dirty = false

        if cb then
            cb(true)
        end
    end
    return PersistentData
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.PersistentData
function PersistentData._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, PersistentData, "PersistentData")
end

return PersistentData
