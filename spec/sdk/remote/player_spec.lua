require "busted.runner"()

describe("#sdk SDK.Remote.Player", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Player

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
        Player = SDK.Remote.Player

        -- spies
        SDK.Debug.Error = spy.on(SDK.Debug, "Error")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
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
            string.format("SDK.Remote.Player.%s():", fn_name),
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
                        Player[name](unpack(args))
                    end,
                    string.format("SDK.Remote.Player.%s():", name),
                    msg,
                    explanation and "(" .. explanation .. ")"
                )
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Player[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Player[name](unpack(args)))
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
                    Player[name](unpack(args))
                end, name, arg_name, explanation)
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Player[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Player[name](unpack(args)))
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
                        Player[name](unpack(args))
                    end,
                    string.format("SDK.Remote.Player.%s():", name),
                    "Player shouldn't be a ghost"
                )
            end)

            it("shouldn't call TheSim:SendRemoteExecute()", function()
                AssertSendWasNotCalled(function()
                    Player[name](unpack(args))
                end)
            end)

            it("should return false", function()
                assert.is_false(Player[name](unpack(args)))
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
                    Player[name](unpack(args))
                end, "[remote]", "[player]", unpack(debug))
            end)

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(function()
                    Player[name](unpack(args))
                end, send)
            end)

            it("should return true", function()
                assert.is_true(Player[name](unpack(args)))
            end)
        end)
    end

    describe("general", function()
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

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "radius",
                    "must be an unsigned integer",
                    "foo",
                    20,
                    2.5,
                    _G.ThePlayer
                )

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "amount",
                    "must be an unsigned integer",
                    20,
                    -10,
                    2.5,
                    _G.ThePlayer
                )

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "duration",
                    "must be an unsigned number",
                    20,
                    20,
                    true,
                    _G.ThePlayer
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
                    20,
                    20,
                    2.5,
                    _G.ThePlayer
                )
            end)
        end)
    end)

    describe("attributes", function()
        local function TestSetAttributePercent(name, debug, send)
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

        TestSetAttributePercent(
            "SetHealthLimitPercent",
            { "Player health limit:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPenalty(0.75) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetHealthPercent",
            { "Player health:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetHungerPercent",
            { "Player hunger:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.hunger then player.components.hunger:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetMoisturePercent",
            { "Player moisture:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.moisture then player.components.moisture:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetSanityPercent",
            { "Player sanity:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.sanity then player.components.sanity:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        describe("SetTemperature()", function()
            describe("when a player is not a ghost", function()
                before_each(function()
                    _G.ThePlayer.HasTag = spy.new(function(_, tag)
                        return tag ~= "playerghost"
                    end)
                end)

                TestRemoteInvalidArg(
                    "SetTemperature",
                    "value",
                    "must be an entity temperature",
                    "foo"
                )

                TestRemoteInvalidArg(
                    "SetTemperature",
                    "player",
                    "must be a player",
                    25,
                    "foo"
                )

                TestRemoteValid(
                    "SetTemperature",
                    { "Player temperature:", "25.00°", "(Player)" },
                    'player = LookupPlayerInstByUserID("KU_foobar") if player.components.temperature then player.components.temperature:SetTemperature(25.00) end', -- luacheck: only
                    25,
                    _G.ThePlayer
                )
            end)

            TestRemotePlayerIsGhost("SetTemperature", _G.ThePlayer, 25)
        end)

        describe("SetWerenessPercent()", function()
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
                                Player.SetWerenessPercent(25, _G.ThePlayer)
                            end, "[remote]", "[player]", "Player wereness:", "25.00%", "(Player)")
                        end)

                        it("should call TheSim:SendRemoteExecute()", function()
                            AssertSendWasCalled(function()
                                Player.SetWerenessPercent(25, _G.ThePlayer)
                            end, 'player = LookupPlayerInstByUserID("KU_foobar") if player.components.wereness then player.components.wereness:SetPercent(math.min(0.25, 1)) end') -- luacheck: only
                        end)

                        it("should return true", function()
                            assert.is_true(Player.SetWerenessPercent(25, _G.ThePlayer))
                        end)
                    end)

                    TestRemoteInvalidArg(
                        "SetWerenessPercent",
                        "percent",
                        "must be a percent",
                        "foo"
                    )

                    TestRemoteInvalidArg(
                        "SetWerenessPercent",
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
                                    Player.SetWerenessPercent(25, _G.ThePlayer)
                                end,
                                "SDK.Remote.Player.SetWerenessPercent():",
                                "Player should be a Woodie"
                            )
                        end)

                        it("shouldn't call TheSim:SendRemoteExecute()", function()
                            AssertSendWasNotCalled(function()
                                Player.SetWerenessPercent(25, _G.ThePlayer)
                            end)
                        end)

                        it("should return false", function()
                            assert.is_false(Player.SetWerenessPercent(25, _G.ThePlayer))
                        end)
                    end)

                    TestRemoteInvalidArg(
                        "SetWerenessPercent",
                        "percent",
                        "must be a percent",
                        "foo"
                    )

                    TestRemoteInvalidArg(
                        "SetWerenessPercent",
                        "player",
                        "must be a player",
                        25,
                        "foo"
                    )
                end)
            end)

            TestRemotePlayerIsGhost("SetWerenessPercent", _G.ThePlayer, 25)
        end)
    end)
end)
