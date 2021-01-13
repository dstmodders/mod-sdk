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
        _G.SetPause = nil
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.SetPause = spy.new(Empty)

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

    describe("general", function()
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
                        assert.is_false(World.IsPointPassable(pt))
                    end, _G.TheWorld, "Map", "IsPassableAtPoint")
                end)
            end)

            describe("when some passed pos fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(World.IsPointPassable(pt))
                    end, pt, "Get")
                end)
            end)

            it("should call pos:Get()", function()
                assert.spy(pt.Get).was_called(0)
                World.IsPointPassable(pt)
                assert.spy(pt.Get).was_called(1)
                assert.spy(pt.Get).was_called_with(match.is_ref(pt))
            end)

            it("should call world.Map:IsPassableAtPoint()", function()
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(0)
                World.IsPointPassable(pt)
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(1)
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called_with(
                    match.is_ref(_G.TheWorld.Map),
                    1,
                    0,
                    -1
                )
            end)

            it("should return true", function()
                assert.is_true(World.IsPointPassable(pt))
            end)
        end)

        describe("Rollback()", function()
            describe("when invalid days are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        World.Rollback("foo")
                    end, "Rollback", "days", "must be an unsigned integer")
                end)

                it("should return false", function()
                    assert.is_false(World.Rollback("foo"))
                end)
            end)

            describe("when valid days are passed", function()
                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    it("should debug string", function()
                        AssertDebugString(function()
                            World.Rollback(1)
                        end, "[world]", "Rollback:", "1 day")
                    end)

                    it("should call TheNet:SendWorldRollbackRequestToServer()", function()
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        World.Rollback(1)
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called(1)
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called_with(
                            match.is_ref(_G.TheNet),
                            1
                        )
                    end)

                    it("should return true", function()
                        assert.is_true(World.Rollback(1))
                    end)
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
                            World.Rollback(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheNet:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            World.Rollback(1)
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        it("should return false", function()
                            assert.is_false(World.Rollback(1))
                        end)
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
                            World.Rollback(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheNet:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            World.Rollback(1)
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        it("should return true", function()
                            assert.is_true(World.Rollback(1))
                        end)
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
                it("should return nil", function()
                    assert.is_nil(World.GetPhaseNext())
                end)
            end)
        end)

        describe("GetTimeUntilPhase()", function()
            before_each(function()
                _G.TheWorld.net.components.clock = {
                    GetTimeUntilPhase = spy.new(ReturnValueFn(10)),
                }
            end)

            it("should call TheWorld.net.components.clock:GetTimeUntilPhase()", function()
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_not_called()
                World.GetTimeUntilPhase("day")
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called(1)
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called_with(
                    match.is_ref(_G.TheWorld.net.components.clock),
                    "day"
                )
            end)

            it("should return TheWorld.net.components.clock:GetTimeUntilPhase() value", function()
                assert.is_equal(
                    _G.TheWorld.net.components.clock:GetTimeUntilPhase(),
                    World.GetTimeUntilPhase("day")
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetTimeUntilPhase())
                    end, _G.TheWorld, "net", "components", "clock")
                end)
            end)
        end)
    end)

    describe("weather", function()
        describe("GetWeatherComponent()", function()
            describe("when in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.caveweather = "caveweather"
                    World.IsCave = ReturnValueFn(true)
                end)

                it("should return CaveWeather component", function()
                    assert.is_equal("caveweather", World.GetWeatherComponent())
                end)

                describe("and a caveweather component is missing", function()
                    before_each(function()
                        _G.TheWorld.net.components.caveweather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(World.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when not in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.weather = "weather"
                    World.IsCave = ReturnValueFn(false)
                end)

                it("should return Weather component", function()
                    assert.is_equal("weather", World.GetWeatherComponent())
                end)

                describe("and a weather component is not available", function()
                    before_each(function()
                        _G.TheWorld.net.components.weather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(World.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetWeatherComponent())
                    end, _G.TheWorld, "net", "net", "components")
                end)
            end)
        end)
    end)
end)
