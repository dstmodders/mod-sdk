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

        SetTestModule(Player)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        _G.AssertDebugErrorInvalidArg(fn, Player, fn_name, arg_name, explanation)
    end

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.Remote.Player." .. fn_name .. "():", ...)
    end

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[remote]", "[player]", ...)
    end

    local function TestSendRemoteExecuteCalls(fn, calls, ...)
        local args = { ... }
        it((calls > 0 and "should" or "shouldn't")
            .. " call TheNet:SendRemoteExecute()", function()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
            fn()
            assert.spy(_G.TheNet.SendRemoteExecute).was_called(calls)
            if calls > 0 and #args > 0 then
                assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                    match.is_ref(_G.TheNet),
                    unpack(args),
                    1,
                    3
                )
            end
        end)
    end

    local function TestSendRemoteExecute(fn, ...)
        TestSendRemoteExecuteCalls(fn, 1, ...)
    end

    local function TestRemotePlayerIsGhost(name, player, ...)
        local args = { ..., player }
        describe("when a player is a ghost", function()
            local _HasTag

            local fn = function()
                return Player[name](unpack(args))
            end

            before_each(function()
                _HasTag = player.HasTag
                player.HasTag = spy.new(function(_, tag)
                    return tag == "player" or tag == "playerghost"
                end)
            end)

            after_each(function()
                player.HasTag = _HasTag
            end)

            TestDebugError(fn, name, "Player shouldn't be a ghost")
            TestSendRemoteExecuteCalls(fn, 0)
            TestReturnFalse(fn)
        end)
    end

    local function TestRemoteValid(name, debug, send, ...)
        _G.TestRemoteValid(name, {
            debug = {
                name = "player",
                args = debug,
            },
            send = {
                data = send,
                x = 1,
                z = 3,
            },
        }, ...)
    end

    describe("general", function()
        describe("GatherPlayers()", function()
            TestRemoteValid("GatherPlayers", { "Gather players" }, "c_gatherplayers()")
        end)

        describe("GoNext()", function()
            TestRemoteInvalid("GoNext", nil, "string")
            TestRemoteValid("GoNext", {
                "Go next:",
                "foobar",
            }, 'c_gonext("foobar")', "foobar")
        end)
    end)

    describe("attribute", function()
        local function TestSetAttributePercent(name, debug, send)
            describe(name .. "()", function()
                TestArgPercent(name, {
                    empty = {
                        args = { nil, _G.ThePlayer },
                        calls = 1,
                    },
                    invalid = { "foo", _G.ThePlayer },
                    valid = { 25, _G.ThePlayer },
                })

                TestArgPlayer(name, {
                    empty = { 25 },
                    invalid = { 25, "foo" },
                    valid = { 25, _G.ThePlayer },
                })

                describe("when a player is not a ghost", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag ~= "playerghost"
                        end)
                    end)

                    TestRemoteInvalid(name, nil, "foo")
                    TestRemoteInvalid(name, nil, 25, "foo")
                    TestRemoteValid(name, debug, send, 25, _G.ThePlayer)
                end)

                TestRemotePlayerIsGhost(name, _G.ThePlayer, 25)
            end)
        end

        TestSetAttributePercent(
            "SetHealthLimitPercent",
            { "Health limit:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.health:SetPenalty(0.75)'
        )

        TestSetAttributePercent(
            "SetHealthPenaltyPercent",
            { "Health penalty:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.health:SetPenalty(0.25)'
        )

        TestSetAttributePercent(
            "SetHealthPercent",
            { "Health:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.health:SetPercent(0.25)'
        )

        TestSetAttributePercent(
            "SetHungerPercent",
            { "Hunger:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.hunger:SetPercent(0.25)'
        )

        TestSetAttributePercent(
            "SetMoisturePercent",
            { "Moisture:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.moisture:SetPercent(0.25)'
        )

        TestSetAttributePercent(
            "SetSanityPercent",
            { "Sanity:", "25.00%", "(Player)" },
            'LookupPlayerInstByUserID("KU_foobar").components.sanity:SetPercent(0.25)'
        )

        describe("SetTemperature()", function()
            local fn_name = "SetTemperature"

            TestArg(fn_name, "temperature", "must be an entity temperature", {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "foo", _G.ThePlayer },
                valid = { 25, _G.ThePlayer },
            })

            TestArgPlayer(fn_name, {
                empty = { 25 },
                invalid = { 25, "foo" },
                valid = { 25, _G.ThePlayer },
            })

            describe("when a player is not a ghost", function()
                before_each(function()
                    _G.ThePlayer.HasTag = spy.new(function(_, tag)
                        return tag ~= "playerghost"
                    end)
                end)

                TestRemoteInvalid(fn_name, nil, "foo")
                TestRemoteInvalid(fn_name, nil, 25, "foo")

                TestRemoteValid(
                    fn_name,
                    { "Temperature:", "25.00°", "(Player)" },
                    'LookupPlayerInstByUserID("KU_foobar")'
                        .. ".components.temperature:SetTemperature(25)",
                    25,
                    _G.ThePlayer
                )
            end)

            TestRemotePlayerIsGhost(fn_name, _G.ThePlayer, 25)
        end)

        describe("SetWerenessPercent()", function()
            _G.ThePlayer.HasTag = spy.new(function(_, tag)
                return tag == "player" or tag == "werehuman"
            end)

            TestArgPercent("SetWerenessPercent", {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "foo", _G.ThePlayer },
                valid = { 25, _G.ThePlayer },
            })

            TestArgPlayer("SetWerenessPercent", {
                empty = { 25 },
                invalid = { 25, "foo" },
                valid = { 25, _G.ThePlayer },
            })

            describe("when a player is not a ghost", function()
                local fn = function()
                    return Player.SetWerenessPercent(25, _G.ThePlayer)
                end

                describe("and a player is a Woodie", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag == "player" or tag == "werehuman"
                        end)
                    end)

                    describe("when valid arguments are passed", function()
                        TestDebugString(fn, "Wereness:", "25.00%", "(Player)")
                        TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar")'
                            .. ".components.wereness:SetPercent(0.25)")
                        TestReturnTrue(fn)
                    end)

                    TestRemoteInvalid("SetWerenessPercent", nil, "foo")
                    TestRemoteInvalid("SetWerenessPercent", nil, 25, "foo")
                end)

                describe("and a player is not a Woodie", function()
                    before_each(function()
                        _G.ThePlayer.HasTag = spy.new(function(_, tag)
                            return tag == "player"
                        end)
                    end)

                    describe("when valid arguments are passed", function()
                        TestDebugError(fn, "SetWerenessPercent", "Player should be a Woodie")
                        TestSendRemoteExecuteCalls(fn, 0)
                        TestReturnFalse(fn)
                    end)

                    TestRemoteInvalid("SetWerenessPercent", nil, "foo")
                    TestRemoteInvalid("SetWerenessPercent", nil, 25, "foo")
                end)
            end)

            TestRemotePlayerIsGhost("SetWerenessPercent", _G.ThePlayer, 25)
        end)
    end)

    describe("call", function()
        local args_invalid, args_valid

        setup(function()
            args_invalid =  { _G.TheSim }
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
            TestArgPlayer("CallFn", {
                empty = { "Foo", "foo" },
                invalid = { "Foo", "foo", "foo" },
                valid = { "Foo", "foo", _G.ThePlayer },
            })

            describe("when serialized argument is passed", function()
                local fn = function()
                    return Player.CallFn("Foo", "foo")
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar"):Foo("foo")')
                TestReturnTrue(fn)
            end)

            describe("when serialized arguments are passed", function()
                local fn = function()
                    return Player.CallFn("Foo", args_valid)
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar"):Foo('
                        .. '"foo", '
                        .. '"bar", '
                        .. "0, "
                        .. "1, "
                        .. "true, "
                        .. "false, "
                        .. 'LookupPlayerInstByUserID("KU_foobar")'
                    .. ")")
                TestReturnTrue(fn)
            end)

            describe("when nil argument is passed", function()
                local fn = function()
                    return Player.CallFn("Foo")
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar"):Foo()')
                TestReturnTrue(fn)
            end)

            describe("when non-serialized arguments are passed", function()
                local fn = function()
                    return Player.CallFn("Foo", args_invalid)
                end

                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(fn, "CallFn", "args", "can't be serialized")
                end)

                TestSendRemoteExecuteCalls(fn, 0)
                TestReturnFalse(fn)
            end)
        end)

        describe("CallFnComponent()", function()
            TestArgPlayer("CallFnComponent", {
                empty = { "foo", "Bar", "foo" },
                invalid = { "foo", "Bar", "foo", "foo" },
                valid = { "foo", "Bar", "foo", _G.ThePlayer },
            })

            describe("when serialized argument is passed", function()
                local fn = function()
                    return Player.CallFnComponent("foo", "Bar", "foo")
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar")'
                    .. '.components.foo:Bar("foo")')
                TestReturnTrue(fn)
            end)

            describe("when serialized arguments are passed", function()
                local fn = function()
                    return Player.CallFnComponent("foo", "Bar", args_valid)
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar")'
                    .. ".components.foo:Bar("
                        .. '"foo", '
                        .. '"bar", '
                        .. "0, "
                        .. "1, "
                        .. "true, "
                        .. "false, "
                        .. 'LookupPlayerInstByUserID("KU_foobar")'
                    .. ")")
                TestReturnTrue(fn)
            end)

            describe("when nil argument is passed", function()
                local fn = function()
                    return Player.CallFnComponent("foo", "Bar")
                end

                TestSendRemoteExecute(fn, 'LookupPlayerInstByUserID("KU_foobar")'
                    .. ".components.foo:Bar()")
                TestReturnTrue(fn)
            end)

            describe("when non-serialized arguments are passed", function()
                local fn = function()
                    return Player.CallFnComponent("foo", "Bar", args_invalid)
                end

                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(fn, "CallFnComponent", "args", "can't be serialized")
                end)

                TestSendRemoteExecuteCalls(fn, 0)
                TestReturnFalse(fn)
            end)
        end)
    end)

    describe("craft", function()
        describe("LockRecipe()", function()
            local fn_name = "LockRecipe"

            TestArgRecipe(fn_name, {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "string", _G.ThePlayer },
                valid = { "foo", _G.ThePlayer },
            })

            TestArgPlayer(fn_name, {
                empty = { "foo" },
                invalid = { "foo", "foo" },
                valid = { "foo", _G.ThePlayer },
            })

            TestRemoteInvalid(fn_name, nil, "string")
            TestRemoteInvalid(fn_name, nil, "foo", "foo")
            TestRemoteValid(
                fn_name,
                { "Lock recipe:", "foo", "(Player)" },
                'player = LookupPlayerInstByUserID("KU_foobar") '
                    .. "for k, v in pairs(player.components.builder.recipes) do "
                        .. 'if v == "foo" then '
                            .. "table.remove(player.components.builder.recipes, k) "
                        .. "end "
                    .. "end "
                    .. 'player.replica.builder:RemoveRecipe("foo")',
                "foo",
                _G.ThePlayer
            )
        end)

        describe("UnlockRecipe()", function()
            local fn_name = "UnlockRecipe"

            TestArgRecipe(fn_name, {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "string", _G.ThePlayer },
                valid = { "foo", _G.ThePlayer },
            })

            TestArgPlayer(fn_name, {
                empty = { "foo" },
                invalid = { "foo", "foo" },
                valid = { "foo", _G.ThePlayer },
            })

            TestRemoteInvalid(fn_name, nil, "string")
            TestRemoteInvalid(fn_name, nil, "foo", "foo")
            TestRemoteValid(
                fn_name,
                { "Unlock recipe:", "foo", "(Player)" },
                'player = LookupPlayerInstByUserID("KU_foobar") '
                    .. 'player.components.builder:AddRecipe("foo") '
                    .. 'player:PushEvent("unlockrecipe", { recipe = "foo" })',
                "foo",
                _G.ThePlayer
            )
        end)

        describe("ToggleFreeCrafting()", function()
            TestRemoteInvalid("ToggleFreeCrafting", nil, "foo")
            TestRemoteValid(
                "ToggleFreeCrafting", {
                    "Toggle free crafting:",
                    "Player",
                },
                'player = LookupPlayerInstByUserID("KU_foobar") '
                    .. "player.components.builder:GiveAllRecipes() "
                    .. 'player:PushEvent("techlevelchange")',
                _G.ThePlayer
            )
        end)
    end)
end)
