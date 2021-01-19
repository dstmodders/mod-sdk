--
-- Packages
--

_G.MOD_SDK_TEST = true

package.path = "./sdk/?.lua;" .. package.path

require "spec/class"
require "spec/vector3"

local preloads = {
    ["yoursubdirectory/sdk/sdk/config"] = "sdk/config",
    ["yoursubdirectory/sdk/sdk/console"] = "sdk/console",
    ["yoursubdirectory/sdk/sdk/constant"] = "sdk/constant",
    ["yoursubdirectory/sdk/sdk/debug"] = "sdk/debug",
    ["yoursubdirectory/sdk/sdk/debugupvalue"] = "sdk/debugupvalue",
    ["yoursubdirectory/sdk/sdk/dump"] = "sdk/dump",
    ["yoursubdirectory/sdk/sdk/entity"] = "sdk/entity",
    ["yoursubdirectory/sdk/sdk/frontend"] = "sdk/frontend",
    ["yoursubdirectory/sdk/sdk/input"] = "sdk/input",
    ["yoursubdirectory/sdk/sdk/method"] = "sdk/method",
    ["yoursubdirectory/sdk/sdk/modmain"] = "sdk/modmain",
    ["yoursubdirectory/sdk/sdk/persistentdata"] = "sdk/persistentdata",
    ["yoursubdirectory/sdk/sdk/player"] = "sdk/player",
    ["yoursubdirectory/sdk/sdk/player/attribute"] = "sdk/player/attribute",
    ["yoursubdirectory/sdk/sdk/player/craft"] = "sdk/player/craft",
    ["yoursubdirectory/sdk/sdk/player/inventory"] = "sdk/player/inventory",
    ["yoursubdirectory/sdk/sdk/remote"] = "sdk/remote",
    ["yoursubdirectory/sdk/sdk/remote/player"] = "sdk/remote/player",
    ["yoursubdirectory/sdk/sdk/remote/world"] = "sdk/remote/world",
    ["yoursubdirectory/sdk/sdk/rpc"] = "sdk/rpc",
    ["yoursubdirectory/sdk/sdk/sdk"] = "sdk/sdk",
    ["yoursubdirectory/sdk/sdk/test"] = "sdk/test",
    ["yoursubdirectory/sdk/sdk/thread"] = "sdk/thread",
    ["yoursubdirectory/sdk/sdk/utils"] = "sdk/utils",
    ["yoursubdirectory/sdk/sdk/utils/chain"] = "sdk/utils/chain",
    ["yoursubdirectory/sdk/sdk/utils/string"] = "sdk/utils/string",
    ["yoursubdirectory/sdk/sdk/utils/table"] = "sdk/utils/table",
    ["yoursubdirectory/sdk/sdk/utils/value"] = "sdk/utils/value",
    ["yoursubdirectory/sdk/sdk/world"] = "sdk/world",
    ["yoursubdirectory/sdk/spec/class"] = "spec/class",
    ["yoursubdirectory/sdk/spec/submodule"] = "spec/submodule",
    ["yoursubdirectory/sdk/spec/vector3"] = "spec/vector3",
}

for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

--
-- SDK
--

function LoadSDK()
    return require("sdk/sdk").UnloadAllModules().SetIsSilent(true).Load({
        modname = "dst-mod-sdk",
        AddPrefabPostInit = function() end
    }, "", {
        "Dump",
        "Test",
    })
end

local SDK = LoadSDK()

--
-- Asserts
--

function AssertDebugError(fn, ...)
    AssertDebugErrorCalls(fn, 1, ...)
end

function AssertDebugErrorCalls(fn, calls, ...)
    local args = { ... }
    if SDK.IsLoaded("Debug") then
        local assert = require "luassert.assert"
        assert.spy(SDK.Debug.Error).was_not_called()
        fn()
        assert.spy(SDK.Debug.Error).was_called(calls)
        if calls > 0 and #args > 0 then
            assert.spy(SDK.Debug.Error).was_called_with(unpack(args))
        end
    end
end

function AssertDebugErrorInvalidArg(fn, module, fn_name, arg_name, explanation)
    AssertDebugErrorInvalidArgCalls(fn, 1, module, fn_name, arg_name, explanation)
end

function AssertDebugErrorInvalidArgCalls(fn, calls, module, fn_name, arg_name, explanation)
    AssertDebugErrorCalls(
        fn,
        calls,
        string.format("%s.%s():", tostring(module), fn_name),
        string.format("Invalid argument%s is passed", arg_name and ' (' .. arg_name .. ")" or ""),
        explanation and "(" .. explanation .. ")"
    )
end

function AssertDebugString(fn, ...)
    AssertDebugStringCalls(fn, 1, ...)
end

function AssertDebugStringCalls(fn, calls, ...)
    local args = { ... }
    if SDK.IsLoaded("Debug") then
        local assert = require "luassert.assert"
        assert.spy(SDK.Debug.String).was_not_called()
        fn()
        assert.spy(SDK.Debug.String).was_called(calls)
        if calls > 0 and #args > 0 then
            assert.spy(SDK.Debug.String).was_called_with(unpack(args))
        end
    end
end

--
-- Tests
--

local _MODULE

function SetTestModule(module)
    _MODULE = module
end

function TestArg(fn_name, name, explanation, args)
    name = name ~= nil and name or "argument"

    local describe = require "busted".describe
    local it = require "busted".it

    if args.empty then
        local _args = args.empty.args or args.empty
        local calls = args.empty.calls or 0
        describe("when no " .. name .. " is passed", function()
            it((calls > 0 and "should" or "shouldn't") .. " debug error string", function()
                AssertDebugErrorInvalidArgCalls(function()
                    _MODULE[fn_name](unpack(_args))
                end, calls, _MODULE, fn_name, name, explanation)
            end)
        end)
    end

    if args.invalid then
        local _args = args.invalid.args or args.invalid
        local calls = args.invalid.calls or 1
        describe("when an invalid " .. name .. " is passed", function()
            it((calls > 0 and "should" or "shouldn't") .. " debug error string", function()
                AssertDebugErrorInvalidArgCalls(function()
                    _MODULE[fn_name](unpack(_args))
                end, calls, _MODULE, fn_name, name, explanation)
            end)
        end)
    end

    if args.valid then
        local _args = args.valid.args or args.valid
        local calls = args.valid.calls or 0
        describe("when a valid " .. name .. " is passed", function()
            it((calls > 0 and "should" or "shouldn't") .. " debug error string", function()
                AssertDebugErrorCalls(function()
                    _MODULE[fn_name](unpack(_args))
                end, calls)
            end)
        end)
    end
end

function TestArgNumber(fn_name, args, name)
    name = name ~= nil and name or "number"
    TestArg(fn_name, name, "must be a number", args)
end

function TestArgPercent(fn_name, args, name)
    name = name ~= nil and name or "percent"
    TestArg(fn_name, name, "must be a percent", args)
end

function TestArgPlayer(fn_name, args, name)
    name = name ~= nil and name or "player"
    TestArg(fn_name, name, "must be a player", args)
end

function TestArgPoint(fn_name, args, name)
    name = name ~= nil and name or "pt"
    TestArg(fn_name, name, "must be a point", args)
end

function TestArgRecipe(fn_name, args, name)
    name = name ~= nil and name or "recipe"
    TestArg(fn_name, name, "must be a valid recipe", args)
end

function TestArgRecipes(fn_name, args, name)
    name = name ~= nil and name or "recipes"
    TestArg(fn_name, name, "must be valid recipes", args)
end

function TestArgSeason(fn_name, args, name)
    name = name ~= nil and name or "season"
    TestArg(fn_name, name, "must be a season: autumn, winter, spring or summer", args)
end

function TestArgString(fn_name, args, name)
    name = name ~= nil and name or "str"
    TestArg(fn_name, name, "must be a string", args)
end

function TestArgUnitInterval(fn_name, args, name)
    name = name ~= nil and name or "number"
    TestArg(fn_name, name, "must be a unit interval", args)
end

function TestArgUnsignedInteger(fn_name, args, name)
    name = name ~= nil and name or "number"
    TestArg(fn_name, name, "must be an unsigned integer", args)
end

function TestRemoteInvalid(name, error, ...)
    local assert = require("busted").assert
    local describe = require "busted".describe
    local it = require "busted".it

    local args = { ... }
    local description = "when no arguments are passed"
    if #args > 1 then
        description = "when valid arguments are passed"
    elseif #args == 1 then
        description = "when a valid argument is passed"
    end

    describe(description, function()
        if error then
            it("should debug error string", function()
                AssertDebugError(
                    function()
                        _MODULE[name](unpack(args))
                    end,
                    string.format("%s.%s():", tostring(_MODULE), name),
                    error.message,
                    error.explanation and "(" .. error.explanation .. ")"
                )
            end)
        end

        it("shouldn't call TheSim:SendRemoteExecute()", function()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
            _MODULE[name](unpack(args))
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
        end)

        it("should return false", function()
            assert.is_false(_MODULE[name](unpack(args)))
        end)
    end)
end

function TestRemoteValid(name, options, ...)
    local assert = require("busted").assert
    local describe = require "busted".describe
    local it = require "busted".it
    local match = require "luassert.match"

    local args = { ... }
    local description = "when no arguments are passed"
    if #args > 1 then
        description = "when valid arguments are passed"
    elseif #args == 1 then
        description = "when a valid argument is passed"
    end

    describe(description, function()
        if options.debug and options.debug.args then
            it("should debug string", function()
                AssertDebugString(function()
                    _MODULE[name](unpack(args))
                end, "[remote]", "[" .. options.debug.name .. "]", unpack(options.debug.args))
            end)
        end

        if options.send then
            it("should call TheSim:SendRemoteExecute()", function()
                assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
                _MODULE[name](unpack(args))
                assert.spy(_G.TheNet.SendRemoteExecute).was_called(1)
                assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                    match.is_ref(_G.TheNet),
                    options.send.data,
                    options.send.x,
                    options.send.z
                )
            end)
        end

        it("should return true", function()
            assert.is_true(_MODULE[name](unpack(args)))
        end)
    end)
end
