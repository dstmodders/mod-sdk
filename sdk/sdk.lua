----
-- Mod SDK entry point.
--
-- This is an SDK entry point. On its own it doesn't do much and requires `SDK.Load` to be called
-- inside your `modmain.lua` in order to initialize SDK and load all corresponding submodules.
--
--    require("<your subdirectory>/sdk/sdk/sdk").Load(env, "<your subdirectory>/sdk")
--
-- That's it! You may now use SDK by requiring it in any of your mod files:
--
--    local SDK = require "<your subdirectory>/sdk/sdk/sdk"
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
    FrontEnd = "sdk/frontend",
    Input = "sdk/input",
    Method = "sdk/method",
    ModMain = "sdk/modmain",
    PersistentData = "sdk/persistentdata",
    Player = {
        path = "sdk/player",
        submodules = {
            Attribute = "sdk/player/attribute",
            Craft = "sdk/player/craft",
            Inventory = "sdk/player/inventory",
        },
    },
    Remote = {
        path = "sdk/remote",
        submodules = {
            Player = "sdk/remote/player",
            World = "sdk/remote/world",
        }
    },
    RPC = "sdk/rpc",
    Test = "sdk/test",
    Thread = "sdk/thread",
    Time = "sdk/time",
    Utils = {
        path = "sdk/utils",
        submodules = {
            Chain = "sdk/utils/chain",
            Table = "sdk/utils/table",
            Value = "sdk/utils/value",
        }
    },
    World = {
        path = "sdk/world",
        submodules = {
            SaveData = "sdk/world/savedata",
            Season = "sdk/world/season",
            Weather = "sdk/world/weather",
        },
    },
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

        if SDK.IsLoaded("World") and SDK.IsLoaded("DebugUpvalue") then
            SDK.OnLoadComponent(
                SDK.World.IsCave() and "caveweather" or "weather",
                SDK.World.Weather.OverrideOnUpdate
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

--- Reloads a game.
-- @treturn boolean
function SDK.Reload()
    if not InGamePlay() then
        SDK._DebugString("Reloading simulation...")
        StartNextInstance()
        return true
    end

    if SDK.World then
        return SDK.World.Rollback(0)
    end

    return false
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

--- Load
-- @section load

--- Checks if a module is loaded.
-- @tparam string name Module name
-- @treturn boolean
function SDK.IsLoaded(name)
    return SDK.loaded[name] and true or false
end

--- Loads an SDK.
-- @tparam table env Environment
-- @tparam string path Path
-- @tparam[opt] table modules Modules to load
-- @treturn SDK|boolean
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

        -- load all utilities first in all cases
        SDK.LoadModule("Utils", path .. _MODULES.Utils.path)

        if type(modules) == "table" and SDK.Utils.Table.Count(modules) > 0 then
            -- load all only the provided modules (except utilities)
            modules = SDK.SanitizeModules(modules)
            for k, v in pairs(modules) do
                if k ~= "Utils" then
                    SDK.LoadModule(k, path .. v.path, v.submodules)
                end
            end
        else
            -- load all modules (except utilities)
            modules = SDK.SanitizeModules(_MODULES)
            for k, v in pairs(modules) do
                if k ~= "Utils" then
                    SDK.LoadModule(k, path .. v.path, v.submodules)
                end
            end
        end

        AddWorldPostInit()
        return SDK
    end

    SDK._Error("SDK.Load():", "path not resolved")
    return false
end

--- Loads a single module.
-- @see SDK.UnloadModule
-- @usage SDK.LoadModule("Player")
-- @usage SDK.LoadModule("Player", "<your subdirectory>/sdk/player")
-- @tparam string name
-- @tparam[opt] string path
-- @tparam[opt] table submodules
-- @treturn boolean
function SDK.LoadModule(name, path, submodules)
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
        SDK.loaded[name] = SDK.path .. (type(_MODULES[name]) == "string"
            and _MODULES[name]
            or _MODULES[name].path)
        module = require(SDK.loaded[name])
    end

    if type(module) ~= "table" then
        return false
    end

    SDK[name] = module._DoInit and module._DoInit(SDK, submodules) or module
    SDK._Info("Loaded", tostring(SDK[name]))

    return true
end

--- Loads a single submodule.
-- @see SDK.LoadSubmodules
-- @tparam table parent
-- @tparam string name
-- @tparam string path
-- @tparam[opt] table global
-- @treturn boolean
function SDK.LoadSubmodule(parent, name, path, global)
    if parent and name and path then
        path = RemoveTrailingSlashes(path)

        local module = require(SDK.path .. path)
        if type(module) ~= "table" then
            return false
        end

        module = module._DoInit and module._DoInit(SDK, parent) or module
        module = SDK._DoInitModule(parent, module, name, global)

        SDK._Info("Loaded", tostring(module))

        parent[name] = module
    end
    return SDK
end

--- Loads submodules.
-- @see SDK.LoadSubmodule
-- @tparam table parent
-- @tparam table submodules
-- @tparam[opt] table global
-- @treturn SDK
function SDK.LoadSubmodules(parent, submodules, global)
    if parent and type(submodules) == "table" then
        submodules = SDK.SanitizeSubmodules(parent._name, submodules)
        for k, v in pairs(submodules) do
            SDK.LoadSubmodule(parent, k, v.path, global)
        end
    end
    return SDK
end

--- Unloads a single module.
-- @see SDK.LoadModule
-- @usage SDK.UnloadModule("Player")
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

--- Unloads a single module.
-- @see SDK.LoadModule
-- @tparam string name
-- @treturn SDK
function SDK.UnloadAllModules()
    for k, v in pairs(SDK.loaded) do
        package.loaded[v] = nil
        SDK._Info("Unloaded", tostring(SDK[k]))
        SDK[k] = nil
        SDK.loaded[k] = nil
    end
    return SDK
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

--- Sanitize
-- @section sanitize

--- Sanitizes modules.
-- @tparam table modules
-- @treturn table
function SDK.SanitizeModules(modules)
    if type(modules) ~= "table" then
        return
    end

    local t = {}
    for k, v in pairs(modules) do
        if type(k) == "number" then
            t[v] = {
                path = type(_MODULES[v]) == "string" and _MODULES[v] or _MODULES[v].path,
                submodules = SDK.SanitizeSubmodules(v),
            }
        else
            t[k] = {
                path = type(v) ~= "string" and v.path or (type(_MODULES[k]) ~= "string"
                    and _MODULES[k].path
                    or _MODULES[k]) or v,
            }

            t[k].submodules = SDK.SanitizeSubmodules(k, v.submodules)

            if type(v) == "table" and not v.submodules and not v.path then
                t[k].submodules = SDK.SanitizeSubmodules(k, v)
            end
        end
    end

    return t
end

--- Sanitizes submodules.
-- @tparam string module Module name
-- @tparam[opt] table submodules Submodules
-- @treturn table
function SDK.SanitizeSubmodules(module, submodules)
    if _MODULES[module] and not _MODULES[module].submodules then
        return
    end

    local modules
    if _MODULES[module] then
        modules = _MODULES[module].submodules
        if not submodules then
            submodules = modules
        end
    else
        modules = submodules
    end

    local t = {}
    for k, v in pairs(submodules) do
        if type(k) == "number" then
            t[v] = {
                path = modules[v],
            }
        else
            t[k] = {
                path = type(v) ~= "string" and v.path or (type(modules[k]) ~= "string"
                    and modules[k].path
                    or modules[k]) or v
            }
        end
    end

    return t
end

--- Internal
-- @section internal

--- Checks if an argument is a number.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgNumber(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "number"
    if SDK.Utils.Value.IsNumber(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a number")
end

--- Checks if a player argument is valid.
-- @tparam table module
-- @tparam string fn_name
-- @tparam[opt] any value
-- @tparam[opt] string arg_name
function SDK._ArgPlayer(module, fn_name, value, arg_name)
    value = value ~= nil and value or ThePlayer
    arg_name = arg_name ~= nil and arg_name or "player"
    if SDK.Utils.Value.IsPlayer(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a player")
end

--- Checks if a player argument is an alive player.
-- @tparam table module
-- @tparam string fn_name
-- @tparam[opt] any value
-- @tparam[opt] string arg_name
function SDK._ArgPlayerAlive(module, fn_name, value, arg_name)
    value = value ~= nil and value or ThePlayer
    arg_name = arg_name ~= nil and arg_name or "player"

    if not SDK.Utils.Value.IsPlayer(value) then
        SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a player")
        return
    end

    if value:HasTag("playerghost") then
        SDK._DebugErrorNoPlayerGhost(module, fn_name)
        return
    end

    return value
end

--- Checks if an argument is a point.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgPoint(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "pt"
    if SDK.Utils.Value.IsPoint(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a point")
end

--- Checks if an argument is a prefab.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgPrefab(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "prefab"
    if SDK.Utils.Value.IsPrefab(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a prefab")
end

--- Checks if an argument is a recipe.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgRecipe(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "recipe"
    if SDK.Utils.Value.IsRecipeValid(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a valid recipe")
end

--- Checks if an argument is recipes.
-- @tparam table module
-- @tparam string fn_name
-- @tparam[opt] any value
-- @tparam[opt] string arg_name
function SDK._ArgRecipes(module, fn_name, value, arg_name)
    value = value ~= nil and value or AllRecipes
    arg_name = arg_name ~= nil and arg_name or "recipes"
    if type(value) == "table" then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be valid recipes")
end

--- Checks if an argument is a season.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgSeason(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "season"
    if SDK.Utils.Value.IsSeason(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(
        module,
        fn_name,
        arg_name,
        "must be a season: autumn, winter, spring or summer"
    )
end

--- Checks if an argument is a string.
-- @tparam table module
-- @tparam string fn_name
-- @tparam[opt] any value
-- @tparam[opt] string arg_name
function SDK._ArgString(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "str"
    if SDK.Utils.Value.IsString(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a string")
end

--- Checks if an argument is a unit interval.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgUnitInterval(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "number"
    if SDK.Utils.Value.IsUnitInterval(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be a unit interval")
end

--- Checks if an argument is an unsigned number.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgUnsigned(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "number"
    if SDK.Utils.Value.IsUnsigned(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be an unsigned number")
end

--- Checks if an argument is an unsigned integer.
-- @tparam table module
-- @tparam string fn_name
-- @tparam any value
-- @tparam[opt] string arg_name
function SDK._ArgUnsignedInteger(module, fn_name, value, arg_name)
    arg_name = arg_name ~= nil and arg_name or "number"
    if SDK.Utils.Value.IsUnsigned(value) and SDK.Utils.Value.IsInteger(value) then
        return value
    end
    SDK._DebugErrorInvalidArg(module, fn_name, arg_name, "must be an unsigned integer")
end

--- Debugs an error string.
-- @tparam any ...
function SDK._DebugError(...)
    if SDK.IsLoaded("Debug") then
        SDK.Debug.Error(...)
    end
end

--- Debugs an error function string.
-- @tparam table module Module
-- @tparam string fn_name Function name
-- @tparam any ...
function SDK._DebugErrorFn(module, fn_name, ...)
    SDK._DebugError(string.format("%s.%s():", tostring(module), fn_name), ...)
end

--- Debugs an invalid argument error string.
-- @tparam table module Module
-- @tparam string fn_name Function name
-- @tparam string arg_name Argument name
-- @tparam[opt] string explanation Explanation
function SDK._DebugErrorInvalidArg(module, fn_name, arg_name, explanation)
    SDK._DebugErrorFn(
        module,
        fn_name,
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

--- Debugs an invalid world type error string.
-- @tparam table module Module
-- @tparam string fn_name Function name
-- @tparam[opt] string explanation Explanation
function SDK._DebugErrorInvalidWorldType(module, fn_name, explanation)
    SDK._DebugErrorFn(
        module,
        fn_name,
        "Invalid world type",
        explanation and "(" .. explanation .. ")"
    )
end

--- Debugs a calling without global error string.
-- @tparam table module Module
-- @tparam any field Field/Function
-- @tparam string name Field/Function name
-- @tparam string global Global name
function SDK._DebugErrorNoCallWithoutGlobal(module, field, name, global)
    SDK._DebugError(string.format(
        type(field) == "function"
            and "Function %s.%s() shouldn't be called when %s global is not available"
            or "Field %s.%s shouldn't be called when %s global is not available",
        tostring(module),
        name,
        global
    ))
end

--- Debugs a calling directly error string.
-- @tparam table module Module
-- @tparam any field Field/Function
-- @tparam string name Field/Function name
function SDK._DebugErrorNoDirectUse(module, field, name)
    SDK._DebugError(string.format(
        type(field) == "function"
            and "Function %s.%s() shouldn't be used directly"
            or "Field %s.%s shouldn't be used directly",
        tostring(module),
        name
    ))
end

--- Debugs a missing function error string.
-- @tparam table module Module
-- @tparam string name Field/Function name
function SDK._DebugErrorNoFunction(module, name)
    SDK._DebugError(string.format("Function or field %s.%s doesn't exist", tostring(module), name))
end

--- Debugs a player is dead error string.
-- @tparam table module Module
-- @tparam string fn_name Function name
function SDK._DebugErrorNoPlayerGhost(module, fn_name)
    SDK._DebugErrorFn(module, fn_name, "Player shouldn't be a ghost")
end

--- Debugs a notice string.
-- @tparam any ...
function SDK._DebugNotice(...)
    SDK._DebugString("[notice]", ...)
end

--- Debugs a missing function error string.
-- @tparam table module Module
-- @tparam string fn_name Function name
-- @tparam any ...
function SDK._DebugNoticeFn(module, fn_name, ...)
    SDK._DebugNotice(string.format("%s.%s():", tostring(module), fn_name), ...)
end

--- Debugs a time scale mismatch notice string.
-- @tparam table module Module
-- @tparam string fn_name Function name
function SDK._DebugNoticeTimeScaleMismatch(module, fn_name)
    SDK._DebugNoticeFn(
        module,
        fn_name,
        "Other players will experience a client-side time scale mismatch"
    )
end

--- Debugs a string.
-- @tparam any ...
function SDK._DebugString(...)
    if SDK.IsLoaded("Debug") then
        SDK.Debug.String(...)
    end
end

--- Initializes a module.
-- @usage SDK._DoInitModule(SDK, YourModule, "YourModule")
-- @usage SDK._DoInitModule(SDK, YourModule, "YourModule", "TheWorld")
-- @usage SDK._DoInitModule(SDK, YourModule, "YourModule", {
--     global = "TheWorld",
-- })
-- @tparam table parent Parent module
-- @tparam table module Module
-- @tparam string name Module name
-- @tparam[opt] table|string options Options or a global name
-- @treturn table
function SDK._DoInitModule(parent, module, name, options)
    options = options ~= nil and options or {}

    SDK._SetModuleName(parent, module, name)

    local global = type(options) == "string" and options or options.global
    local t = setmetatable({
        module = module,
        options = {
            global = global,
        },
        Has = function(field)
            return rawget(module, field) and true or false
        end,
    }, {
        __index = function(_, k)
            local field = rawget(module, k)
            if global and not _G[global] then
                SDK._DebugErrorNoCallWithoutGlobal(module, field, k, global)
            else
                if type(field) == "function" and not string.match(k, "^_") then -- function
                    return field
                elseif type(field) == "table" and field.module then -- another module or submodule
                    return field
                elseif field and string.match(k, "^_") then
                    SDK._DebugErrorNoDirectUse(module, field, k)
                elseif field then
                    return field
                else
                    SDK._DebugErrorNoFunction(module, k)
                end
            end

            return function() end
        end,
    })

    SDK._SetModuleName(parent, t, name)

    return t
end

--- Prints an error string.
-- @tparam any ...
function SDK._Error(...)
    SDK._Info("[error]", ...)
end

--- Gets a component.
-- @tparam table module
-- @tparam string fn_name
-- @tparam EntityScript entity
-- @tparam string name
function SDK._GetComponent(module, fn_name, entity, name)
    local component = SDK.Utils.Chain.Get(entity, "components", name)
    if component then
        return component
    end

    local _name = name:gsub("^%l", string.upper)
    if entity then
        SDK._DebugErrorFn(
            module,
            fn_name,
            _name,
            "component is not available",
            entity.GetDisplayName and "(" .. entity:GetDisplayName() .. ")"
        )
    else
        SDK._DebugErrorFn(module, fn_name, _name, "component is not available")
    end
end

--- Gets a replica.
-- @tparam table module
-- @tparam string fn_name
-- @tparam EntityScript entity
-- @tparam string name
function SDK._GetReplica(module, fn_name, entity, name)
    local replica = SDK.Utils.Chain.Get(entity, "replica", name)
    if replica then
        return replica
    end

    local _name = name:gsub("^%l", string.upper)
    if entity then
        SDK._DebugErrorFn(
            module,
            fn_name,
            _name,
            "replica is not available",
            entity.GetDisplayName and "(" .. entity:GetDisplayName() .. ")"
        )
    else
        SDK._DebugErrorFn(module, fn_name, _name, "replica is not available")
    end
end

--- Prints an info string.
-- @tparam any ...
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

--- Sets a module name.
-- @tparam table parent Parent module
-- @tparam table module Module
-- @tparam string name Module name
function SDK._SetModuleName(parent, module, name)
    local fn = function()
        return tostring(parent) .. "." .. name
    end

    module._name = name

    local mt = getmetatable(module)
    if mt then
        mt.__tostring = fn
        return
    end

    setmetatable(module, {
        __tostring = fn
    })
end

setmetatable(SDK, {
    __index = function(self, k)
        if not self.IsLoaded(k) and _MODULES[k] then
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
