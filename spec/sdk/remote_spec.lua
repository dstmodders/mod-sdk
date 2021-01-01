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

    teardown(function()
        _G.TheNet = nil
        _G.TheSim = nil
        _G.TheWorld = nil
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

    describe("general", function()
        describe("GatherPlayers()", function()
            it("should return true", function()
                assert.is_true(Remote.GatherPlayers())
            end)

            TestDebugString(function()
                Remote.GatherPlayers()
            end, "[remote]", "Gather players")

            TestSendRemoteExecuteWasCalled(function()
                Remote.GatherPlayers()
            end, "c_gatherplayers()")
        end)

        describe("Rollback()", function()
            describe("when no days are passed", function()
                it("should return true", function()
                    assert.is_true(Remote.Rollback())
                end)

                TestDebugString(function()
                    Remote.Rollback()
                end, "[remote]", "Rollback:", "0 days")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.Rollback()
                end, "TheNet:SendWorldRollbackRequestToServer(0)")
            end)

            describe("when a valid value is passed", function()
                describe("(1 day)", function()
                    it("should return true", function()
                        assert.is_true(Remote.Rollback(1))
                    end)

                    TestDebugString(function()
                        Remote.Rollback(1)
                    end, "[remote]", "Rollback:", "1 day")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.Rollback(1)
                    end, 'TheNet:SendWorldRollbackRequestToServer(1)')
                end)

                describe("(3 days)", function()
                    it("should return true", function()
                        assert.is_true(Remote.Rollback(3))
                    end)

                    TestDebugString(function()
                        Remote.Rollback(3)
                    end, "[remote]", "Rollback:", "3 days")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.Rollback(3)
                    end, "TheNet:SendWorldRollbackRequestToServer(3)")
                end)
            end)

            describe("when an invalid value is passed", function()
                describe("(-1 day)", function()
                    it("should return false", function()
                        assert.is_false(Remote.Rollback(-1))
                    end)

                    TestDebugError(
                        function()
                            Remote.Rollback(-1)
                        end,
                        "SDK.Remote.Rollback():",
                        'Invalid argument (days) is passed',
                        "(must be an unsigned integer)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.Rollback(-1)
                    end)
                end)

                describe("(0.5 days)", function()
                    it("should return false", function()
                        assert.is_false(Remote.Rollback(0.5))
                    end)

                    TestDebugError(
                        function()
                            Remote.Rollback(0.5)
                        end,
                        "SDK.Remote.Rollback():",
                        'Invalid argument (days) is passed',
                        "(must be an unsigned integer)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.Rollback(0.5)
                    end)
                end)
            end)
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

    describe("world", function()
        describe("ForcePrecipitation()", function()
            describe("when no bool is passed", function()
                it("should return true", function()
                    assert.is_true(Remote.ForcePrecipitation(0.5))
                end)

                TestDebugString(function()
                    Remote.ForcePrecipitation()
                end, "[remote]", "Force precipitation:", "true")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.ForcePrecipitation()
                end, 'TheWorld:PushEvent("ms_forceprecipitation", true)')
            end)

            describe("when true is passed", function()
                it("should return true", function()
                    assert.is_true(Remote.ForcePrecipitation(true))
                end)

                TestDebugString(function()
                    Remote.ForcePrecipitation(true)
                end, "[remote]", "Force precipitation:", "true")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.ForcePrecipitation(true)
                end, 'TheWorld:PushEvent("ms_forceprecipitation", true)')
            end)

            describe("when false is passed", function()
                it("should return true", function()
                    assert.is_true(Remote.ForcePrecipitation(false))
                end)

                TestDebugString(function()
                    Remote.ForcePrecipitation(false)
                end, "[remote]", "Force precipitation:", "false")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.ForcePrecipitation(false)
                end, 'TheWorld:PushEvent("ms_forceprecipitation", false)')
            end)
        end)

        describe("Season()", function()
            describe("when a valid value is passed", function()
                describe("(autumn)", function()
                    it("should return true", function()
                        assert.is_true(Remote.Season("autumn"))
                    end)

                    TestDebugString(function()
                        Remote.Season("autumn")
                    end, "[remote]", "Season:", "autumn")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.Season("autumn")
                    end, 'TheWorld:PushEvent("ms_setseason", "autumn")')
                end)
            end)

            describe("when an invalid value is passed", function()
                describe("(foo)", function()
                    it("should return false", function()
                        assert.is_false(Remote.Season("foo"))
                    end)

                    TestDebugError(
                        function()
                            Remote.Season("foo")
                        end,
                        "SDK.Remote.Season():",
                        'Invalid argument (season) is passed',
                        "(must be a season: autumn, winter, spring or summer)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.Season("foo")
                    end)
                end)
            end)
        end)

        describe("SeasonLength()", function()
            describe("when a valid season is passed", function()
                describe("(autumn)", function()
                    describe("and a invalid length is passed", function()
                        describe("(-10)", function()
                            it("should return false", function()
                                assert.is_false(Remote.SeasonLength("autumn", -10))
                            end)

                            TestDebugError(
                                function()
                                    Remote.SeasonLength("autumn", -10)
                                end,
                                "SDK.Remote.SeasonLength():",
                                'Invalid argument (length) is passed',
                                "(must be an unsigned integer)"
                            )

                            TestSendRemoteExecuteWasNotCalled(function()
                                Remote.SeasonLength("autumn", -10)
                            end)
                        end)
                    end)

                    describe("and a valid length is passed", function()
                        describe("(10)", function()
                            it("should return true", function()
                                assert.is_true(Remote.SeasonLength("autumn", 10))
                            end)

                            TestDebugString(function()
                                Remote.SeasonLength("autumn", 10)
                            end, "[remote]", "Season length:", "autumn", "(10 days)")

                            TestSendRemoteExecuteWasCalled(function()
                                Remote.SeasonLength("autumn", 10)
                            end, 'TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 10 })') -- luacheck: only
                        end)
                    end)
                end)
            end)

            describe("when an invalid season is passed", function()
                describe("(foo)", function()
                    it("should return false", function()
                        assert.is_false(Remote.SeasonLength("foo", 10))
                    end)

                    TestDebugError(
                        function()
                            Remote.SeasonLength("foo", 10)
                        end,
                        "SDK.Remote.SeasonLength():",
                        'Invalid argument (season) is passed',
                        "(must be a season: autumn, winter, spring or summer)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.SeasonLength("foo", 10)
                    end)
                end)
            end)
        end)

        describe("SnowLevel()", function()
            describe("when not in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(true)
                end)

                it("should return false", function()
                    assert.is_false(Remote.SnowLevel(1))
                end)

                TestDebugError(
                    function()
                        Remote.SnowLevel(1)
                    end,
                    "SDK.Remote.SnowLevel():",
                    'Invalid world type',
                    "(must be in a forest)"
                )

                TestSendRemoteExecuteWasNotCalled(function()
                    Remote.SnowLevel(1)
                end)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(false)
                end)

                describe("and an invalid delta is passed", function()
                    describe("(2)", function()
                        it("should return false", function()
                            assert.is_false(Remote.SnowLevel(2))
                        end)

                        TestDebugError(
                            function()
                                Remote.SnowLevel(2)
                            end,
                            "SDK.Remote.SnowLevel():",
                            'Invalid argument (delta) is passed',
                            "(must be a unit interval)"
                        )

                        TestSendRemoteExecuteWasNotCalled(function()
                            Remote.SnowLevel(2)
                        end)
                    end)
                end)

                describe("when no delta is passed", function()
                    it("should return true", function()
                        assert.is_true(Remote.SnowLevel())
                    end)

                    TestDebugString(function()
                        Remote.SnowLevel()
                    end, "[remote]", "Snow level:", "0")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.SnowLevel()
                    end, 'TheWorld:PushEvent("ms_setsnowlevel", 0.00)')
                end)

                describe("when a valid delta is passed", function()
                    describe("(1)", function()
                        it("should return true", function()
                            assert.is_true(Remote.SnowLevel(1))
                        end)

                        TestDebugString(function()
                            Remote.SnowLevel(1)
                        end, "[remote]", "Snow level:", "1")

                        TestSendRemoteExecuteWasCalled(function()
                            Remote.SnowLevel(1)
                        end, 'TheWorld:PushEvent("ms_setsnowlevel", 1.00)')
                    end)
                end)
            end)
        end)

        describe("WorldDeltaMoisture()", function()
            describe("when an invalid delta is passed", function()
                describe("(foo)", function()
                    it("should return false", function()
                        assert.is_false(Remote.WorldDeltaMoisture("foo"))
                    end)

                    TestDebugError(
                        function()
                            Remote.WorldDeltaMoisture("foo")
                        end,
                        "SDK.Remote.WorldDeltaMoisture():",
                        'Invalid argument (delta) is passed',
                        "(must be a number)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.WorldDeltaMoisture("foo")
                    end)
                end)
            end)

            describe("when no delta is passed", function()
                it("should return true", function()
                    assert.is_true(Remote.WorldDeltaMoisture())
                end)

                TestDebugString(function()
                    Remote.WorldDeltaMoisture()
                end, "[remote]", "World delta moisture:", "0")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.WorldDeltaMoisture()
                end, 'TheWorld:PushEvent("ms_deltamoisture", 0)')
            end)

            describe("when a valid delta is passed", function()
                describe("(1)", function()
                    it("should return true", function()
                        assert.is_true(Remote.WorldDeltaMoisture(1))
                    end)

                    TestDebugString(function()
                        Remote.WorldDeltaMoisture(1)
                    end, "[remote]", "World delta moisture:", "1")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.WorldDeltaMoisture(1)
                    end, 'TheWorld:PushEvent("ms_deltamoisture", 1)')
                end)
            end)
        end)

        describe("WorldDeltaWetness()", function()
            describe("when an invalid delta is passed", function()
                describe("(foo)", function()
                    it("should return false", function()
                        assert.is_false(Remote.WorldDeltaWetness("foo"))
                    end)

                    TestDebugError(
                        function()
                            Remote.WorldDeltaWetness("foo")
                        end,
                        "SDK.Remote.WorldDeltaWetness():",
                        'Invalid argument (delta) is passed',
                        "(must be a number)"
                    )

                    TestSendRemoteExecuteWasNotCalled(function()
                        Remote.WorldDeltaWetness("foo")
                    end)
                end)
            end)

            describe("when no delta is passed", function()
                it("should return true", function()
                    assert.is_true(Remote.WorldDeltaWetness())
                end)

                TestDebugString(function()
                    Remote.WorldDeltaWetness()
                end, "[remote]", "World delta wetness:", "0")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.WorldDeltaWetness()
                end, 'TheWorld:PushEvent("ms_deltawetness", 0)')
            end)

            describe("when delta is passed", function()
                describe("(1)", function()
                    it("should return true", function()
                        assert.is_true(Remote.WorldDeltaWetness(1))
                    end)

                    TestDebugString(function()
                        Remote.WorldDeltaWetness(1)
                    end, "[remote]", "World delta wetness:", "1")

                    TestSendRemoteExecuteWasCalled(function()
                        Remote.WorldDeltaWetness(1)
                    end, 'TheWorld:PushEvent("ms_deltawetness", 1)')
                end)
            end)
        end)
    end)
end)
