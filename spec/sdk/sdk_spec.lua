require "busted.runner"()
require "class"

describe("#sdk SDK", function()
    -- before_each initialization
    local SDK

    before_each(function()
        SDK = require "sdk"
    end)

    describe("internal", function()
        local _print

        setup(function()
            _print = _G.print
        end)

        before_each(function()
            _G.print = spy.new(Empty)
        end)

        teardown(function()
            _G.print = _print
        end)

        describe("Info()", function()
            describe("when SDK.env is available", function()
                before_each(function()
                    SDK.env = {
                        modname = "dst-mod-sdk",
                    }
                end)

                it("should print error", function()
                    assert.spy(_G.print).was_not_called()
                    SDK._Info("one", "two", "three")
                    assert.spy(_G.print).was_called(1)
                    assert.spy(_G.print).was_called_with(
                        "[sdk] [dst-mod-sdk] one two three"
                    )
                end)
            end)

            describe("when SDK.env is not available", function()
                before_each(function()
                    SDK.env = nil
                end)

                it("should print error", function()
                    assert.spy(_G.print).was_not_called()
                    SDK._Info("one", "two", "three")
                    assert.spy(_G.print).was_called(1)
                    assert.spy(_G.print).was_called_with("[sdk] one two three")
                end)
            end)
        end)

        describe("Error()", function()
            describe("when SDK.env is available", function()
                before_each(function()
                    SDK.env = {
                        modname = "dst-mod-sdk",
                    }
                end)

                it("should print error", function()
                    assert.spy(_G.print).was_not_called()
                    SDK._Error("one", "two", "three")
                    assert.spy(_G.print).was_called(1)
                    assert.spy(_G.print).was_called_with(
                        "[sdk] [dst-mod-sdk] [error] one two three"
                    )
                end)
            end)

            describe("when SDK.env is not available", function()
                before_each(function()
                    SDK.env = nil
                end)

                it("should print error", function()
                    assert.spy(_G.print).was_not_called()
                    SDK._Error("one", "two", "three")
                    assert.spy(_G.print).was_called(1)
                    assert.spy(_G.print).was_called_with("[sdk] [error] one two three")
                end)
            end)
        end)
    end)

    describe("general", function()
        before_each(function()
            SDK._Error = spy.new(Empty)
            SDK._Info = spy.new(Empty)
        end)

        describe("should have a", function()
            describe("getter", function()
                local getters = {
                    env = "GetEnv",
                    modname = "GetModName",
                    path = "GetPath",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(SDK, field, getter)
                    end)
                end
            end)
        end)

        describe("Load()", function()
            describe("when env not passed", function()
                it("should print error", function()
                    assert.spy(SDK._Error).was_not_called()
                    SDK.Load()
                    assert.spy(SDK._Error).was_called(1)
                    assert.spy(SDK._Error).was_called_with("SDK.Load():", "required env not passed")
                end)

                it("should return false", function()
                    assert.is_false(SDK.Load())
                end)
            end)

            describe("when path not passed", function()
                it("should print error", function()
                    assert.spy(SDK._Error).was_not_called()
                    SDK.Load({})
                    assert.spy(SDK._Error).was_called(1)
                    assert.spy(SDK._Error).was_called_with(
                        "SDK.Load():",
                        "required path not passed"
                    )
                end)

                it("should return false", function()
                    assert.is_false(SDK.Load({}))
                end)
            end)

            describe("when both env and path are passed", function()
                local env

                setup(function()
                    _G.MODS_ROOT = "./"
                    _G.softresolvefilepath = spy.new(ReturnValueFn(false))
                end)

                before_each(function()
                    env = mock({
                        modname = "dst-mod-sdk",
                        AddPrefabPostInit = Empty,
                    })

                    SDK.env = nil
                    SDK.path = nil
                end)

                teardown(function()
                    _G.MODS_ROOT = nil
                    _G.softresolvefilepath = nil
                end)

                it("should add SDK.env", function()
                    assert.is_nil(SDK.env)
                    SDK.Load(env, "yoursubdirectory/sdk")
                    assert.is_equal(env, SDK.env)
                end)

                it("should add SDK.path", function()
                    assert.is_nil(SDK.path)
                    SDK.Load(env, "yoursubdirectory/sdk")
                    assert.is_equal("./dst-mod-sdk/scripts/yoursubdirectory/sdk", SDK.path)
                end)

                describe("when path is resolved", function()
                    setup(function()
                        _G.softresolvefilepath = spy.new(ReturnValueFn(true))
                    end)

                    it("should print info", function()
                        assert.spy(SDK._Info).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Info).was_called(3)
                        assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path)
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils")
                        assert.spy(SDK._Info).was_called_with("Added world post initializer")
                    end)

                    it("shouldn't print error", function()
                        assert.spy(SDK._Error).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Error).was_not_called()
                    end)

                    it("should return true", function()
                        assert.is_true(SDK.Load(env, "yoursubdirectory/sdk"))
                    end)
                end)

                describe("when path is not resolved", function()
                    setup(function()
                        _G.softresolvefilepath = spy.new(ReturnValueFn(false))
                    end)

                    it("should print info", function()
                        assert.spy(SDK._Info).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Info).was_called(1)
                        assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path)
                    end)

                    it("should print error", function()
                        assert.spy(SDK._Error).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Error).was_called(1)
                        assert.spy(SDK._Error).was_called_with("SDK.Load():", "path not resolved")
                    end)

                    it("should return false", function()
                        assert.is_false(SDK.Load(env, "yoursubdirectory/sdk"))
                    end)
                end)
            end)
        end)

        describe("LoadModule()", function()
            describe("when name not passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Empty)
                    SDK.LoadModule(nil, "spec/empty")
                    assert.is_nil(SDK.Empty)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule(nil, "spec/empty"))
                end)
            end)

            describe("when path not passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Empty)
                    SDK.LoadModule("Empty")
                    assert.is_nil(SDK.Empty)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule("Empty"))
                end)
            end)

            describe("when both name and path are are passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Empty)
                    SDK.LoadModule()
                    assert.is_nil(SDK.Empty)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule())
                end)
            end)

            describe("when both name and path are passed", function()
                before_each(function()
                    SDK.Empty = nil
                end)

                it("should load package", function()
                    assert.is_nil(package.loaded["spec/empty"])
                    SDK.LoadModule("Empty", "spec/empty")
                    assert.is_not_nil(package.loaded["spec/empty"])
                end)

                it("should add SDK.[name]", function()
                    assert.is_nil(SDK.Empty)
                    SDK.LoadModule("Empty", "spec/empty")
                    assert.is_not_nil(SDK.Empty)
                end)

                it("should print info", function()
                    assert.spy(SDK._Info).was_not_called()
                    SDK.LoadModule("Empty", "spec/empty")
                    assert.spy(SDK._Info).was_called(1)
                    assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Empty")
                end)

                it("should return true", function()
                    assert.is_true(SDK.LoadModule("Empty", "spec/empty"))
                end)
            end)
        end)
    end)
end)
