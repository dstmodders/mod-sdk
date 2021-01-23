require "busted.runner"()

describe("#sdk SDK.World", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local World

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        -- globals
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendWorldRollbackRequestToServer = Empty,
        })

        _G.ThePlayer = {}

        _G.TheWorld = mock({
            meta = {
                saveversion = "5.031",
                seed = "1574459949",
            },
            net = {
                components = {},
            },
            state = {},
            topology = {
                ids = {
                    "Forest hunters:6:WalrusHut_Grassy",
                },
            },
            HasTag = function(_, tag)
                return tag == "forest"
            end
        })

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        SDK.LoadModule("World")
        World = require "yoursubdirectory/sdk/sdk/world"

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        _G.AssertDebugErrorInvalidArg(fn, World, fn_name, arg_name, explanation)
    end

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.World." .. fn_name .. "():", ...)
    end

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[world]", ...)
    end

    local function TestDebugStringCalls(fn, calls, ...)
        _G.TestDebugStringCalls(fn, calls, "[world]", ...)
    end

    describe("general", function()
        describe("should have a", function()
            describe("getter", function()
                local getters = {
                    nr_of_walrus_camps = "GetNrOfWalrusCamps",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(World, field, getter)
                    end)
                end
            end)
        end)

        describe("GetMeta()", function()
            describe("when no name is passed", function()
                it("should return TheWorld.meta", function()
                    assert.is_equal(_G.TheWorld.meta, World.GetMeta())
                end)
            end)

            describe("when the name is passed", function()
                it("should return TheWorld.meta field value", function()
                    assert.is_equal(_G.TheWorld.meta.saveversion, World.GetMeta("saveversion"))
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetMeta("saveversion"))
                    end, _G.TheWorld, "meta", "saveversion")
                end)
            end)
        end)

        describe("GetSeed()", function()
            it("should return TheWorld.meta.seed", function()
                assert.is_equal(_G.TheWorld.meta.seed, World.GetSeed())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetSeed())
                    end, _G.TheWorld, "meta", "seed")
                end)
            end)
        end)

        describe("IsPointPassable()", function()
            local pt

            local fn = function()
                return World.IsPointPassable(pt)
            end

            before_each(function()
                _G.TheWorld = {
                    Map = {
                        IsPassableAtPoint = spy.new(ReturnValueFn(true)),
                    },
                }

                pt = {
                    Get = spy.new(ReturnValuesFn(1, 0, -1)),
                }
            end)

            describe("when some passed world fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(fn())
                    end, _G.TheWorld, "Map", "IsPassableAtPoint")
                end)
            end)

            describe("when some passed pos fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(fn())
                    end, pt, "Get")
                end)
            end)

            it("should call pos:Get()", function()
                assert.spy(pt.Get).was_called(0)
                fn()
                assert.spy(pt.Get).was_called(1)
                assert.spy(pt.Get).was_called_with(match.is_ref(pt))
            end)

            it("should call world.Map:IsPassableAtPoint()", function()
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(0)
                fn()
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(1)
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called_with(
                    match.is_ref(_G.TheWorld.Map),
                    1,
                    0,
                    -1
                )
            end)

            TestReturnTrue(fn)
        end)

        describe("Rollback()", function()
            describe("when invalid days are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        World.Rollback("foo")
                    end, "Rollback", "days", "must be an unsigned integer")
                end)

                TestReturnFalse(function()
                    return World.Rollback("foo")
                end)
            end)

            describe("when valid days are passed", function()
                local fn = function()
                    return World.Rollback(1)
                end

                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Rollback:", "1 day")

                    it("should call TheNet:SendWorldRollbackRequestToServer()", function()
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        fn()
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called(1)
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called_with(
                            match.is_ref(_G.TheNet),
                            1
                        )
                    end)

                    TestReturnTrue(fn)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    describe("and SDK.Remote.World.Rollback() returns false", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.Rollback
                        end)

                        before_each(function()
                            SDK.Remote.World.Rollback = spy.new(ReturnValueFn(false))
                        end)

                        teardown(function()
                            SDK.Remote.World.Rollback = _fn
                        end)

                        it("should call SDK.Remote.World.Rollback()", function()
                            assert.spy(SDK.Remote.World.Rollback).was_not_called()
                            fn()
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheNet:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            fn()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        TestReturnFalse(fn)
                    end)

                    describe("and SDK.Remote.World.Rollback() returns true", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.Rollback
                        end)

                        before_each(function()
                            SDK.Remote.World.Rollback = spy.new(ReturnValueFn(true))
                        end)

                        teardown(function()
                            SDK.Remote.World.Rollback = _fn
                        end)

                        it("should call SDK.Remote.World.Rollback()", function()
                            assert.spy(SDK.Remote.World.Rollback).was_not_called()
                            fn()
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheNet:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            fn()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        TestReturnTrue(fn)
                    end)
                end)
            end)
        end)
    end)

    describe("phase", function()
        describe("GetPhase()", function()
            before_each(function()
                _G.TheWorld.state.cavephase = "dusk"
                _G.TheWorld.state.phase = "day"
            end)

            describe("when in the cave", function()
                before_each(function()
                    World.IsCave = ReturnValueFn(true)
                end)

                it("should return cave phase", function()
                    assert.equal("dusk", World.GetPhase())
                end)
            end)

            describe("when in the cave", function()
                before_each(function()
                    World.IsCave = ReturnValueFn(false)
                end)

                it("should return phase", function()
                    assert.equal("day", World.GetPhase())
                end)
            end)
        end)

        describe("GetPhaseNext()", function()
            describe("when the phase is passed", function()
                it("should return the next phase", function()
                    assert.is_equal("dusk", World.GetPhaseNext("day"))
                    assert.is_equal("night", World.GetPhaseNext("dusk"))
                    assert.is_equal("day", World.GetPhaseNext("night"))
                end)
            end)

            describe("when the phase is not passed", function()
                TestReturnNil(function()
                    return World.GetPhaseNext()
                end)
            end)
        end)

        describe("GetTimeUntilPhase()", function()
            local fn = function()
                return World.GetTimeUntilPhase("day")
            end

            before_each(function()
                _G.TheWorld.net.components.clock = {
                    GetTimeUntilPhase = spy.new(ReturnValueFn(10)),
                }
            end)

            it("should call TheWorld.net.components.clock:GetTimeUntilPhase()", function()
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_not_called()
                fn()
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called(1)
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called_with(
                    match.is_ref(_G.TheWorld.net.components.clock),
                    "day"
                )
            end)

            it("should return TheWorld.net.components.clock:GetTimeUntilPhase() value", function()
                assert.is_equal(_G.TheWorld.net.components.clock:GetTimeUntilPhase(), fn())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(fn())
                    end, _G.TheWorld, "net", "components", "clock")
                end)
            end)
        end)
    end)

    describe("internal", function()
        describe("_GuessNrOfWalrusCamps()", function()
            local fn = function()
                return World._GuessNrOfWalrusCamps()
            end

            after_each(function()
                World.nr_of_walrus_camps = 0
            end)

            describe("when some TheWorld.topology.ids chain fields are missing", function()
                before_each(function()
                    _G.TheWorld.topology.ids = nil
                end)

                TestDebugError(fn, "_GuessNrOfWalrusCamps", "No world topology IDs found")

                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(fn())
                    end, _G.TheWorld, "topology", "ids")
                end)
            end)

            describe("when a single Walrus Camp", function()
                before_each(function()
                    _G.TheWorld.topology.ids = {
                        "Forest hunters:6:WalrusHut_Grassy",
                    }
                end)

                it("should set World.nr_of_walrus_camps value", function()
                    assert.is_equal(0, World.nr_of_walrus_camps)
                    fn()
                    assert.is_equal(1, World.nr_of_walrus_camps)
                end)

                TestDebugStringCalls(fn, 2, "Guessing the number of Walrus Camps...")
                TestDebugStringCalls(fn, 2, "Found", "1", "Walrus Camp")
            end)

            describe("when multiple Walrus Camps", function()
                before_each(function()
                    _G.TheWorld.topology.ids = {
                        "Forest hunters:6:WalrusHut_Grassy",
                        "The hunters:4:WalrusHut_Plains",
                        "The hunters:5:WalrusHut_Rocky",
                        "The hunters:8:WalrusHut_Grassy",
                    }
                end)

                it("should set World.nr_of_walrus_camps value", function()
                    assert.is_equal(0, World.nr_of_walrus_camps)
                    fn()
                    assert.is_equal(4, World.nr_of_walrus_camps)
                end)

                TestDebugStringCalls(fn, 2, "Guessing the number of Walrus Camps...")
                TestDebugStringCalls(fn, 2, "Found", "4", "Walrus Camps")
            end)
        end)
    end)
end)
