require "busted.runner"()

describe("#sdk SDK", function()
    -- setup
    local match

    -- before_each initialization
    local SDK

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        -- globals
        _G.InGamePlay = nil
        _G.SetPause = nil
        _G.ThePlayer = nil
        _G.TheSim = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.InGamePlay = spy.new(ReturnValueFn(false))
        _G.SetPause = spy.new(Empty)
        _G.ThePlayer = {}

        _G.TheSim = mock({
            GetTimeScale = ReturnValueFn(1),
            SetTimeScale = Empty,
        })

        _G.TheWorld = {
            ismastersim = false,
        }

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Debug")

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    teardown(function()
        LoadSDK()
    end)

    local function AssertDebugErrorCalls(fn, calls, ...)
        if SDK.IsLoaded("Debug") then
            assert.spy(SDK.Debug.Error).was_not_called()
            fn()
            assert.spy(SDK.Debug.Error).was_called(calls)
            if calls > 0 then
                assert.spy(SDK.Debug.Error).was_called_with(...)
            end
        end
    end

    local function AssertDebugError(fn, ...)
        AssertDebugErrorCalls(fn, 1, ...)
    end

    local function AssertDebugString(fn, ...)
        if SDK.IsLoaded("Debug") then
            assert.spy(SDK.Debug.String).was_not_called()
            fn()
            assert.spy(SDK.Debug.String).was_called(1)
            assert.spy(SDK.Debug.String).was_called_with(...)
        end
    end

    describe("lifecycle", function()
        local Module

        before_each(function()
            -- initialization
            SDK.LoadModule("Module", "spec/module")
            Module = require("spec/module")
        end)

        after_each(function()
            SDK.UnloadModule("Module")
        end)

        describe("when calling a module through SDK", function()
            it("should have a module field pointing to the module itself", function()
                assert.is_equal(Module, SDK.Module.module)
            end)

            it("should have Has() which returns if a field/function exists", function()
                assert.is_function(SDK.Module.Has)
                assert.is_true(SDK.Module.Has("_DoInit"))
                assert.is_false(SDK.Module.Has("FooBar"))
            end)

            describe("and the required global is available", function()
                before_each(function()
                    _G.ThePlayer = {}
                end)

                describe("when referencing an existent function", function()
                    it("shouldn't debug error string", function()
                        AssertDebugErrorCalls(function()
                            SDK.Module.Foo()
                        end, 0)
                    end)

                    it("should return a function itself", function()
                        assert.is_function(SDK.Module.Foo)
                        assert.is_equal("bar", SDK.Module.Foo())
                    end)
                end)

                describe("and referencing a non-existent function", function()
                    it("should debug error string", function()
                        AssertDebugError(function()
                            SDK.Module.FooBar()
                        end, "Function or field SDK.Module.FooBar doesn't exist")
                    end)

                    it("should return a function that returns nil", function()
                        assert.is_function(SDK.Module.FooBar)
                        assert.is_nil(SDK.Module.FooBar())
                    end)
                end)

                describe("and referencing an internal function", function()
                    it("should debug error string", function()
                        AssertDebugError(function()
                            SDK.Module._DoInit()
                        end, "Function SDK.Module._DoInit() shouldn't be used directly")
                    end)

                    it("should return a function that returns nil", function()
                        assert.is_function(SDK.Module._DoInit)
                        assert.is_nil(SDK.Module._DoInit())
                    end)
                end)

                describe("and referencing an internal field", function()
                    before_each(function()
                        Module.foo = "bar"
                    end)

                    it("should debug error string", function()
                        AssertDebugError(function()
                            assert.is_not_nil(SDK.Module.foo)
                        end, "Field SDK.Module.foo shouldn't be used directly")
                    end)

                    it("should return a function that returns nil", function()
                        assert.is_function(SDK.Module.foo)
                        assert.is_nil(SDK.Module.foo())
                    end)
                end)
            end)

            describe("and the required global is not available", function()
                before_each(function()
                    _G.ThePlayer = nil
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        SDK.Module.Foo()
                    end, "Function SDK.Module.Foo() shouldn't be called when ThePlayer global is "
                        .. "not available")
                end)

                it("should return a function that returns nil", function()
                    assert.is_function(SDK.Module.Foo)
                    assert.is_nil(SDK.Module.Foo())
                end)
            end)
        end)
    end)

    describe("internal", function()
        local _print

        setup(function()
            _print = _G.print
        end)

        teardown(function()
            _G.print = _print
            SDK.SetIsSilent(true)
        end)

        before_each(function()
            _G.print = spy.new(Empty)
            SDK.SetIsSilent(false)
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
                    path_full = "GetPathFull",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(SDK, field, getter)
                    end)
                end
            end)
        end)

        describe("Load()", function()
            describe("when env is not passed", function()
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

            describe("when path is not passed", function()
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
                    _G.softresolvefilepath = spy.new(ReturnValueFn(false))
                end)

                teardown(function()
                    _G.softresolvefilepath = nil
                end)

                before_each(function()
                    env = mock({
                        modname = "dst-mod-sdk",
                        AddPrefabPostInit = Empty,
                    })

                    SDK.env = nil
                    SDK.path = nil
                    SDK.path_full = nil
                end)

                it("should add SDK.env", function()
                    assert.is_nil(SDK.env)
                    SDK.Load(env, "yoursubdirectory/sdk")
                    assert.is_equal(env, SDK.env)
                end)

                it("should add SDK.path", function()
                    assert.is_nil(SDK.path)
                    SDK.Load(env, "yoursubdirectory/sdk")
                    assert.is_equal("yoursubdirectory/sdk/", SDK.path)
                end)

                it("should add SDK.path_full", function()
                    assert.is_nil(SDK.path_full)
                    SDK.Load(env, "yoursubdirectory/sdk")
                    assert.is_equal("dst-mod-sdk/scripts/yoursubdirectory/sdk/", SDK.path_full)
                end)

                describe("when path is resolved", function()
                    setup(function()
                        _G.softresolvefilepath = spy.new(ReturnValueFn(true))
                        SDK.UnloadAllModules()
                    end)

                    teardown(function()
                        LoadSDK()
                    end)

                    it("should print info", function()
                        assert.spy(SDK._Info).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Info).was_called(27)
                        assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path_full)
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Value")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Chain")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Table")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Inventory")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Console")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.ModMain")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Thread")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Constant")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Entity")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.RPC")
                        assert.spy(SDK._Info).was_called_with("Unloaded", "SDK.Debug")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Debug")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.DebugUpvalue")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote.World")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote.Player")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.PersistentData")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Config")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Test")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Input")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Method")
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Dump")
                        assert.spy(SDK._Info).was_called_with("Added world post initializer")
                    end)

                    it("shouldn't print error", function()
                        assert.spy(SDK._Error).was_not_called()
                        SDK.Load(env, "yoursubdirectory/sdk")
                        assert.spy(SDK._Error).was_not_called()
                    end)

                    it("should return self", function()
                        assert.is_equal(SDK, SDK.Load(env, "yoursubdirectory/sdk"))
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
                        assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path_full)
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
            after_each(function()
                SDK.UnloadModule("Module")
            end)

            describe("when name is not passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    SDK.LoadModule(nil, "spec/module")
                    assert.is_nil(SDK.Module)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule(nil, "spec/module"))
                end)
            end)

            describe("when path is not passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    SDK.LoadModule("Module")
                    assert.is_nil(SDK.Module)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule("Module"))
                end)
            end)

            describe("when both name and path are are passed", function()
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    SDK.LoadModule()
                    assert.is_nil(SDK.Module)
                end)

                it("should return false", function()
                    assert.is_false(SDK.LoadModule())
                end)
            end)

            describe("when both name and path are passed", function()
                before_each(function()
                    SDK.Module = nil
                end)

                it("should load package", function()
                    assert.is_nil(package.loaded["spec/module"])
                    SDK.LoadModule("Module", "spec/module")
                    assert.is_not_nil(package.loaded["spec/module"])
                end)

                it("should add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    SDK.LoadModule("Module", "spec/module")
                    assert.is_not_nil(SDK.Module)
                end)

                it("should print info", function()
                    assert.spy(SDK._Info).was_not_called()
                    SDK.LoadModule("Module", "spec/module")
                    assert.spy(SDK._Info).was_called(1)
                    assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Module")
                end)

                it("should return true", function()
                    assert.is_true(SDK.LoadModule("Module", "spec/module"))
                end)
            end)
        end)
    end)

    describe("pausing", function()
        describe("IsPaused()", function()
            describe("when TheSim:GetTimeScale() returns 0", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(0))
                end)

                it("should return true", function()
                    assert.is_true(SDK.IsPaused())
                end)
            end)

            describe("when TheSim:GetTimeScale() returns a non-0 value", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(1))
                end)

                it("should return false", function()
                    assert.is_false(SDK.IsPaused())
                end)
            end)
        end)

        describe("Pause()", function()
            local function TestLocal()
                it("should set SDK.time_scale_prev field", function()
                    SDK.time_scale_prev = nil
                    SDK.Pause()
                    assert.is_equal(1, SDK.time_scale_prev)
                end)

                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    SDK.Pause()
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                        match.is_ref(_G.TheSim),
                        0
                    )
                end)

                it("should call SetPause()", function()
                    assert.spy(_G.SetPause).was_not_called()
                    SDK.Pause()
                    assert.spy(_G.SetPause).was_called(1)
                    assert.spy(_G.SetPause).was_called_with(true, "console")
                end)

                it("should return true", function()
                    assert.is_true(SDK.Pause())
                end)
            end

            describe("when the game is paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(true))
                    SDK.Debug.Error = spy.new(ReturnValueFn(true))
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        SDK.Pause()
                    end, "SDK.Pause():", "Game is already paused")
                end)

                it("should return false", function()
                    assert.is_false(SDK.Pause())
                end)
            end)

            describe("when the game is not paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(false))
                end)

                describe("and in a game play", function()
                    before_each(function()
                        _G.InGamePlay = spy.new(ReturnValueFn(true))
                    end)

                    describe("and is master simulation", function()
                        before_each(function()
                            _G.TheWorld.ismastersim = true
                        end)

                        TestLocal()
                    end)

                    describe("and is non-master simulation", function()
                        setup(function()
                            SDK.LoadModule("Remote")
                        end)

                        teardown(function()
                            SDK.UnloadModule("Remote")
                        end)

                        before_each(function()
                            _G.TheWorld.ismastersim = false
                        end)

                        describe("and SDK.Remote.World.SetTimeScale() returns false", function()
                            before_each(function()
                                SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call SDK.Remote.World.SetTimeScale()", function()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                                SDK.Pause()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(0)
                            end)

                            it("should debug string", function()
                                AssertDebugString(function()
                                    SDK.Pause()
                                end, "Pause game")
                            end)

                            TestLocal()
                        end)

                        describe("and SDK.Remote.World.SetTimeScale() returns true", function()
                            before_each(function()
                                SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call SDK.Remote.World.SetTimeScale()", function()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                                SDK.Pause()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(0)
                            end)

                            it("should debug strings", function()
                                if SDK.IsLoaded("Debug") then
                                    assert.spy(SDK.Debug.String).was_not_called()
                                    SDK.Pause()
                                    assert.spy(SDK.Debug.String).was_called(2)
                                    assert.spy(SDK.Debug.String).was_called_with("Pause game")
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[notice]",
                                        "SDK.Pause():",
                                        "Other players will experience a client-side time scale "
                                            .. "mismatch"
                                    )
                                end
                            end)

                            TestLocal()
                        end)
                    end)
                end)
            end)
        end)

        describe("Resume()", function()
            local function TestLocal()
                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    SDK.Resume()
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                        match.is_ref(_G.TheSim),
                        SDK.time_scale_prev
                    )
                end)

                it("should call SetPause()", function()
                    assert.spy(_G.SetPause).was_not_called()
                    SDK.Resume()
                    assert.spy(_G.SetPause).was_called(1)
                    assert.spy(_G.SetPause).was_called_with(false, "console")
                end)

                it("should return true", function()
                    assert.is_true(SDK.Resume())
                end)
            end

            describe("when the game is not paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(false))
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        SDK.Resume()
                    end, "SDK.Resume():", "Game is already resumed")
                end)

                it("should return false", function()
                    assert.is_false(SDK.Resume())
                end)
            end)

            describe("when the game is paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(true))
                end)

                describe("and in a game play", function()
                    before_each(function()
                        _G.InGamePlay = spy.new(ReturnValueFn(true))
                    end)

                    describe("and is master simulation", function()
                        before_each(function()
                            _G.TheWorld.ismastersim = true
                        end)

                        it("should debug string", function()
                            AssertDebugString(function()
                                SDK.Resume()
                            end, "Resume game")
                        end)

                        TestLocal()
                    end)

                    describe("and is non-master simulation", function()
                        setup(function()
                            SDK.LoadModule("Remote")
                        end)

                        teardown(function()
                            SDK.UnloadModule("Remote")
                        end)

                        before_each(function()
                            _G.TheWorld.ismastersim = false
                        end)

                        describe("and SDK.Remote.World.SetTimeScale() returns false", function()
                            before_each(function()
                                SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call SDK.Remote.World.SetTimeScale()", function()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                                SDK.Resume()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(
                                    SDK.time_scale_prev
                                )
                            end)

                            it("should debug string", function()
                                AssertDebugString(function()
                                    SDK.Resume()
                                end, "Resume game")
                            end)

                            TestLocal()
                        end)

                        describe("and SDK.Remote.World.SetTimeScale() returns true", function()
                            before_each(function()
                                SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call SDK.Remote.World.SetTimeScale()", function()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                                SDK.Resume()
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(
                                    SDK.time_scale_prev
                                )
                            end)

                            it("should debug strings", function()
                                if SDK.IsLoaded("Debug") then
                                    assert.spy(SDK.Debug.String).was_not_called()
                                    SDK.Resume()
                                    assert.spy(SDK.Debug.String).was_called(2)
                                    assert.spy(SDK.Debug.String).was_called_with("Resume game")
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[notice]",
                                        "SDK.Resume():",
                                        "Other players will experience a client-side time scale "
                                            .. "mismatch"
                                    )
                                end
                            end)

                            TestLocal()
                        end)
                    end)
                end)
            end)
        end)

        describe("TogglePause()", function()
            before_each(function()
                SDK.Pause = spy.new(Empty)
                SDK.Resume = spy.new(Empty)
            end)

            describe("when the world is paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(true))
                end)

                it("should call SDK.Resume()", function()
                    assert.spy(SDK.Resume).was_not_called()
                    SDK.TogglePause()
                    assert.spy(SDK.Resume).was_called(1)
                    assert.spy(SDK.Resume).was_called_with()
                end)

                it("shouldn't call SDK.Pause()", function()
                    assert.spy(SDK.Pause).was_not_called()
                    SDK.TogglePause()
                    assert.spy(SDK.Pause).was_not_called()
                end)
            end)

            describe("when the world is not paused", function()
                before_each(function()
                    SDK.IsPaused = spy.new(ReturnValueFn(false))
                end)

                it("should call SDK.Pause()", function()
                    assert.spy(SDK.Pause).was_not_called()
                    SDK.TogglePause()
                    assert.spy(SDK.Pause).was_called(1)
                    assert.spy(SDK.Pause).was_called_with()
                end)

                it("shouldn't call SDK.Resume()", function()
                    assert.spy(SDK.Resume).was_not_called()
                    SDK.TogglePause()
                    assert.spy(SDK.Resume).was_not_called()
                end)
            end)
        end)
    end)
end)
