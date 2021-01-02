require "busted.runner"()

describe("#sdk SDK.Remote", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Remote

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        _G.TheNet = nil
        _G.TheSim = nil
        _G.ThePlayer = nil
        _G.TheWorld = nil
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 0, 3
            end,
        })

        _G.ThePlayer = mock({
            GUID = 1,
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
        })

        _G.TheWorld = mock({
            HasTag = ReturnValueFn(false),
        })

        -- initialization
        SDK = require "sdk/sdk"
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        Remote = require "sdk/remote"
        Remote._DoInit(SDK)

        -- spies
        Remote.Send = spy.on(Remote, "Send")
        SDK.Debug.Error = spy.on(SDK.Debug, "Error")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
    end)

    local function TestDebugError(fn, ...)
        local args = { ... }
        it("should debug error string", function()
            assert.spy(SDK.Debug.Error).was_not_called()
            fn()
            assert.spy(SDK.Debug.Error).was_called(1)
            assert.spy(SDK.Debug.Error).was_called_with(unpack(args))
        end)
    end

    local function TestDebugString(fn, ...)
        local args = { ... }
        it("should debug string", function()
            assert.spy(SDK.Debug.String).was_not_called()
            fn()
            assert.spy(SDK.Debug.String).was_called(1)
            assert.spy(SDK.Debug.String).was_called_with(unpack(args))
        end)
    end

    local function TestSendRemoteExecuteWasCalled(fn, ...)
        local args = { ..., 1, 3 }
        it("should call TheSim:SendRemoteExecute()", function()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
            fn()
            assert.spy(_G.TheNet.SendRemoteExecute).was_called(1)
            assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                match.is_ref(_G.TheNet),
                unpack(args)
            )
        end)
    end

    local function TestSendRemoteExecuteWasNotCalled(fn)
        it("shouldn't call TheSim:SendRemoteExecute()", function()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
            fn()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
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
            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
            end)

            TestDebugError(
                function()
                    Remote[name](unpack(args))
                end,
                string.format("SDK.Remote.%s():", name),
                string.format(
                    "Invalid argument%s is passed",
                    arg_name and ' (' .. arg_name .. ")" or ""
                ),
                explanation and "(" .. explanation .. ")"
            )

            TestSendRemoteExecuteWasNotCalled(function()
                Remote[name](unpack(args))
            end)
        end)
    end

    local function TestRemotePlayerIsGhost(name, player, ...)
        local args = { ..., player }
        describe("when a player is a ghost", function()
            local _HasTag

            before_each(function()
                _HasTag = player.HasTag
                player.HasTag = spy.new(function(_, tag)
                    return tag == "player" or tag == "playerghost"
                end)
            end)

            after_each(function()
                player.HasTag = _HasTag
            end)

            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
            end)

            TestDebugError(
                function()
                    Remote[name](unpack(args))
                end,
                string.format("SDK.Remote.%s():", name),
                "Player shouldn't be a ghost"
            )

            TestSendRemoteExecuteWasNotCalled(function()
                Remote[name](unpack(args))
            end)
        end)
    end

    local function TestRemoteInvalidWorldType(name, explanation, ...)
        local args = { ... }
        local description = "when no arguments are passed"
        if #args > 1 then
            description = "when valid arguments are passed"
        elseif #args == 1 then
            description = "when a valid argument is passed"
        end

        describe(description, function()
            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
            end)

            TestDebugError(
                function()
                    Remote[name](unpack(args))
                end,
                string.format("SDK.Remote.%s():", name),
                "Invalid world type",
                explanation and "(" .. explanation .. ")"
            )

            TestSendRemoteExecuteWasNotCalled(function()
                Remote[name](unpack(args))
            end)
        end)
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
            it("should return true", function()
                assert.is_true(Remote[name](unpack(args)))
            end)

            TestDebugString(function()
                Remote[name](unpack(args))
            end, "[remote]", unpack(debug))

            TestSendRemoteExecuteWasCalled(function()
                Remote[name](unpack(args))
            end, send)
        end)
    end

    describe("general", function()
        describe("GatherPlayers()", function()
            TestRemoteValid("GatherPlayers", { "Gather players" }, "c_gatherplayers()")
        end)

        describe("GoNext()", function()
            local entity = {
                GUID = 1,
                prefab = "foobar",
                GetDisplayName = ReturnValueFn("Foo Bar"),
            }

            TestRemoteInvalidArg("GoNext", "entity", "must be an entity", "foo")
            TestRemoteValid("GoNext", {
                "Go next:",
                "Foo Bar",
            }, 'c_gonext("foobar")', entity)
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

        describe("Send()", function()
            describe("when different data types are passed", function()
                TestSendRemoteExecuteWasCalled(function()
                    Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                end, '1, 0.12, "test"')
            end)

            it("should call TheSim:GetPosition()", function()
                assert.spy(_G.TheSim.GetPosition).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.GetPosition).was_called(1)
                assert.spy(_G.TheSim.GetPosition).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:ProjectScreenPos()", function()
                assert.spy(_G.TheSim.ProjectScreenPos).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.ProjectScreenPos).was_called(1)
                assert.spy(_G.TheSim.ProjectScreenPos).was_called_with(match.is_ref(_G.TheSim))
            end)

            TestSendRemoteExecuteWasCalled(function()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
            end, 'TheWorld:PushEvent("ms_setseason", "autumn")')
        end)
    end)

    describe("player", function()
        local function TestSetPlayerAttributePercent(name, debug, send)
            describe(name .. "()", function()
                describe("when a player is not a ghost", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag ~= "playerghost"
                        end)
                    end)

                    TestRemoteInvalidArg(name, "value", "must be a percent", "foo")
                    TestRemoteInvalidArg(name, "player", "must be a player", 50, "foo")
                    TestRemoteValid(name, debug, send, 50, _G.ThePlayer)
                end)

                TestRemotePlayerIsGhost("SetPlayerHealthPercent", _G.ThePlayer, 50)
            end)
        end

        TestSetPlayerAttributePercent(
            "SetPlayerHealthPercent",
            { "Player health:", "50.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPercent(math.min(0.50, 1)) end' -- luacheck: only
        )
    end)

    describe("world", function()
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

        describe("SendMiniEarthquake()", function()
            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestRemoteInvalidWorldType("SendMiniEarthquake", "must be in a cave")
            end)

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestRemoteInvalidArg("SendMiniEarthquake", "player", "must be a player", "foo")

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "radius",
                    "must be an unsigned integer",
                    _G.ThePlayer,
                    "foo"
                )

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "amount",
                    "must be an unsigned integer",
                    _G.ThePlayer,
                    20,
                    -10
                )

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "duration",
                    "must be an unsigned number",
                    _G.ThePlayer,
                    20,
                    20,
                    true
                )

                TestRemoteValid(
                    "SendMiniEarthquake",
                    { "Send mini earthquake:", "Player" },
                    'TheWorld:PushEvent("ms_miniquake", { target = LookupPlayerInstByUserID("KU_foobar"), rad = 20, num = 20, duration = 2.50 })' -- luacheck: only
                )

                TestRemoteValid(
                    "SendMiniEarthquake",
                    { "Send mini earthquake:", "Player" },
                    'TheWorld:PushEvent("ms_miniquake", { target = LookupPlayerInstByUserID("KU_foobar"), rad = 20, num = 20, duration = 2.50 })', -- luacheck: only
                    _G.ThePlayer,
                    20,
                    20,
                    2.5
                )
            end)
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
                    "0",
                }, 'TheWorld:PushEvent("ms_setsnowlevel", 0.00)')

                TestRemoteValid("SetSnowLevel", {
                    "Snow level:",
                    "1",
                }, 'TheWorld:PushEvent("ms_setsnowlevel", 1.00)', 1)
            end)
        end)

        describe("SetWorldDeltaMoisture()", function()
            TestRemoteInvalidArg("SetWorldDeltaMoisture", "delta", "must be a number", "foo")

            TestRemoteValid("SetWorldDeltaMoisture", {
                "World delta moisture:",
                "0",
            }, 'TheWorld:PushEvent("ms_deltamoisture", 0)')

            TestRemoteValid("SetWorldDeltaMoisture", {
                "World delta moisture:",
                "1",
            }, 'TheWorld:PushEvent("ms_deltamoisture", 1)', 1)
        end)

        describe("SetWorldDeltaWetness()", function()
            TestRemoteInvalidArg("SetWorldDeltaWetness", "delta", "must be a number", "foo")

            TestRemoteValid("SetWorldDeltaWetness", {
                "World delta wetness:",
                "0",
            }, 'TheWorld:PushEvent("ms_deltawetness", 0)')

            TestRemoteValid("SetWorldDeltaWetness", {
                "World delta wetness:",
                "1",
            }, 'TheWorld:PushEvent("ms_deltawetness", 1)', 1)
        end)
    end)
end)
