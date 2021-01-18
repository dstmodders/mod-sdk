require "busted.runner"()

describe("#sdk SDK.Remote.Player", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Player

    setup(function()
        -- match
        match = require "luassert.match"

        -- globals
        _G.AllRecipes = {
            foo = {},
            bar = {},
            foobar = {},
        }

        _G.IsRecipeValid = spy.new(function(recipe)
            return _G.AllRecipes[recipe] and true or false
        end)

        _G.PREFABFILES = { "foo", "bar", "foobar" }

        _G.TUNING = {
            MIN_ENTITY_TEMP = -20,
            MAX_ENTITY_TEMP = 90,
        }
    end)

    teardown(function()
        -- globals
        _G.AllRecipes = nil
        _G.IsRecipeValid = nil
        _G.PREFABFILES = nil
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

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        _G.AssertDebugErrorInvalidArg(fn, Player, fn_name, arg_name, explanation)
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
        describe("GatherPlayers()", function()
            TestRemoteValid("GatherPlayers", { "Gather players" }, "c_gatherplayers()")
        end)

        describe("GoNext()", function()
            TestRemoteInvalidArg("GoNext", "prefab", "must be a prefab", "string")
            TestRemoteValid("GoNext", {
                "Go next:",
                "foobar",
            }, 'c_gonext("foobar")', "foobar")
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

                TestRemoteInvalidArg(
                    "SendMiniEarthquake",
                    "player",
                    "must be a player",
                    20,
                    20,
                    2.5,
                    "foo"
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

        describe("ToggleFreeCrafting()", function()
            TestRemoteInvalidArg("ToggleFreeCrafting", "player", "must be a player", "foo")
            TestRemoteValid("ToggleFreeCrafting", {
                "Toggle free crafting:",
                "Player",
            }, 'player = LookupPlayerInstByUserID("KU_foobar") player.components.builder:GiveAllRecipes() player:PushEvent("techlevelchange")', _G.ThePlayer) -- luacheck: only
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
            { "Health limit:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPenalty(0.75) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetHealthPenaltyPercent",
            { "Health penalty:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPenalty(0.25) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetHealthPercent",
            { "Health:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.health then player.components.health:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetHungerPercent",
            { "Hunger:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.hunger then player.components.hunger:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetMoisturePercent",
            { "Moisture:", "25.00%", "(Player)" },
            'player = LookupPlayerInstByUserID("KU_foobar") if player.components.moisture then player.components.moisture:SetPercent(math.min(0.25, 1)) end' -- luacheck: only
        )

        TestSetAttributePercent(
            "SetSanityPercent",
            { "Sanity:", "25.00%", "(Player)" },
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
                    "temperature",
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
                    { "Temperature:", "25.00°", "(Player)" },
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
                            end, "[remote]", "[player]", "Wereness:", "25.00%", "(Player)")
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

    describe("call", function()
        local args_invalid, args_valid

        setup(function()
            args_invalid =  { {} }
            args_valid = {
                "foo",
                "bar",
                0,
                1,
                true,
                false,
                ThePlayer,
            }
        end)

        describe("CallFn()", function()
            describe("when serialized arguments are passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Player.CallFn("Foo", args_valid)
                    end, 'player = LookupPlayerInstByUserID("KU_foobar") '
                        .. "player:Foo("
                            .. '"foo", '
                            .. '"bar", '
                            .. "0, "
                            .. "1, "
                            .. "true, "
                            .. "false, "
                            .. 'LookupPlayerInstByUserID("KU_foobar")'
                        .. ")")
                end)

                it("should return true", function()
                    assert.is_true(Player.CallFn("Foo", args_valid))
                end)
            end)

            describe("when non-serialized arguments are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Player.CallFn("Foo", args_invalid)
                    end, "CallFn", "args", "can't be serialized")
                end)

                it("shouldn't call TheSim:SendRemoteExecute()", function()
                    AssertSendWasNotCalled(function()
                        Player.CallFn("Foo", args_invalid)
                    end)
                end)

                it("should return false", function()
                    assert.is_false(Player.CallFn("Foo", args_invalid))
                end)
            end)
        end)

        describe("CallFnComponent()", function()
            describe("when serialized arguments are passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Player.CallFnComponent("foo", "Bar", args_valid)
                    end, 'player = LookupPlayerInstByUserID("KU_foobar") '
                        .. "player.components.foo:Bar("
                            .. '"foo", '
                            .. '"bar", '
                            .. "0, "
                            .. "1, "
                            .. "true, "
                            .. "false, "
                            .. 'LookupPlayerInstByUserID("KU_foobar")'
                        .. ")")
                end)

                it("should return true", function()
                    assert.is_true(Player.CallFnComponent("foo", "Bar", args_valid))
                end)
            end)

            describe("when non-serialized arguments are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Player.CallFnComponent("foo", "Bar", args_invalid)
                    end, "CallFnComponent", "args", "can't be serialized")
                end)

                it("shouldn't call TheSim:SendRemoteExecute()", function()
                    AssertSendWasNotCalled(function()
                        Player.CallFnComponent("foo", "Bar", args_invalid)
                    end)
                end)

                it("should return false", function()
                    assert.is_false(Player.CallFnComponent("foo", "Bar", args_invalid))
                end)
            end)
        end)

        describe("CallFnReplica()", function()
            describe("when serialized arguments are passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Player.CallFnReplica("foo", "Bar", args_valid)
                    end, 'player = LookupPlayerInstByUserID("KU_foobar") '
                        .. "player.replica.foo:Bar("
                            .. '"foo", '
                            .. '"bar", '
                            .. "0, "
                            .. "1, "
                            .. "true, "
                            .. "false, "
                            .. 'LookupPlayerInstByUserID("KU_foobar")'
                        .. ")")
                end)

                it("should return true", function()
                    assert.is_true(Player.CallFnReplica("foo", "Bar", args_valid))
                end)
            end)

            describe("when non-serialized arguments are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Player.CallFnReplica("foo", "Bar", args_invalid)
                    end, "CallFnReplica", "args", "can't be serialized")
                end)

                it("shouldn't call TheSim:SendRemoteExecute()", function()
                    AssertSendWasNotCalled(function()
                        Player.CallFnReplica("foo", "Bar", args_invalid)
                    end)
                end)

                it("should return false", function()
                    assert.is_false(Player.CallFnReplica("foo", "Bar", args_invalid))
                end)
            end)
        end)
    end)

    describe("recipe", function()
        describe("LockRecipe()", function()
            TestRemoteInvalidArg("LockRecipe", "recipe", "must be a valid recipe", "string")
            TestRemoteInvalidArg("LockRecipe", "player", "must be a player", "foo", "foo")
            TestRemoteValid(
                "LockRecipe",
                { "Lock recipe:", "foo", "(Player)" },
                'player = LookupPlayerInstByUserID("KU_foobar") for k, v in pairs(player.components.builder.recipes) do if v == "foo" then table.remove(player.components.builder.recipes, k) end end player.replica.builder:RemoveRecipe("foo")', -- luacheck: only
                "foo",
                _G.ThePlayer
            )
        end)

        describe("UnlockRecipe()", function()
            TestRemoteInvalidArg("UnlockRecipe", "recipe", "must be a valid recipe", "string")
            TestRemoteInvalidArg("UnlockRecipe", "player", "must be a player", "foo", "foo")
            TestRemoteValid(
                "UnlockRecipe",
                { "Unlock recipe:", "foo", "(Player)" },
                'player = LookupPlayerInstByUserID("KU_foobar") player.components.builder:AddRecipe("foo") player:PushEvent("unlockrecipe", { recipe = "foo" })', -- luacheck: only
                "foo",
                _G.ThePlayer
            )
        end)
    end)
end)
