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
            state = {},
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

            it("should return true", function()
                assert.is_true(Season[fn_name](unpack(args)))
            end)
        end)

        describe("and SDK.Remote.World." .. name .. "() returns false", function()
            before_each(function()
                SDK.Remote.World[name] = spy.new(ReturnValueFn(false))
            end)

            it("should return false", function()
                assert.is_false(Season[fn_name](unpack(args)))
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

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(function()
                    Season.AdvanceSeason(20)
                end, "Advance season:", "20 days")

                TestPushEventCalls(function()
                    Season.AdvanceSeason(20)
                end, 20, "ms_advanceseason")

                it("should return true", function()
                    assert.is_true(Season.AdvanceSeason(20))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("AdvanceSeason", "AdvanceSeason", 20)
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

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestDebugString(function()
                    Season.RetreatSeason(20)
                end, "Retreat season:", "20 days")

                TestPushEventCalls(function()
                    Season.RetreatSeason(20)
                end, 20, "ms_retreatseason")

                it("should return true", function()
                    assert.is_true(Season.RetreatSeason(20))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteWorld("RetreatSeason", "RetreatSeason", 20)
            end)
        end)
    end)

    describe("get", function()
        TestGetState("GetSeason", "season", "autumn")

        describe("GetSeasonLength()", function()
            before_each(function()
                _G.TheWorld.state = {
                    autumnlength = 20,
                    springlength = 20,
                    summerlength = 15,
                    winterlength = 15,
                }
            end)

            it("should return TheWorld.state[season]length", function()
                assert.is_equal(_G.TheWorld.state.autumnlength, Season.GetSeasonLength("autumn"))
                assert.is_equal(_G.TheWorld.state.springlength, Season.GetSeasonLength("spring"))
                assert.is_equal(_G.TheWorld.state.summerlength, Season.GetSeasonLength("summer"))
                assert.is_equal(_G.TheWorld.state.winterlength, Season.GetSeasonLength("winter"))
            end)
        end)
    end)

    describe("set", function()
        describe("SetSeason()", function()
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

                TestDebugString(function()
                    Season.SetSeason("autumn")
                end, "Season:", "autumn")

                TestPushEvent(function()
                    Season.SetSeason("autumn")
                end, "ms_setseason", "autumn")

                it("should return true", function()
                    assert.is_true(Season.SetSeason("autumn"))
                end)
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

                TestDebugString(function()
                    Season.SetSeasonLength("autumn", 20)
                end, "Season length:", "autumn", "(20 days)")

                TestPushEvent(function()
                    Season.SetSeasonLength("autumn", 20)
                end, "ms_setseasonlength", match.is_same({
                    season = "autumn",
                    length = 20
                }))

                it("should return true", function()
                    assert.is_true(Season.SetSeasonLength("autumn", 20))
                end)
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
