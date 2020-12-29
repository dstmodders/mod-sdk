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
        _G.TheWorld = nil
    end)

    before_each(function()
        -- globals
        _G.TheWorld = {
            meta = {
                saveversion = "5.031",
                seed = "1574459949",
            },
            net = {
                components = {},
            },
            state = {},
        }

        -- initialization
        SDK = require "sdk/sdk"
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        World = require "sdk/world"
        World._DoInit(SDK)
    end)

    describe("general", function()
        describe("GetMeta", function()
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

        describe("GetSeed", function()
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

        describe("IsPassable", function()
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
    end)

    describe("phase", function()
        describe("GetPhase", function()
            before_each(function()
                _G.TheWorld.state.cavephase = "dusk"
                _G.TheWorld.state.phase = "day"
                World.IsCave = ReturnValueFn(true)
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

        describe("GetPhaseNext", function()
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

        describe("GetTimeUntilPhase", function()
            local clock, GetTimeUntilPhase

            before_each(function()
                _G.TheWorld.net.components.clock = {}
                _G.TheWorld.net.components.clock.GetTimeUntilPhase = spy.new(ReturnValueFn(10))
                clock = _G.TheWorld.net.components.clock
                GetTimeUntilPhase = clock.GetTimeUntilPhase
            end)

            it("should call Clock:GetTimeUntilPhase()", function()
                assert.spy(GetTimeUntilPhase).was_not_called()
                World.GetTimeUntilPhase("day")
                assert.spy(GetTimeUntilPhase).was_called(1)
                assert.spy(GetTimeUntilPhase).was_called_with(match.is_ref(clock), "day")
            end)

            it("should return Clock:GetTimeUntilPhase() value", function()
                assert.is_equal(10, World.GetTimeUntilPhase("day"))
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
        describe("GetWeatherComponent", function()
            describe("when in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.caveweather = "caveweather"
                    World.IsCave = ReturnValueFn(true)
                end)

                it("should return CaveWeather component", function()
                    assert.is_equal("caveweather", World.GetWeatherComponent())
                end)

                describe("and the CaveWeather component is missing", function()
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

                describe("and the Weather component is missing", function()
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
