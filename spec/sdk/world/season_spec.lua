require "busted.runner"()

describe("#sdk SDK.World.Season", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Season

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
        _G.ThePlayer = {
            GUID = 1,
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
        }

        _G.TheWorld = mock({
            state = {
                autumnlength = 20,
                remainingdaysinseason = 17,
                season = "autumn",
            },
            PushEvent = Empty,
        })

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        SDK.LoadModule("World")
        Season = require "yoursubdirectory/sdk/sdk/world/season"

        SetTestModule(Season)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[world]", "[season]", ...)
    end

    local function TestGetState(fn_name, state, value)
        describe(fn_name .. "()", function()
            before_each(function()
                _G.TheWorld.state[state] = value
            end)

            it("should return TheWorld.state." .. state, function()
                assert.is_equal(value, Season[fn_name]())
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
                return Season[fn_name](unpack(args))
            end)
        end)

        describe("and SDK.Remote.World." .. name .. "() returns false", function()
            before_each(function()
                SDK.Remote.World[name] = spy.new(ReturnValueFn(false))
            end)

            TestReturnFalse(function()
                return Season[fn_name](unpack(args))
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
        describe("AdvanceSeason()", function()
            before_each(function()
                SDK.Remote.World.AdvanceSeason = spy.new(ReturnValueFn(true))
            end)

            TestArgUnsignedInteger("AdvanceSeason", {
                empty = {},
                invalid = { "foo" },
                valid = { 20 },
            }, "days")

            describe("when days argument is passed", function()
                local fn = function()
                    return Season.AdvanceSeason(20)
                end

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Advance season:", "20 days")
                    TestPushEventCalls(fn, 20, "ms_advanceseason")
                    TestReturnTrue(fn)

                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("AdvanceSeason", "AdvanceSeason", 20)
                end)
            end)

            describe("when days argument is not passed", function()
                local fn = function()
                    return Season.AdvanceSeason()
                end

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Advance season:", "17 days")
                    TestPushEventCalls(fn, 17, "ms_advanceseason")
                    TestReturnTrue(fn)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("AdvanceSeason", "AdvanceSeason", 20)
                end)
            end)
        end)

        describe("RetreatSeason()", function()
            before_each(function()
                SDK.Remote.World.RetreatSeason = spy.new(ReturnValueFn(true))
            end)

            TestArgUnsignedInteger("RetreatSeason", {
                empty = {},
                invalid = { "foo" },
                valid = { 20 },
            }, "days")

            describe("when days argument is passed", function()
                local fn = function()
                    return Season.RetreatSeason(20)
                end

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Retreat season:", "20 days")
                    TestPushEventCalls(fn, 20, "ms_retreatseason")
                    TestReturnTrue(fn)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("RetreatSeason", "RetreatSeason", 20)
                end)
            end)

            describe("when days argument is not passed", function()
                local fn = function()
                    return Season.RetreatSeason()
                end

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestDebugString(fn, "Retreat season:", "3 days")
                    TestPushEventCalls(fn, 3, "ms_retreatseason")
                    TestReturnTrue(fn)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteWorld("RetreatSeason", "RetreatSeason", 0)
                end)
            end)
        end)
    end)

    describe("get", function()
        TestGetState("GetSeason", "season", "autumn")

        describe("GetSeasonLength()", function()
            before_each(function()
                _G.TheWorld.state.autumnlength = 20
                _G.TheWorld.state.springlength = 20
                _G.TheWorld.state.summerlength = 15
                _G.TheWorld.state.winterlength = 15
            end)

            describe("when season argument is passed", function()
                it("should return TheWorld.state[season]length", function()
                    local state = _G.TheWorld.state
                    assert.is_equal(state.autumnlength, Season.GetSeasonLength("autumn"))
                    assert.is_equal(state.springlength, Season.GetSeasonLength("spring"))
                    assert.is_equal(state.summerlength, Season.GetSeasonLength("summer"))
                    assert.is_equal(state.winterlength, Season.GetSeasonLength("winter"))
                end)
            end)

            describe("when season argument is not passed", function()
                it("should return TheWorld.state[season]length", function()
                    assert.is_equal(_G.TheWorld.state.autumnlength, Season.GetSeasonLength())
                end)
            end)
        end)
    end)

    describe("set", function()
        describe("SetSeason()", function()
            local fn = function()
                return Season.SetSeason("autumn")
            end

            before_each(function()
                SDK.Remote.World.SetSeason = spy.new(ReturnValueFn(true))
            end)

            TestArgSeason("SetSeason", {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { "foo" },
                valid = { "autumn" },
            }, "season")

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(fn, "Season:", "autumn")
                TestPushEvent(fn, "ms_setseason", "autumn")
                TestReturnTrue(fn)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetSeason", "SetSeason", "autumn")
            end)
        end)

        describe("SetSeasonLength()", function()
            local fn_name = "SetSeasonLength"

            local fn = function()
                return Season.SetSeasonLength("autumn", 20)
            end

            before_each(function()
                SDK.Remote.World.SetSeasonLength = spy.new(ReturnValueFn(true))
            end)

            TestArgSeason(fn_name, {
                empty = {
                    args = { nil, 20 },
                    calls = 1,
                },
                invalid = { "foo", 20 },
                valid = { "autumn", 20 },
            }, "season")

            TestArgUnsignedInteger(fn_name, {
                empty = {
                    args = { "autumn" },
                    calls = 1,
                },
                invalid = { "autumn", "foo" },
                valid = { "autumn", 20 },
            }, "length")

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(fn, "Season length:", "autumn", "(20 days)")

                TestPushEvent(fn, "ms_setseasonlength", match.is_same({
                    season = "autumn",
                    length = 20
                }))

                TestReturnTrue(fn)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("SetSeasonLength", "SetSeasonLength", "autumn", 20)
            end)
        end)
    end)
end)
