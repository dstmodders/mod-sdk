----
-- Mod SDK.
--
-- Includes Don't Starve Together mod SDK to simplify mods' development.
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
local SDK = {
    -- general
    env = nil,
    modname = nil,
    path = nil,

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
    DebugUpvalue = "sdk/debugupvalue",
    Dump = "sdk/dump",
    ModMain = "sdk/modmain",
    RPC = "sdk/rpc",
}

local _ON_ENTER_CHARACTER_SELECT = {}
local _ON_LOAD_WORLD = {}
local _ON_PLAYER_ACTIVATED = {}
local _ON_PLAYER_DEACTIVATED = {}

--- Helpers
-- @section helpers

local function Info(...) -- luacheck: only
    local msg = "[SDK]"
    for i = 1, arg.n do
        msg = msg .. " " .. tostring(arg[i])
    end
    print(msg)
end

local function Error(...)
    Info("[error]", ...)
end

local function AddWorldPostInit()
    SDK.env.AddPrefabPostInit("world", function(self)
        if #_ON_LOAD_WORLD > 0 then
            for _, fn in pairs(_ON_LOAD_WORLD) do
                if type(fn) == "function" then
                    fn(self)
                end
            end
        end

        self:ListenForEvent("entercharacterselect", function(...)
            if #_ON_ENTER_CHARACTER_SELECT > 0 then
                for _, fn in pairs(_ON_ENTER_CHARACTER_SELECT) do
                    if type(fn) == "function" then
                        fn(...)
                    end
                end
            end
        end)

        self:ListenForEvent("playeractivated", function(world, player, ...)
            if #_ON_PLAYER_ACTIVATED > 0 and player == ThePlayer then
                for _, fn in pairs(_ON_PLAYER_ACTIVATED) do
                    if type(fn) == "function" then
                        fn(world, player, ...)
                    end
                end
            end
        end)

        self:ListenForEvent("playerdeactivated", function(world, player, ...)
            if #_ON_PLAYER_DEACTIVATED > 0 and player == ThePlayer then
                for _, fn in pairs(_ON_PLAYER_DEACTIVATED) do
                    if type(fn) == "function" then
                        fn(world, player, ...)
                    end
                end
            end
        end)
    end)
    Info("Added world post initializer")
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

function SDK._DebugErrorNoDirectUse(module, fn_name)
    SDK.Debug.Error(string.format("SDK.%s.%s() shouldn't be used directly", module, fn_name))
end

function SDK._DebugErrorNoFunction(module, fn_name)
    SDK.Debug.Error(string.format("SDK.%s.%s() doesn't exist", module, fn_name))
end

function SDK._DoInitModule(module, name, global)
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            if global and not _G[global] then
                SDK._DebugErrorNoCallWithoutGlobal(name, k, global)
            else
                local fn = rawget(module, k)
                if fn and not string.match(k, "^_") then
                    return fn
                elseif string.match(k, "^_") then
                    SDK._DebugErrorNoDirectUse(name, k)
                else
                    SDK._DebugErrorNoFunction(name, k)
                end
            end

            return function()
                return nil
            end
        end,
    })
    return t
end

--- General
-- @section general

--- Gets environment.
-- @treturn table
function SDK.GetEnv()
    return SDK.env
end

--- Gets mod name.
-- @treturn string
function SDK.GetModName()
    return SDK.modname
end

--- Gets SDK path.
-- @treturn string
function SDK.GetPath()
    return SDK.path
end

--- Loads single module.
-- @tparam string name
-- @tparam[opt] string path
function SDK.LoadModule(name, path)
    path = path ~= nil and path or _MODULES[name]
    local module = require(path)
    if type(module) == "table" then
        SDK[name] = module._DoInit and module._DoInit(SDK) or module
    end
end

--- Loads SDK.
-- @tparam table env Environment
-- @tparam string path Path
-- @tparam table modules Modules to load
-- @treturn boolean
function SDK.Load(env, path, modules)
    path = path ~= nil and path or "scripts/sdk"

    SDK.env = env
    SDK.modname = env.modname
    SDK.path = MODS_ROOT .. SDK.modname .. "/" .. path

    Info(string.format("Loading from: %s", SDK.path))

    if softresolvefilepath(SDK.path .. "/sdk/sdk.lua") then
        package.path = SDK.path .. "/?.lua;" .. package.path

        SDK.LoadModule("Utils", "sdk/utils")

        local total = SDK.Utils.Table.Count(modules)
        if total ~= false and total > 0 then
            for k, v in pairs(modules) do
                if type(k) == "number" then
                    SDK.LoadModule(v)
                else
                    SDK.LoadModule(k, v)
                end
            end
        end

        AddWorldPostInit()
        return true
    end

    Error(string.format("Path not resolved: %s", SDK.path))
    return false
end

--- Post Constructors
-- @section post-constructors

--- Triggered after class constructor.
--
-- Just wraps `AddClassPostConstruct`.
--
-- @tparam string src Class source
-- @tparam function fn Function
function SDK.OnClassPostConstruct(src, fn)
    SDK.env.AddClassPostConstruct(src, function(...)
        fn(...)
    end)
end

--- Triggered when entering character select.
-- @tparam function fn Function
function SDK.OnEnterCharacterSelect(fn)
    if type(fn) == "function" then
        table.insert(_ON_ENTER_CHARACTER_SELECT, fn)
    end
end

--- Triggered when player is activated.
-- @tparam function fn Function
function SDK.OnPlayerActivated(fn)
    if type(fn) == "function" then
        table.insert(_ON_PLAYER_ACTIVATED, fn)
    end
end

--- Triggered when player is deactivated.
-- @tparam function fn Function
function SDK.OnPlayerDeactivated(fn)
    if type(fn) == "function" then
        table.insert(_ON_PLAYER_DEACTIVATED, fn)
    end
end

--- Triggered when worlds is loaded.
-- @tparam function fn Function
function SDK.OnLoadWorld(fn)
    if type(fn) == "function" then
        table.insert(_ON_LOAD_WORLD, fn)
    end
end

--- Overrides
-- @section overrides

--- Overrides method.
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

--- Overrides component method.
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
            Error(msg)
            assert(false, msg)
            return
        end
        return rawget(self, k)
    end,
})

return SDK
