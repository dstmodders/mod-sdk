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

function TestArgPlayer(module, fn_name, args)
    local describe = require "busted".describe
    local it = require "busted".it

    if args.empty then
        local _args = args.empty.args or args.empty
        local calls = args.empty.calls or 0
        describe("when no player is passed", function()
            it("shouldn't debug error string", function()
                AssertDebugErrorCalls(function()
                    module[fn_name](unpack(_args))
                end, calls)
            end)
        end)
    end

    if args.invalid then
        local _args = args.invalid.args or args.invalid
        local calls = args.invalid.calls or 1
        describe("when an invalid player is passed", function()
            it("should debug error string", function()
                AssertDebugErrorInvalidArgCalls(function()
                    module[fn_name](unpack(_args))
                end, calls, module, fn_name, "player", "must be a player")
            end)
        end)
    end

    if args.valid then
        local _args = args.valid.args or args.valid
        local calls = args.valid.calls or 0
        describe("when a valid player is passed", function()
            it("shouldn't debug error string", function()
                AssertDebugErrorCalls(function()
                    module[fn_name](unpack(_args))
                end, calls)
            end)
        end)
    end
end

function TestArgRecipe(module, fn_name, args)
    local describe = require "busted".describe
    local it = require "busted".it

    if args.empty then
        local _args = args.empty.args or args.empty
        local calls = args.empty.calls or 1
        describe("when no recipe is passed", function()
            it("should debug error string", function()
                AssertDebugErrorInvalidArgCalls(function()
                    module[fn_name](unpack(_args))
                end, calls, module, fn_name, "recipe", "must be a valid recipe")
            end)
        end)
    end

    if args.invalid then
        local _args = args.invalid.args or args.invalid
        local calls = args.invalid.calls or 1
        describe("when an invalid recipe is passed", function()
            it("should debug error string", function()
                AssertDebugErrorInvalidArgCalls(function()
                    module[fn_name](unpack(_args))
                end, calls, module, fn_name, "recipe", "must be a valid recipe")
            end)
        end)
    end

    if args.valid then
        local _args = args.valid.args or args.valid
        local calls = args.valid.calls or 0
        describe("when a valid recipe is passed", function()
            it("shouldn't debug error string", function()
                AssertDebugErrorCalls(function()
                    module[fn_name](unpack(_args))
                end, calls)
            end)
        end)
    end
end

function TestArgRecipes(module, fn_name, args)
    local describe = require "busted".describe
    local it = require "busted".it

    if args.empty then
        local calls = args.empty.calls or 0
        describe("when no recipes are passed", function()
            it("shouldn't debug error string", function()
                AssertDebugErrorCalls(function()
                    module[fn_name](unpack(args.empty))
                end, calls)
            end)
        end)
    end

    if args.invalid then
        describe("when invalid recipes are passed", function()
            it("should debug error string", function()
                if args.invalid.calls then
                    AssertDebugErrorInvalidArgCalls(function()
                        module[fn_name](unpack(args.invalid.args))
                    end, args.invalid.calls, module, fn_name, "recipes", "must be valid recipes")
                else
                    AssertDebugErrorInvalidArg(function()
                        module[fn_name](unpack(args.invalid))
                    end, module, fn_name, "recipes", "must be valid recipes")
                end
            end)
        end)
    end

    if args.valid then
        local calls = args.valid.calls or 0
        describe("when valid recipes are passed", function()
            it("shouldn't debug error string", function()
                AssertDebugErrorCalls(function()
                    module[fn_name](unpack(args.valid))
                end, calls)
            end)
        end)
    end
end
