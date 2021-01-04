----
-- Mod SDK.
--
-- This is an SDK entry point. On its own it doesn't do much and requires `SDK.Load` to be called
-- inside your `modmain.lua` in order to initialize SDK and load all corresponding submodules.
--
--    local SDK = require "<your subdirectory>/sdk/sdk/sdk"
--
--    SDK.Load(env, "<your subdirectory>/sdk")
--
-- That's it! You may now use SDK by requiring it in any of your mod files:
--
--    local SDK = require "<your subdirectory>/sdk/sdk/sdk"
--
--    dumptable(SDK.Entity.GetTags(ThePlayer))
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local _mt = getmetatable(_G)
if _mt and not (_mt.__declared and _mt.__declared.MOD_SDK_TEST) then
    _G.MOD_SDK_TEST = false
end

local SDK = {
    -- general
    env = nil,
    is_silent = false,
    loaded = {},
    modname = nil,
    path = nil,
    path_full = nil,

    -- constants
    OVERRIDE = {
        ORIGINAL_NONE = 1,
        ORIGINAL_FIRST = 2,
        ORIGINAL_LAST = 3,
    },
    VERSION = 0.1,
}

local _MODULES = {
    Config = "sdk/config",
    Console = "sdk/console",
    Constant = "sdk/constant",
    Debug = "sdk/debug",
    DebugUpvalue = "sdk/debugupvalue",
    Dump = "sdk/dump",
    Entity = "sdk/entity",
    Input = "sdk/input",
    Inventory = "sdk/inventory",
    Method = "sdk/method",
    ModMain = "sdk/modmain",
    PersistentData = "sdk/persistentdata",
    Player = "sdk/player",
    Remote = "sdk/remote",
    RPC = "sdk/rpc",
    Test = "sdk/test",
    Thread = "sdk/thread",
    Utils = "sdk/utils",
    World = "sdk/world",
}

local _IS_IN_CHARACTER_SELECT = false
local _ON_ENTER_CHARACTER_SELECT = {}
local _ON_LOAD_WORLD = {}
local _ON_PLAYER_ACTIVATED = {}
local _ON_PLAYER_DEACTIVATED = {}

--- Helpers
-- @section helpers

local function AddWorldPostInit()
    SDK.env.AddPrefabPostInit("world", function(self)
        if #_ON_LOAD_WORLD > 0 then
            for _, fn in pairs(_ON_LOAD_WORLD) do
                if type(fn) == "function" then
                    fn(self)
                end
            end
        end

        if SDK.World then
            SDK.OnLoadComponent(
                SDK.World.IsCave() and "caveweather" or "weather",
                SDK.World.WeatherOnUpdate
            )
        end

        self:ListenForEvent("entercharacterselect", function(...)
            _IS_IN_CHARACTER_SELECT = true
            if #_ON_ENTER_CHARACTER_SELECT > 0 then
                for _, fn in pairs(_ON_ENTER_CHARACTER_SELECT) do
                    if type(fn) == "function" then
                        fn(...)
                    end
                end
            end
        end)

        self:ListenForEvent("playeractivated", function(world, player, ...)
            _IS_IN_CHARACTER_SELECT = false
            if #_ON_PLAYER_ACTIVATED > 0 and player == ThePlayer then
                for _, fn in pairs(_ON_PLAYER_ACTIVATED) do
                    if type(fn) == "function" then
                        fn(world, player, ...)
                    end
                end
            end
        end)

        self:ListenForEvent("playerdeactivated", function(world, player, ...)
            _IS_IN_CHARACTER_SELECT = false
            if #_ON_PLAYER_DEACTIVATED > 0 and player == ThePlayer then
                for _, fn in pairs(_ON_PLAYER_DEACTIVATED) do
                    if type(fn) == "function" then
                        fn(world, player, ...)
                    end
                end
            end
        end)
    end)
    SDK._Info("Added world post initializer")
end

local function RemoveTrailingSlashes(str)
    return str:gsub("(.)/*$", "%1")
end

local function SanitizePath(path)
    path = RemoveTrailingSlashes(path)
    path = (path:len() > 0 and path ~= "/") and path .. "/" or path
    return path
end

--- Internal
-- @section internal

function SDK._DebugErrorNoCallWithoutGlobal(module, fn_name, global)
    SDK.Debug.Error(string.format(
        "SDK.%s.%s() shouldn't be called when %s global is not available",
        module,
        fn_name,
        global
    ))
end

function SDK._DebugErrorNoDirectUse(module, field, name)
    if not SDK.Debug then
        return
    end

    if type(field) == "function" then
        SDK.Debug.Error(string.format(
            "Function %s.%s() shouldn't be used directly",
            tostring(module),
            name
        ))
    else
        SDK.Debug.Error(string.format(
            "Field %s.%s shouldn't be used directly",
            tostring(module),
            name
        ))
    end
end

function SDK._DebugErrorNoFunction(module, name)
    if SDK.Debug then
        SDK.Debug.Error(string.format(
            "Function or field %s.%s doesn't exist",
            tostring(module),
            name
        ))
    end
end

function SDK._DoInitModule(parent, module, name, global)
    local mt = setmetatable({
        module = module,
        Has = function(field)
            return rawget(module, field) and true or false
        end,
    }, {
        __index = function(_, k)
            if global and not _G[global] then
                SDK._DebugErrorNoCallWithoutGlobal(name, k, global)
            else
                local field = rawget(module, k)
                if type(field) == "function" and not string.match(k, "^_") then -- function
                    return field
                elseif type(field) == "table" and field.module then -- another module or submodule
                    return field
                elseif field then
                    SDK._DebugErrorNoDirectUse(module, field, k)
                else
                    SDK._DebugErrorNoFunction(module, k)
                end
            end

            return function()
                return nil
            end
        end,
    })

    SDK._SetModuleName(parent, module, name)
    SDK._SetModuleName(parent, mt, name)

    return mt
end

function SDK._Error(...)
    SDK._Info("[error]", ...)
end

function SDK._Info(...) -- luacheck: only
    if SDK.is_silent then
        return
    end

    local msg = (SDK.env and SDK.env.modname)
        and string.format("[sdk] [%s]", SDK.env.modname)
        or "[sdk]"

    for i = 1, arg.n do
        msg = msg .. " " .. tostring(arg[i])
    end
    print(msg)
end

function SDK._SetModuleName(parent, module, name)
    local fn = function()
        return tostring(parent) .. "." .. name
    end

    local mt = getmetatable(module)
    if mt then
        mt.__tostring = fn
        return
    end

    setmetatable(module, {
        __tostring = fn
    })
end

--- General
-- @section general

--- Gets an environment.
-- @treturn table
function SDK.GetEnv()
    return SDK.env
end

--- Gets a mod name.
-- @treturn string
function SDK.GetModName()
    return SDK.modname
end

--- Gets an SDK path.
-- @treturn string
function SDK.GetPath()
    return SDK.path
end

--- Gets an SDK full path.
-- @treturn string
function SDK.GetPathFull()
    return SDK.path_full
end

--- Checks if in a silent state.
-- @treturn string
function SDK.IsSilent()
    return SDK.is_silent
end

--- Loads an SDK.
-- @tparam table env Environment
-- @tparam string path Path
-- @tparam[opt] table modules Modules to load
-- @treturn boolean
function SDK.Load(env, path, modules)
    if not env then
        SDK._Error("SDK.Load():", "required env not passed")
        return false
    end

    if type(path) ~= "string" then
        SDK._Error("SDK.Load():", "required path not passed")
        return false
    end

    path = SanitizePath(path)

    if package.loaded.busted then
        if not _G.softresolvefilepath then
            _G.softresolvefilepath = function(filepath)
                return _G.MODS_ROOT .. filepath
            end
        end

        require(path .. "spec/class")
        require(path .. "spec/vector3")
    end

    SDK.env = env
    SDK.modname = env.modname

    SDK.SetPath(path)
    SDK._Info("Loading SDK:", SDK.path_full)

    if softresolvefilepath(SDK.path_full .. "/sdk/sdk.lua") then
        package.path = SDK.path_full .. "/?.lua;" .. package.path
        SDK.LoadModule("Utils", path .. _MODULES.Utils)
        if type(modules) == "table" and SDK.Utils.Table.Count(modules) > 0 then
            for k, v in pairs(modules) do
                if k ~= "Utils" then
                    if type(k) == "number" then
                        SDK.LoadModule(v, path .. _MODULES[v])
                    else
                        SDK.LoadModule(k, v)
                    end
                end
            end
        else
            for k, v in pairs(_MODULES) do
                if k ~= "Utils" then
                    SDK.LoadModule(k, path .. v)
                end
            end
        end

        AddWorldPostInit()
        return true
    end

    SDK._Error("SDK.Load():", "path not resolved")
    return false
end

--- Loads a single module.
-- @see SDK.UnloadModule
-- @tparam string name
-- @tparam[opt] string path
-- @treturn boolean
function SDK.LoadModule(name, path)
    if not name or (not path and not SDK.path) then
        return false
    end

    local module

    SDK.SetPath(SDK.path)
    SDK.UnloadModule(name)

    if path then
        SDK.loaded[name] = path
        module = require(SDK.loaded[name])
    elseif _MODULES[name] then
        SDK.loaded[name] = SDK.path .. _MODULES[name]
        module = require(SDK.loaded[name])
    end

    if type(module) ~= "table" then
        return false
    end

    SDK[name] = module._DoInit and module._DoInit(SDK) or module
    SDK._Info("Loaded", tostring(SDK[name]))

    return true
end

--- Loads a single submodule.
-- @tparam table parent
-- @tparam string name
-- @tparam string path
-- @tparam[opt] table global
-- @treturn boolean
function SDK.LoadSubmodule(parent, name, path, global)
    if not parent or not name or not path then
        return false
    end

    path = RemoveTrailingSlashes(path)

    local module = require(SDK.path .. path)
    if type(module) ~= "table" then
        return false
    end

    module = module._DoInit and module._DoInit(SDK) or module
    module = SDK._DoInitModule(parent, module, name, global)

    SDK._Info("Loaded", tostring(module))

    parent[name] = module

    return true
end

--- Sets a silent state.
-- @tparam boolean is_silent
-- @treturn SDK
function SDK.SetIsSilent(is_silent)
    SDK.is_silent = is_silent
    return SDK
end

--- Sets both path and full path.
-- @tparam string path
-- @treturn SDK
function SDK.SetPath(path)
    SDK.path = SanitizePath(path)

    if package.loaded.busted then
        if not _G.MODS_ROOT then
            _G.MODS_ROOT = ""
        end
    end

    if _G.MODS_ROOT and SDK.modname then
        SDK.path_full = SanitizePath(_G.MODS_ROOT .. SDK.modname .. "/scripts/" .. SDK.path)
    end
    return SDK
end

--- Unloads a single module.
-- @see SDK.LoadModule
-- @tparam string name
-- @treturn boolean
function SDK.UnloadModule(name)
    if not name or not rawget(SDK, name) then
        return false
    end

    local module_name = tostring(SDK[name])

    if not SDK.loaded[name] then
        SDK._Error("Module", module_name, "is not loaded")
    end

    if package.loaded[SDK.loaded[name]] then
        package.loaded[SDK.loaded[name]] = nil
        SDK[name] = nil
        SDK.loaded[name] = nil
        SDK._Info("Unloaded", module_name)
    end

    return true
end

--- Post Initializers
-- @section post-initializers

--- Checks if in a character select.
-- @treturn boolean
function SDK.IsInCharacterSelect()
    return _IS_IN_CHARACTER_SELECT
end

--- Triggered when entering the character select screen.
-- @tparam function fn Function
function SDK.OnEnterCharacterSelect(fn)
    if type(fn) == "function" then
        table.insert(_ON_ENTER_CHARACTER_SELECT, fn)
    end
end

--- Triggered when the player is activated.
-- @tparam function fn Function
function SDK.OnPlayerActivated(fn)
    if type(fn) == "function" then
        table.insert(_ON_PLAYER_ACTIVATED, fn)
    end
end

--- Triggered when the player is deactivated.
-- @tparam function fn Function
function SDK.OnPlayerDeactivated(fn)
    if type(fn) == "function" then
        table.insert(_ON_PLAYER_DEACTIVATED, fn)
    end
end

--- Triggered after a class initialization.
--
-- Just wraps `AddClassPostConstruct`.
--
-- @tparam string src Class
-- @tparam function fn Function
function SDK.OnLoadClass(src, fn)
    SDK.env.AddClassPostConstruct(src, function(...)
        fn(...)
    end)
end

--- Triggered after a component initialization.
--
-- Just wraps `AddComponentPostInit`.
--
-- @tparam string src Component
-- @tparam function fn Function
function SDK.OnLoadComponent(src, fn)
    SDK.env.AddComponentPostInit(src, function(...)
        fn(...)
    end)
end

--- Triggered when the world is loaded.
-- @tparam function fn Function
function SDK.OnLoadWorld(fn)
    if type(fn) == "function" then
        table.insert(_ON_LOAD_WORLD, fn)
    end
end

--- Overrides
-- @section overrides

--- Overrides a method.
-- @tparam string src Source
-- @tparam string method Method to override
-- @tparam function fn New function
-- @tparam number override Override type
function SDK.OverrideMethod(src, method, fn, override)
    override = override == nil and SDK.OVERRIDE.ORIGINAL_LAST or override
    local original_fn = src[method]
    src[method] = function(...)
        if override == SDK.OVERRIDE.ORIGINAL_NONE then
            return fn(original_fn, ...)
        elseif override == SDK.OVERRIDE.ORIGINAL_FIRST then
            original_fn(...)
            return fn(original_fn, ...)
        elseif override == SDK.OVERRIDE.ORIGINAL_LAST then
            fn(original_fn, ...)
            return original_fn(...)
        end
    end
end

--- Overrides a component method.
-- @tparam string component Component
-- @tparam string method Method to override
-- @tparam function fn New function
-- @tparam number override Override type
function SDK.OverrideComponentMethod(component, method, fn, override)
    if type(component) == "string" then
        SDK.env.AddComponentPostInit(component, function(self)
            SDK.OverrideMethod(self, method, fn, override)
        end)
    else
        SDK.OverrideMethod(component, method, fn, override)
    end
end

setmetatable(SDK, {
    __index = function(self, k)
        if _MODULES[k] and not rawget(self, k) then
            local msg = string.format(
                'SDK.%s is not loaded. Use SDK.LoadModule("%s") or SDK.Load()',
                k,
                k
            )
            SDK._Error(msg)
            assert(false, msg)
            return
        end
        return rawget(self, k)
    end,
    __tostring = function()
        return "SDK"
    end,
})

return SDK
