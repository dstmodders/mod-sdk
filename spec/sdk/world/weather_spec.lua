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

            TestReturnTrue(function()
                return Weather[fn_name](unpack(args))
            end)
        end)

        describe("and SDK.Remote.World." .. name .. "() returns false", function()
            before_each(function()
                SDK.Remote.World[name] = spy.new(ReturnValueFn(false))
            end)

            TestReturnFalse(function()
                return Weather[fn_name](unpack(args))
            end)
        end)
    end

    local function TestPushEventCalls(fn, calls, ...)
        local args = { ... }
        it("should call TheWorld:PushEvent()", function()
            assert.spy(_G.TheWorld.PushEvent).was_not_called()
            fn()
            assert.spy(_G.TheWorld.PushEvent).was_called(calls)
            assert.spy(_G.TheWorld.PushEvent).was_called_with(
                match.is_ref(_G.TheWorld),
                unpack(args)
            )
        end)
    end

    local function TestPushEvent(fn, ...)
        TestPushEventCalls(fn, 1, ...)
    end

    describe("general", function()
        describe("GetWeatherComponent()", function()
            local fn = function()
                return Weather.GetWeatherComponent()
            end

            describe("when not in the forest", function()
                before_each(function()
                    _G.TheWorld.net.components.weather = "weather"
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                it("should return Weather component", function()
                    assert.is_equal("weather", fn())
                end)

                describe("and a weather component is not available", function()
                    before_each(function()
                        _G.TheWorld.net.components.weather = nil
                    end)

                    TestReturnNil(fn)
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
                    assert.is_equal("caveweather", fn())
                end)

                describe("and a caveweather component is missing", function()
                    before_each(function()
                        _G.TheWorld.net.components.caveweather = nil
                    end)

                    TestReturnNil(fn)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(fn())
                    end, _G.TheWorld, "net", "net", "components")
                end)
            end)
        end)

        describe("SendLightningStrike()", function()
            local pt = Vector3(1, 0, 3)

            local fn = function()
                return Weather.SendLightningStrike(pt)
            end

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

                TestDebugError(
                    fn,
                    "SendLightningStrike",
                    "Invalid world type",
                    "(must be in a forest)"
                )
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestDebugErrorCalls(fn, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Send lighting strike:", tostring(pt))
                    TestPushEvent(fn, "ms_sendlightningstrike", pt)
                    TestReturnTrue(fn)
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
            local fn = function()
                return Weather.SendMiniEarthquake()
            end

            before_each(function()
                SDK.Remote.World.SendMiniEarthquake = spy.new(ReturnValueFn(true))
                _G.TheWorld.HasTag = spy.new(function(_, tag)
                    return tag == "cave"
                end)
            end)

            TestArgPlayer("SendMiniEarthquake", {
                empty = { nil, 20, 20, 2.5 },
                invalid = { "foo", 20, 20, 2.5 },
                valid = { _G.ThePlayer, 20, 20, 2.5 },
            }, "player")

            TestArgUnsignedInteger("SendMiniEarthquake", {
                empty = { _G.ThePlayer, nil, 20, 2.5 },
                invalid = { _G.ThePlayer, "foo", 20, 2.5 },
                valid = { _G.ThePlayer, 20, 20, 2.5 },
            }, "radius")

            TestArgUnsignedInteger("SendMiniEarthquake", {
                empty = { _G.ThePlayer, 20, nil, 2.5 },
                invalid = { _G.ThePlayer, 20, "foo", 2.5 },
                valid = { _G.ThePlayer, 20, 20, 2.5 },
            }, "amount")

            TestArgUnsigned("SendMiniEarthquake", {
                empty = { _G.ThePlayer, 20, 20 },
                invalid = { _G.ThePlayer, 20, 20, "foo" },
                valid = { _G.ThePlayer, 20, 20, 2.5 },
            }, "duration")

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestDebugErrorCalls(fn, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Send mini earthquake:", "Player")
                    TestPushEvent(fn, "ms_miniquake", match.is_table())
                    TestReturnTrue(fn)
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

                TestDebugError(
                    fn,
                    "SendMiniEarthquake",
                    "Invalid world type",
                    "(must be in a cave)"
                )
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
            local fn = function()
                return Weather.SetDeltaMoisture(25)
            end

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

                TestDebugString(fn, "Delta moisture:", "25.00")
                TestPushEvent(fn, "ms_deltamoisture", 25)
                TestReturnTrue(fn)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetDeltaMoisture", "SetDeltaMoisture", 25)
            end)
        end)

        describe("SetDeltaWetness()", function()
            local fn = function()
                return Weather.SetDeltaWetness(25)
            end

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

                TestDebugString(fn, "Delta wetness:", "25.00")
                TestPushEvent(fn, "ms_deltawetness", 25)
                TestReturnTrue(fn)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetDeltaWetness", "SetDeltaWetness", 25)
            end)
        end)

        describe("SetPrecipitation()", function()
            local fn = function()
                return Weather.SetPrecipitation(true)
            end

            before_each(function()
                SDK.Remote.World.SetPrecipitation = spy.new(ReturnValueFn(true))
            end)

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(fn, "Precipitation:", "true")
                TestPushEvent(fn, "ms_forceprecipitation", true)
                TestReturnTrue(fn)
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

            local fn = function()
                return Weather.SetSnowLevel(level)
            end

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

                TestDebugError(fn, "SetSnowLevel", "Invalid world type", "(must be in a forest)")
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestDebugErrorCalls(fn, 0)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Snow level:", "0.50")
                    TestPushEvent(fn, "ms_setsnowlevel", level)
                    TestReturnTrue(fn)
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
