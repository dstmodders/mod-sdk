require "busted.runner"()

describe("#sdk SDK", function()
    -- before_each initialization
    local SDK

    teardown(function()
        LoadSDK()
    end)

    before_each(function()
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

    describe("lifecycle", function()
        local Module

        before_each(function()
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
                    _G.TheWorld = {}
                end)

                it("should have submodules", function()
                    assert.is_table(SDK.Module.Submodule)
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
                        Module._foo = "bar"
                    end)

                    it("should debug error string", function()
                        AssertDebugError(function()
                            assert.is_not_nil(SDK.Module._foo)
                        end, "Field SDK.Module._foo shouldn't be used directly")
                    end)

                    it("should return a function that returns nil", function()
                        assert.is_function(SDK.Module._foo)
                        assert.is_nil(SDK.Module._foo())
                    end)
                end)

                describe("and referencing a function from a submodule", function()
                    it("should return a function value", function()
                        assert.is_function(SDK.Module.Submodule.Bar)
                        assert.is_equal("bar", SDK.Module.Submodule.Bar())
                    end)
                end)
            end)

            describe("and the required global is not available", function()
                before_each(function()
                    _G.TheWorld = nil
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        SDK.Module.Foo()
                    end, "Function SDK.Module.Foo() shouldn't be called when TheWorld global is "
                        .. "not available")
                end)

                it("should return a function that returns nil", function()
                    assert.is_function(SDK.Module.Foo)
                    assert.is_nil(SDK.Module.Foo())
                end)
            end)
        end)
    end)

    describe("general", function()
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
    end)

    describe("load", function()
        local _Error, _Info

        setup(function()
            _Error = SDK._Error
            _Info = SDK._Info
        end)

        teardown(function()
            SDK._Error = _Error
            SDK._Info = _Info
        end)

        before_each(function()
            SDK._Error = spy.new(Empty)
            SDK._Info = spy.new(Empty)
        end)

        describe("Load()", function()
            describe("when env is not passed", function()
                it("should print error", function()
                    assert.spy(SDK._Error).was_not_called()
                    SDK.Load()
                    assert.spy(SDK._Error).was_called(1)
                    assert.spy(SDK._Error).was_called_with("SDK.Load():", "required env not passed")
                end)

                TestReturnFalse(function()
                    return SDK.Load()
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

                TestReturnFalse(function()
                    return SDK.Load({})
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

                    TestReturnFalse(function()
                        return SDK.Load(env, "yoursubdirectory/sdk")
                    end)
                end)

                describe("when path is resolved", function()
                    setup(function()
                        _G.softresolvefilepath = spy.new(ReturnValueFn(true))
                    end)

                    teardown(function()
                        LoadSDK()
                    end)

                    before_each(function()
                        SDK.UnloadAllModules()
                        SDK._Info:clear()
                    end)

                    local function TestLoad(...)
                        local args = { ... }
                        it("shouldn't print error", function()
                            assert.spy(SDK._Error).was_not_called()
                            SDK.Load(unpack(args))
                            assert.spy(SDK._Error).was_not_called()
                        end)

                        it("should return self", function()
                            AssertReturnSelf(SDK, "Load", unpack(args))
                        end)
                    end

                    local function TestPrintInfoAll(fn)
                        it("should print info", function()
                            assert.spy(SDK._Info).was_not_called()
                            fn()
                            assert.spy(SDK._Info).was_called(35)
                            assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path_full)
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Config")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Console")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Constant")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Debug")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.DebugUpvalue")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Dump")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Entity")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.FrontEnd")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Input")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Method")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.MiniMap")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.ModMain")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.PersistentData")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player.Attribute")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player.Craft")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player.Inventory")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote.Player")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote.World")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.RPC")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.TemporaryData")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Test")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Thread")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Time")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Chain")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Table")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Value")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.SaveData")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.Season")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.Weather")
                            assert.spy(SDK._Info).was_called_with("Added world post initializer")
                        end)
                    end

                    describe("and no modules are passed", function()
                        TestLoad(env, "yoursubdirectory/sdk")
                        TestPrintInfoAll(function()
                            SDK.Load(env, "yoursubdirectory/sdk")
                        end)
                    end)

                    describe("and all modules are passed", function()
                        local modules = {
                            "Config",
                            "Console",
                            "Constant",
                            "Debug",
                            "DebugUpvalue",
                            "Dump",
                            "Entity",
                            "FrontEnd",
                            "Input",
                            "Method",
                            "MiniMap",
                            "ModMain",
                            "PersistentData",
                            Player = {
                                "Attribute",
                                "Craft",
                                "Inventory",
                            },
                            Remote = {
                                "Player",
                                "World",
                            },
                            "RPC",
                            "Test",
                            "TemporaryData",
                            "Thread",
                            "Time",
                            World = {
                                "SaveData",
                                "Season",
                                "Weather"
                            },
                        }

                        TestLoad(env, "yoursubdirectory/sdk", modules)
                        TestPrintInfoAll(function()
                            SDK.Load(env, "yoursubdirectory/sdk", modules)
                        end)
                    end)

                    describe("and only some modules/submodules are passed", function()
                        local modules = {
                            Player = {
                                path = "sdk/player",
                                submodules = {
                                    Attribute = "sdk/player/attribute",
                                },
                            },
                            Remote = {},
                            "RPC",
                            "Test",
                            "Thread",
                            "World",
                        }

                        TestLoad(env, "yoursubdirectory/sdk", modules)

                        it("should print info", function()
                            assert.spy(SDK._Info).was_not_called()
                            SDK.Load(env, "yoursubdirectory/sdk", modules)
                            assert.spy(SDK._Info).was_called(16)
                            assert.spy(SDK._Info).was_called_with("Loading SDK:", SDK.path_full)
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Player.Attribute")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Remote")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.RPC")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Test")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Thread")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Chain")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Table")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Utils.Value")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.SaveData")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.Season")
                            assert.spy(SDK._Info).was_called_with("Loaded", "SDK.World.Weather")
                            assert.spy(SDK._Info).was_called_with("Added world post initializer")
                        end)
                    end)
                end)
            end)
        end)

        describe("LoadModule()", function()
            after_each(function()
                SDK.UnloadModule("Module")
            end)

            local function TestAddModule(fn)
                it("should load package", function()
                    assert.is_nil(package.loaded["spec/module"])
                    fn()
                    assert.is_not_nil(package.loaded["spec/module"])
                end)

                it("should add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    fn()
                    assert.is_not_nil(SDK.Module)
                end)

                TestReturnTrue(fn)
            end

            local function TestNoAddModule(fn)
                it("shouldn't add SDK.[name]", function()
                    assert.is_nil(SDK.Module)
                    fn()
                    assert.is_nil(SDK.Module)
                end)

                TestReturnFalse(fn)
            end

            local function TestPrintInfoSubmodules(fn)
                it("should print info", function()
                    assert.spy(SDK._Info).was_not_called()
                    fn()
                    assert.spy(SDK._Info).was_called(2)
                    assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Module.Submodule")
                    assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Module")
                end)
            end

            describe("when name is not passed", function()
                TestNoAddModule(function()
                    return SDK.LoadModule(nil, "spec/module")
                end)
            end)

            describe("when path is not passed", function()
                TestNoAddModule(function()
                    return SDK.LoadModule("Module")
                end)
            end)

            describe("when both name and path are are passed", function()
                TestNoAddModule(function()
                    return SDK.LoadModule()
                end)
            end)

            describe("when both name and path are passed", function()
                describe("and no submodules are passed", function()
                    TestAddModule(function()
                        return SDK.LoadModule("Module", "spec/module")
                    end)

                    TestPrintInfoSubmodules(function()
                        SDK.LoadModule("Module", "spec/module")
                    end)
                end)

                describe("and submodules are passed", function()
                    TestAddModule(function()
                        return SDK.LoadModule("Module", "spec/module", {
                            Submodule = "spec/submodule",
                        })
                    end)

                    TestPrintInfoSubmodules(function()
                        SDK.LoadModule("Module", "spec/module", { Submodule = "spec/submodule" })
                    end)
                end)

                describe("and empty submodules are passed", function()
                    TestAddModule(function()
                        return SDK.LoadModule("Module", "spec/module", {})
                    end)

                    it("should print info", function()
                        assert.spy(SDK._Info).was_not_called()
                        SDK.LoadModule("Module", "spec/module", {})
                        assert.spy(SDK._Info).was_called(1)
                        assert.spy(SDK._Info).was_called_with("Loaded", "SDK.Module")
                    end)
                end)
            end)
        end)
    end)

    describe("sanitize", function()
        describe("SanitizeModules()", function()
            local modules = {
                Config = {
                    path = "sdk/config",
                },
                Console = {
                    path = "sdk/console",
                },
                Constant = {
                    path = "sdk/constant",
                },
                Debug = {
                    path = "sdk/debug",
                },
                DebugUpvalue = {
                    path = "sdk/debugupvalue",
                },
                Dump = {
                    path = "sdk/dump",
                },
                Entity = {
                    path = "sdk/entity",
                },
                FrontEnd = {
                    path = "sdk/frontend",
                },
                Input = {
                    path = "sdk/input",
                },
                Method = {
                    path = "sdk/method",
                },
                MiniMap = {
                    path = "sdk/minimap",
                },
                ModMain = {
                    path = "sdk/modmain",
                },
                PersistentData = {
                    path = "sdk/persistentdata",
                },
                Player = {
                    path = "sdk/player",
                    submodules = {
                        Attribute = {
                            path = "sdk/player/attribute",
                        },
                        Craft = {
                            path = "sdk/player/craft",
                        },
                        Inventory = {
                            path = "sdk/player/inventory",
                        },
                    },
                },
                Remote = {
                    path = "sdk/remote",
                    submodules = {
                        Player = {
                            path = "sdk/remote/player",
                        },
                        World = {
                            path = "sdk/remote/world",
                        },
                    },
                },
                RPC = {
                    path = "sdk/rpc",
                },
                TemporaryData = {
                    path = "sdk/temporarydata",
                },
                Test = {
                    path = "sdk/test",
                },
                Thread = {
                    path = "sdk/thread",
                },
                World = {
                    path = "sdk/world",
                    submodules = {
                        SaveData = {
                            path = "sdk/world/savedata",
                        },
                        Season = {
                            path = "sdk/world/season",
                        },
                        Weather = {
                            path = "sdk/world/weather",
                        },
                    },
                },
            }

            local function TestReturnSanitized(fn)
                it("should return sanitized modules", function()
                    assert.is_same(modules, fn())
                end)
            end

            describe("when modules as options are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeModules(modules)
                end)
            end)

            describe("when modules as names are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeModules({
                        "Config",
                        "Console",
                        "Constant",
                        "Debug",
                        "DebugUpvalue",
                        "Dump",
                        "Entity",
                        "FrontEnd",
                        "Input",
                        "Method",
                        "MiniMap",
                        "ModMain",
                        "PersistentData",
                        Player = {
                            "Attribute",
                            "Craft",
                            "Inventory",
                        },
                        Remote = {
                            "Player",
                            "World",
                        },
                        "RPC",
                        "TemporaryData",
                        "Test",
                        "Thread",
                        World = {
                            "SaveData",
                            "Season",
                            "Weather"
                        },
                    })
                end)
            end)

            describe("when modules as name and path pairs are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeModules({
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
                        MiniMap = "sdk/minimap",
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
                            },
                        },
                        RPC = "sdk/rpc",
                        TemporaryData = "sdk/temporarydata",
                        Test = "sdk/test",
                        Thread = "sdk/thread",
                        World = {
                            path = "sdk/world",
                            submodules = {
                                SaveData = "sdk/world/savedata",
                                Season = "sdk/world/season",
                                Weather = "sdk/world/weather",
                            },
                        },
                    })
                end)
            end)
        end)

        describe("SanitizeSubmodules()", function()
            local submodules = {
                Attribute = {
                    path = "sdk/player/attribute",
                },
                Craft = {
                    path = "sdk/player/craft",
                },
                Inventory = {
                    path = "sdk/player/inventory",
                },
            }

            local function TestReturnSanitized(fn)
                it("should return sanitized submodules", function()
                    assert.is_same(submodules, fn())
                end)
            end

            describe("when submodules are not passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeSubmodules("Player")
                end)
            end)

            describe("when submodules as options are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeSubmodules("Player", submodules)
                end)
            end)

            describe("when submodules as names are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeSubmodules("Player", {
                        "Attribute",
                        "Craft",
                        "Inventory",
                    })
                end)
            end)

            describe("when submodules as name and path pairs are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeSubmodules("Player", {
                        Attribute = "sdk/player/attribute",
                        Craft = "sdk/player/craft",
                        Inventory = "sdk/player/inventory",
                    })
                end)
            end)

            describe("when submodules as mixed are passed", function()
                TestReturnSanitized(function()
                    return SDK.SanitizeSubmodules("Player", {
                        "Attribute",
                        Craft = "sdk/player/craft",
                        Inventory = {
                            path = "sdk/player/inventory",
                        },
                    })
                end)
            end)
        end)
    end)

    describe("internal", function()
        local _fn

        setup(function()
            _fn = _G.print
        end)

        teardown(function()
            _G.print = _fn
            SDK.SetIsSilent(true)
        end)

        before_each(function()
            _G.print = spy.new(Empty)
            SDK.SetIsSilent(false)
        end)

        describe("_Error()", function()
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

        describe("_Info()", function()
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
    end)
end)
