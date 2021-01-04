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
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        Remote = require "yoursubdirectory/sdk/sdk/remote"

        -- spies
        Remote.Send = spy.on(Remote, "Send")
        SDK.Debug.Error = spy.on(SDK.Debug, "Error")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
    end)

    after_each(function()
        package.loaded["yoursubdirectory/sdk/sdk/sdk"] = nil
    end)

    local function AssertDebugError(fn, ...)
        assert.spy(SDK.Debug.Error).was_not_called()
        fn()
        assert.spy(SDK.Debug.Error).was_called(1)
        assert.spy(SDK.Debug.Error).was_called_with(...)
    end

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        AssertDebugError(
            fn,
            string.format("SDK.Remote.%s():", fn_name),
            string.format(
                "Invalid argument%s is passed",
                arg_name and ' (' .. arg_name .. ")" or ""
            ),
            explanation and "(" .. explanation .. ")"
        )
    end

    local function AssertDebugString(fn, ...)
        assert.spy(SDK.Debug.String).was_not_called()
        fn()
        assert.spy(SDK.Debug.String).was_called(1)
        assert.spy(SDK.Debug.String).was_called_with(...)
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
                        Remote[name](unpack(args))
                    end,
                    string.format("SDK.Remote.%s():", name),
                    msg,
                    explanation and "(" .. explanation .. ")"
                )
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Remote[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
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
                    Remote[name](unpack(args))
                end, name, arg_name, explanation)
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Remote[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
            end)
        end)
    end

    local function TestRemoteInvalidWorldType(name, explanation, ...)
        TestRemoteInvalid(name, "Invalid world type", explanation, ...)
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

            it("should debug error string", function()
                AssertDebugError(
                    function()
                        Remote[name](unpack(args))
                    end,
                    string.format("SDK.Remote.%s():", name),
                    "Player shouldn't be a ghost"
                )
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Remote[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Remote[name](unpack(args)))
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
            it("should debug string", function()
                AssertDebugString(function()
                    Remote[name](unpack(args))
                end, "[remote]", unpack(debug))
            end)

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(function()
                    Remote[name](unpack(args))
                end, send)
            end)

            it("should return true", function()
                assert.is_true(Remote[name](unpack(args)))
            end)
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
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                    end, '1, 0.12, "test"')
                end)
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

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(function()
                    Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                end, 'TheWorld:PushEvent("ms_setseason", "autumn")')
            end)
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

                    TestRemoteInvalidArg(name, "percent", "must be a percent", "foo")
                    TestRemoteInvalidArg(name, "player", "must be a player", 25, "foo")
                    TestRemoteValid(name, debug, send, 25, _G.ThePlayer)
                end)

                TestRemotePlayerIsGhost(name, _G.ThePlayer, 25)
            end)
        end

        TestSetPlayerAttributePercent(
            "SetPlayerHealthLimitPercent",
            { "Player health limit:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPenalty(0.75) end' -- luacheck: only
        )

        TestSetPlayerAttributePercent(
            "SetPlayerHealthPercent",
            { "Player health:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetPlayerAttributePercent(
            "SetPlayerHungerPercent",
            { "Player hunger:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.hunger then player.components.hunger:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetPlayerAttributePercent(
            "SetPlayerMoisturePercent",
            { "Player moisture:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.moisture then player.components.moisture:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetPlayerAttributePercent(
            "SetPlayerSanityPercent",
            { "Player sanity:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.sanity then player.components.sanity:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        describe("SetPlayerTemperature()", function()
            describe("when a player is not a ghost", function()
                before_each(function()
                    _G.ThePlayer.HasTag = spy.new(function(_, tag)
                        return tag ~= "playerghost"
                    end)
                end)

                TestRemoteInvalidArg(
                    "SetPlayerTemperature",
                    "value",
                    "must be an entity temperature",
                    "foo"
                )

                TestRemoteInvalidArg(
                    "SetPlayerTemperature",
                    "player",
                    "must be a player",
                    25,
                    "foo"
                )

                TestRemoteValid(
                    "SetPlayerTemperature",
                    { "Player temperature:", "25.00°", "(Player)" },
                    'player = LookupPlayerInstByUserID("KU_foobar") if player.components.temperature then player.components.temperature:SetTemperature(25.00) end', -- luacheck: only
                    25,
                    _G.ThePlayer
                )
            end)

            TestRemotePlayerIsGhost("SetPlayerTemperature", _G.ThePlayer, 25)
        end)

        describe("SetPlayerWerenessPercent()", function()
            describe("when a player is not a ghost", function()
                describe("and a player is a Woodie", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag == "player" or tag == "werehuman"
                        end)
                    end)

                    describe("when valid arguments are passed", function()
                        it("should debug string", function()
                            AssertDebugString(function()
                                Remote.SetPlayerWerenessPercent(25, _G.ThePlayer)
                            end, "[remote]", "Player wereness:", "25.00%", "(Player)")
                        end)

                        it("should call TheSim:SendRemoteExecute()", function()
                            AssertSendWasCalled(function()
                                Remote.SetPlayerWerenessPercent(25, _G.ThePlayer)
                            end, 'player = LookupPlayerInstByUserID("KU_foobar") if player.components.wereness then player.components.wereness:SetPercent(math.min(0.25, 1)) end') -- luacheck: only
                        end)

                        it("should return true", function()
                            assert.is_true(Remote.SetPlayerWerenessPercent(25, _G.ThePlayer))
                        end)
                    end)

                    TestRemoteInvalidArg(
                        "SetPlayerWerenessPercent",
                        "percent",
                        "must be a percent",
                        "foo"
                    )

                    TestRemoteInvalidArg(
                        "SetPlayerWerenessPercent",
                        "player",
                        "must be a player",
                        25,
                        "foo"
                    )
                end)

                describe("and a player is not a Woodie", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag == "player"
                        end)
                    end)

                    describe("when valid arguments are passed", function()
                        it("should debug error string", function()
                            AssertDebugError(
                                function()
                                    Remote.SetPlayerWerenessPercent(25, _G.ThePlayer)
                                end,
                                "SDK.Remote.SetPlayerWerenessPercent():",
                                "Player should be a Woodie"
                            )
                        end)

                        it("shouldn't call TheSim:SendRemoteExecute()", function()
                            AssertSendWasNotCalled(function()
                                Remote.SetPlayerWerenessPercent(25, _G.ThePlayer)
                            end)
                        end)

                        it("should return false", function()
                            assert.is_false(Remote.SetPlayerWerenessPercent(25, _G.ThePlayer))
                        end)
                    end)

                    TestRemoteInvalidArg(
                        "SetPlayerWerenessPercent",
                        "percent",
                        "must be a percent",
                        "foo"
                    )

                    TestRemoteInvalidArg(
                        "SetPlayerWerenessPercent",
                        "player",
                        "must be a player",
                        25,
                        "foo"
                    )
                end)
            end)

            TestRemotePlayerIsGhost("SetPlayerWerenessPercent", _G.ThePlayer, 25)
        end)
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
