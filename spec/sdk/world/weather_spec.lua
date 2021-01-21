require "busted.runner"()

describe("#sdk SDK.World.Weather", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Weather

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

        _G.ThePlayer = {
            GUID = 1,
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
        }

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
            end,
            PushEvent = Empty,
        })

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        SDK.LoadModule("World")
        Weather = require "yoursubdirectory/sdk/sdk/world/weather"

        SetTestModule(Weather)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.World.Weather." .. fn_name .. "():", ...)
    end

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[world]", "[weather]", ...)
    end

    local function TestGetState(fn_name, state, value)
        describe(fn_name .. "()", function()
            before_each(function()
                _G.TheWorld.state[state] = value
            end)

            it("should return TheWorld.state." .. state, function()
                assert.is_equal(value, Weather[fn_name]())
            end)
        end)
    end

    local function TestRemoteWorld(fn_name, name, ...)
        local args = { ... }

        describe("and SDK.Remote.World." .. name .. "() returns true", function()
            before_each(function()
                SDK.Remote.World[name] = spy.new(ReturnValueFn(true))
            end)

            it("should return true", function()
                assert.is_true(Weather[fn_name](unpack(args)))
            end)
        end)

        describe("and SDK.Remote.World." .. name .. "() returns false", function()
            before_each(function()
                SDK.Remote.World[name] = spy.new(ReturnValueFn(false))
            end)

            it("should return false", function()
                assert.is_false(Weather[fn_name](unpack(args)))
            end)
        end)
    end

    local function TestPushEventCalls(fn, ...)
        local args = { ... }
        it("should call TheWorld:PushEvent()", function()
            assert.spy(_G.TheWorld.PushEvent).was_not_called()
            fn()
            assert.spy(_G.TheWorld.PushEvent).was_called(1)
            assert.spy(_G.TheWorld.PushEvent).was_called_with(
                match.is_ref(_G.TheWorld),
                unpack(args)
            )
        end)
    end

    describe("general", function()
        describe("GetWeatherComponent()", function()
            describe("when not in the forest", function()
                before_each(function()
                    _G.TheWorld.net.components.weather = "weather"
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                it("should return Weather component", function()
                    assert.is_equal("weather", Weather.GetWeatherComponent())
                end)

                describe("and a weather component is not available", function()
                    before_each(function()
                        _G.TheWorld.net.components.weather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(Weather.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.caveweather = "caveweather"
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                it("should return CaveWeather component", function()
                    assert.is_equal("caveweather", Weather.GetWeatherComponent())
                end)

                describe("and a caveweather component is missing", function()
                    before_each(function()
                        _G.TheWorld.net.components.caveweather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(Weather.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Weather.GetWeatherComponent())
                    end, _G.TheWorld, "net", "net", "components")
                end)
            end)
        end)

        describe("SendLightningStrike()", function()
            local pt = Vector3(1, 0, 3)

            before_each(function()
                SDK.Remote.World.SendLightningStrike = spy.new(ReturnValueFn(true))
            end)

            TestArgPoint("SendLightningStrike", {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { "foo" },
                valid = { pt },
            })

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestDebugError(function()
                    Weather.SendLightningStrike(pt)
                end, "SendLightningStrike", "Invalid world type", "(must be in a forest)")
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestDebugErrorCalls(function()
                    Weather.SendLightningStrike(pt)
                end, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(function()
                        Weather.SendLightningStrike(pt)
                    end, "Send lighting strike:", tostring(pt))

                    TestPushEventCalls(function()
                        Weather.SendLightningStrike(pt)
                    end, "ms_sendlightningstrike", pt)

                    it("should return true", function()
                        assert.is_true(Weather.SendLightningStrike(pt))
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("SendLightningStrike", "SendLightningStrike", pt)
                end)
            end)
        end)

        describe("SendMiniEarthquake()", function()
            before_each(function()
                SDK.Remote.World.SendMiniEarthquake = spy.new(ReturnValueFn(true))
                _G.TheWorld.HasTag = spy.new(function(_, tag)
                    return tag == "cave"
                end)
            end)

            TestArgUnsignedInteger("SendMiniEarthquake", {
                empty = { nil, 20, 2.5, _G.ThePlayer },
                invalid = { "foo", 20, 2.5, _G.ThePlayer },
                valid = { 20, 20, 2.5, _G.ThePlayer },
            }, "radius")

            TestArgUnsignedInteger("SendMiniEarthquake", {
                empty = { 20, nil, 2.5, _G.ThePlayer },
                invalid = { 20, "foo", 2.5, _G.ThePlayer },
                valid = { 20, 20, 2.5, _G.ThePlayer },
            }, "amount")

            TestArgUnsigned("SendMiniEarthquake", {
                empty = { 20, 20, nil, _G.ThePlayer },
                invalid = { 20, 20, "foo", _G.ThePlayer },
                valid = { 20, 20, 2.5, _G.ThePlayer },
            }, "duration")

            TestArgUnsigned("SendMiniEarthquake", {
                empty = { 20, 20, nil, _G.ThePlayer },
                invalid = { 20, 20, "foo", _G.ThePlayer },
                valid = { 20, 20, 2.5, _G.ThePlayer },
            }, "duration")

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestDebugErrorCalls(function()
                    Weather.SendMiniEarthquake()
                end, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(function()
                        Weather.SendMiniEarthquake()
                    end, "Send mini earthquake:", "Player")

                    TestPushEventCalls(function()
                        Weather.SendMiniEarthquake()
                    end, "ms_miniquake", match.is_table())

                    it("should return true", function()
                        assert.is_true(Weather.SendMiniEarthquake())
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("SendMiniEarthquake", "SendMiniEarthquake")
                end)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestDebugError(function()
                    Weather.SendMiniEarthquake()
                end, "SendMiniEarthquake", "Invalid world type", "(must be in a cave)")
            end)
        end)
    end)

    describe("get", function()
        TestGetState("GetMoisture", "moisture", 750)
        TestGetState("GetMoistureCeil", "moistureceil", 1000)
        TestGetState("GetSnowLevel", "snowlevel", 0.5)
        TestGetState("GetWetness", "wetness", 50)
    end)

    describe("set", function()
        describe("SetDeltaMoisture()", function()
            before_each(function()
                SDK.Remote.World.SetDeltaMoisture = spy.new(ReturnValueFn(true))
            end)

            TestArgNumber("SetDeltaMoisture", {
                empty = {},
                invalid = { "foo" },
                valid = { 25 },
            }, "delta")

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(function()
                    Weather.SetDeltaMoisture(25)
                end, "Delta moisture:", "25.00")

                TestPushEventCalls(function()
                    Weather.SetDeltaMoisture(25)
                end, "ms_deltamoisture", 25)

                it("should return true", function()
                    assert.is_true(Weather.SetDeltaMoisture(25))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetDeltaMoisture", "SetDeltaMoisture", 25)
            end)
        end)

        describe("SetDeltaWetness()", function()
            before_each(function()
                SDK.Remote.World.SetDeltaWetness = spy.new(ReturnValueFn(true))
            end)

            TestArgNumber("SetDeltaWetness", {
                empty = {},
                invalid = { "foo" },
                valid = { 25 },
            }, "delta")

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(function()
                    Weather.SetDeltaWetness(25)
                end, "Delta wetness:", "25.00")

                TestPushEventCalls(function()
                    Weather.SetDeltaWetness(25)
                end, "ms_deltawetness", 25)

                it("should return true", function()
                    assert.is_true(Weather.SetDeltaWetness(25))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetDeltaWetness", "SetDeltaWetness", 25)
            end)
        end)

        describe("SetPrecipitation()", function()
            before_each(function()
                SDK.Remote.World.SetPrecipitation = spy.new(ReturnValueFn(true))
            end)

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(function()
                    Weather.SetPrecipitation(true)
                end, "Precipitation:", "true")

                TestPushEventCalls(function()
                    Weather.SetPrecipitation(true)
                end, "ms_forceprecipitation", true)

                it("should return true", function()
                    assert.is_true(Weather.SetPrecipitation(true))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetPrecipitation", "SetPrecipitation", true)
            end)
        end)

        describe("SetSnowLevel()", function()
            local level = 0.5

            before_each(function()
                SDK.Remote.World.SetSnowLevel = spy.new(ReturnValueFn(true))
            end)

            TestArgUnitInterval("SetSnowLevel", {
                empty = {},
                invalid = { "foo" },
                valid = { level },
            }, "level")

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestDebugError(function()
                    Weather.SetSnowLevel(level)
                end, "SetSnowLevel", "Invalid world type", "(must be in a forest)")
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestDebugErrorCalls(function()
                    Weather.SetSnowLevel(level)
                end, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(function()
                        Weather.SetSnowLevel(level)
                    end, "Snow level:", "0.50")

                    TestPushEventCalls(function()
                        Weather.SetSnowLevel(level)
                    end, "ms_setsnowlevel", level)

                    it("should return true", function()
                        assert.is_true(Weather.SetSnowLevel(level))
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("SetSnowLevel", "SetSnowLevel", level)
                end)
            end)
        end)
    end)
end)
