require "busted.runner"()

describe("#sdk SDK.Remote.World", function()
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
        _G.TheSim = nil
        _G.TheWorld = nil
        _G.TUNING = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.ThePlayer = mock({
            GUID = 1,
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 0, 3
            end,
        })

        _G.TheWorld = mock({
            HasTag = ReturnValueFn(false),
        })

        _G.TUNING = {
            MIN_ENTITY_TEMP = -20,
            MAX_ENTITY_TEMP = 90,
        }

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Remote")
        World = SDK.Remote.World

        -- spies
        SDK.Debug.Error = spy.on(SDK.Debug, "Error")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
    end)

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        _G.AssertDebugErrorInvalidArg(fn, World, fn_name, arg_name, explanation)
    end

    local function AssertSendWasCalled(fn, ...)
        local args = { ..., 1, 3 }
        assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
        fn()
        assert.spy(_G.TheNet.SendRemoteExecute).was_called(1)
        assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
            match.is_ref(_G.TheNet),
            unpack(args)
        )
    end

    local function AssertSendWasNotCalled(fn)
        assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
        fn()
        assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
    end

    local function TestRemoteInvalid(name, msg, explanation, ...)
        local args = { ... }
        local description = "when no arguments are passed"
        if #args > 1 then
            description = "when valid arguments are passed"
        elseif #args == 1 then
            description = "when a valid argument is passed"
        end

        describe(description, function()
            it("should debug error string", function()
                AssertDebugError(
                    function()
                        World[name](unpack(args))
                    end,
                    string.format("SDK.Remote.World.%s():", name),
                    msg,
                    explanation and "(" .. explanation .. ")"
                )
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    World[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(World[name](unpack(args)))
            end)
        end)
    end

    local function TestRemoteInvalidArg(name, arg_name, explanation, ...)
        local args = { ... }
        local description = "when no arguments are passed"
        if #args > 1 then
            description = "when invalid arguments are passed"
        elseif #args == 1 then
            description = "when an invalid argument is passed"
        end

        describe(description, function()
            it("should debug error string", function()
                AssertDebugErrorInvalidArg(function()
                    World[name](unpack(args))
                end, name, arg_name, explanation)
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    World[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(World[name](unpack(args)))
            end)
        end)
    end

    local function TestRemoteInvalidWorldType(name, explanation, ...)
        TestRemoteInvalid(name, "Invalid world type", explanation, ...)
    end

    local function TestRemoteValid(name, debug, send, ...)
        local args = { ... }
        local description = "when no arguments are passed"
        if #args > 1 then
            description = "when valid arguments are passed"
        elseif #args == 1 then
            description = "when a valid argument is passed"
        end

        describe(description, function()
            if debug then
                it("should debug string", function()
                    AssertDebugString(function()
                        World[name](unpack(args))
                    end, "[remote]", "[world]", unpack(debug))
                end)
            end

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(function()
                    World[name](unpack(args))
                end, send)
            end)

            it("should return true", function()
                assert.is_true(World[name](unpack(args)))
            end)
        end)
    end

    describe("general", function()
        describe("ForcePrecipitation()", function()
            TestRemoteValid("ForcePrecipitation", {
                "Force precipitation:",
                "true",
            }, 'TheWorld:PushEvent("ms_forceprecipitation", true)')

            TestRemoteValid("ForcePrecipitation", {
                "Force precipitation:",
                "true",
            }, 'TheWorld:PushEvent("ms_forceprecipitation", true)', true)

            TestRemoteValid("ForcePrecipitation", {
                "Force precipitation:",
                "false",
            }, 'TheWorld:PushEvent("ms_forceprecipitation", false)', false)
        end)

        describe("PushEvent()", function()
            TestRemoteInvalidArg("PushEvent", "event", "must be a string")
            TestRemoteInvalidArg("PushEvent", "event", "must be a string", true)

            TestRemoteValid(
                "PushEvent",
                nil,
                'TheWorld:PushEvent("ms_advanceseason")',
                "ms_advanceseason"
            )

            TestRemoteValid(
                "PushEvent",
                nil,
                'TheWorld:PushEvent("ms_forceprecipitation", true)',
                "ms_forceprecipitation",
                true
            )

            TestRemoteValid(
                "PushEvent",
                nil,
                'TheWorld:PushEvent("ms_forceprecipitation", false)',
                "ms_forceprecipitation",
                false
            )

            TestRemoteValid(
                "PushEvent",
                nil,
                'TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 20 })',
                "ms_setseasonlength",
                { season = "autumn", length = 20 }
            )
        end)

        describe("Rollback()", function()
            TestRemoteInvalidArg("Rollback", "days", "must be an unsigned integer", -1)
            TestRemoteInvalidArg("Rollback", "days", "must be an unsigned integer", 0.5)

            TestRemoteValid("Rollback", {
                "Rollback:",
                "0 days",
            }, "TheNet:SendWorldRollbackRequestToServer(0)")

            TestRemoteValid("Rollback", {
                "Rollback:",
                "1 day",
            }, "TheNet:SendWorldRollbackRequestToServer(1)", 1)

            TestRemoteValid("Rollback", {
                "Rollback:",
                "3 days",
            }, "TheNet:SendWorldRollbackRequestToServer(3)", 3)
        end)

        describe("SendLightningStrike()", function()
            local pt

            setup(function()
                pt = Vector3(1, 0, 3)
            end)

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestRemoteInvalidWorldType("SendLightningStrike", "must be in a forest", pt)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestRemoteInvalidArg("SendLightningStrike", "pt", "must be a point", "foo")

                TestRemoteValid(
                    "SendLightningStrike",
                    { "Send lighting strike:", "(1.00, 0.00, 3.00)" },
                    'TheWorld:PushEvent("ms_sendlightningstrike", Vector3(1.00, 0.00, 3.00))',
                    pt
                )
            end)
        end)

        describe("SetDeltaMoisture()", function()
            TestRemoteInvalidArg("SetDeltaMoisture", "delta", "must be a number", "foo")

            TestRemoteValid("SetDeltaMoisture", {
                "Delta moisture:",
                "0.00",
            }, 'TheWorld:PushEvent("ms_deltamoisture", 0)')

            TestRemoteValid("SetDeltaMoisture", {
                "Delta moisture:",
                "1.00",
            }, 'TheWorld:PushEvent("ms_deltamoisture", 1)', 1)
        end)

        describe("SetDeltaWetness()", function()
            TestRemoteInvalidArg("SetDeltaWetness", "delta", "must be a number", "foo")

            TestRemoteValid("SetDeltaWetness", {
                "Delta wetness:",
                "0.00",
            }, 'TheWorld:PushEvent("ms_deltawetness", 0)')

            TestRemoteValid("SetDeltaWetness", {
                "Delta wetness:",
                "1.00",
            }, 'TheWorld:PushEvent("ms_deltawetness", 1)', 1)
        end)

        describe("SetSeason()", function()
            TestRemoteInvalidArg(
                "SetSeason",
                "season",
                "must be a season: autumn, winter, spring or summer",
                "foo"
            )

            TestRemoteValid("SetSeason", {
                "Season:",
                "autumn",
            }, 'TheWorld:PushEvent("ms_setseason", "autumn")', "autumn")
        end)

        describe("SetSeasonLength()", function()
            TestRemoteInvalidArg(
                "SetSeasonLength",
                "season",
                "must be a season: autumn, winter, spring or summer",
                "foo",
                10
            )

            TestRemoteInvalidArg(
                "SetSeasonLength",
                "length",
                "must be an unsigned integer",
                "autumn",
                -10
            )

            TestRemoteValid(
                "SetSeasonLength",
                { "Season length:", "autumn", "(10 days)" },
                'TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 10 })',
                "autumn",
                10
            )
        end)

        describe("SetSnowLevel()", function()
            describe("when not in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(true)
                end)

                TestRemoteInvalidWorldType("SetSnowLevel", "must be in a forest", 1)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(false)
                end)

                TestRemoteInvalidArg("SetSnowLevel", "delta", "must be a unit interval", 2)

                TestRemoteValid("SetSnowLevel", {
                    "Snow level:",
                    "0.00",
                }, 'TheWorld:PushEvent("ms_setsnowlevel", 0)')

                TestRemoteValid("SetSnowLevel", {
                    "Snow level:",
                    "0.50",
                }, 'TheWorld:PushEvent("ms_setsnowlevel", 0.50)', 0.5)

                TestRemoteValid("SetSnowLevel", {
                    "Snow level:",
                    "1.00",
                }, 'TheWorld:PushEvent("ms_setsnowlevel", 1)', 1)
            end)
        end)
    end)
end)
