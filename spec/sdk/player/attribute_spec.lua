require "busted.runner"()

describe("#sdk SDK.Player.Attribute", function()
    -- setup
    local match

    -- before_each test data
    local inst, player_dead, players

    -- before_each initialization
    local SDK
    local Attribute

    local function EachPlayer(fn, except, init_fn)
        except = except ~= nil and except or {}
        for _, player in pairs(players) do
            if not TableHasValue(except, player) then
                if init_fn ~= nil then
                    init_fn(player)
                end
                fn(player)
            end
        end
    end

    local function MockPlayerInst(guid, name, userid, states, tags)
        userid = userid ~= nil and userid or "KU_admin"
        states = states ~= nil and states or { "idle" }
        tags = tags ~= nil and tags or {}

        table.insert(tags, "player")

        if TableHasValue(states, "dead") then
            table.insert(tags, "playerghost")
        end

        if TableHasValue(states, "idle") then
            table.insert(tags, "idle")
        end

        if TableHasValue(states, "werehuman") then
            table.insert(tags, "werehuman")
        end

        return require("busted").mock({
            components = {
                health = {
                    SetPenalty = Empty,
                    SetPercent = Empty,
                },
                hunger = {
                    SetPercent = Empty,
                },
                moisture = {
                    SetPercent = Empty,
                },
                sanity = {
                    SetPercent = Empty,
                },
                temperature = {
                    SetTemperature = Empty,
                },
                wereness = {
                    SetPercent = Empty,
                },
            },
            GUID = guid,
            name = name,
            player_classified = {
                currentwereness = {
                    value = ReturnValueFn(1),
                },
            },
            replica = {
                health = {
                    GetPercent = ReturnValueFn(1),
                    GetPenaltyPercent = ReturnValueFn(.4),
                },
                hunger = {
                    GetPercent = ReturnValueFn(1),
                },
                sanity = {
                    GetPercent = ReturnValueFn(1),
                },
            },
            userid = userid,
            GetDisplayName = ReturnValueFn(name),
            GetMoisture = ReturnValueFn(20),
            GetTemperature = ReturnValueFn(36),
            HasTag = function(_, tag)
                return TableHasValue(tags, tag)
            end,
        })
    end

    setup(function()
        -- match
        match = require "luassert.match"

        -- globals
        _G.TUNING = {
            MIN_ENTITY_TEMP = -20,
            MAX_ENTITY_TEMP = 90,
        }
    end)

    teardown(function()
        -- globals
        _G.ThePlayer = nil
        _G.TheWorld = nil
        _G.TUNING = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- test data
        inst = MockPlayerInst(1, "PlayerInst", nil, { "idle", "werehuman" }, { "wereness" })
        player_dead = MockPlayerInst(2, "PlayerDead", "KU_one", { "dead", "idle" })

        players = {
            inst,
            player_dead,
        }

        -- globals
        _G.ThePlayer = inst
        _G.TheWorld = {}

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Player")
        SDK.LoadModule("Remote")
        Attribute = require "yoursubdirectory/sdk/sdk/player/attribute"

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function AssertDebugErrorInvalidArg(fn, fn_name, arg_name, explanation)
        _G.AssertDebugErrorInvalidArg(fn, Attribute, fn_name, arg_name, explanation)
    end

    local function AssertDebugString(fn, ...)
        _G.AssertDebugString(fn, "[player]", "[attribute]", ...)
    end

    local function TestArgPlayer(...)
        _G.TestArgPlayer(Attribute, ...)
    end

    describe("attributes", function()
        local function TestComponentIsAvailable(fn_name, name, setter, debug, value)
            describe("and a " .. name .. " component is available", function()
                local _component

                setup(function()
                    _component = _G.ThePlayer.components[name]
                end)

                before_each(function()
                    _G.ThePlayer.components[name] = mock({
                        [setter] = Empty,
                    })
                end)

                teardown(function()
                    _G.ThePlayer.components[name] = _component
                end)

                it("should debug string", function()
                    AssertDebugString(function()
                        Attribute[fn_name](25)
                    end, unpack(debug))
                end)

                it(
                    "should call [player].components." .. name .. ":" .. setter .. "()",
                    function()
                        assert.spy(_G.ThePlayer.components[name][setter]).was_not_called()
                        Attribute[fn_name](25)
                        assert.spy(_G.ThePlayer.components[name][setter]).was_called(1)
                        assert.spy(_G.ThePlayer.components[name][setter]).was_called_with(
                            match.is_ref(_G.ThePlayer.components[name]),
                            value
                        )
                    end
                )

                it("should return true", function()
                    assert.is_true(Attribute[fn_name](25))
                end)
            end)
        end

        local function TestComponentIsNotAvailable(fn_name, name)
            describe("and a " .. name .. " component is not available", function()
                local _component

                setup(function()
                    _component = _G.ThePlayer.components[name]
                end)

                before_each(function()
                    _G.ThePlayer.components[name] = nil
                end)

                teardown(function()
                    _G.ThePlayer.components[name] = _component
                end)

                it("should debug error string", function()
                    AssertDebugError(
                        function()
                            Attribute[fn_name](25)
                        end,
                        "SDK.Player.Attribute." .. fn_name .. "():",
                        name:gsub("^%l", string.upper),
                        "component is not available",
                        "(" .. _G.ThePlayer:GetDisplayName() .. ")"
                    )
                end)

                it("should return false", function()
                    assert.is_false(Attribute[fn_name](25))
                end)
            end)
        end

        local function TestGetAttribute(name, fn_name)
            describe(name .. "()", function()
                TestArgPlayer(name, {
                    empty = {},
                    invalid = { "foo" },
                    valid = { _G.ThePlayer },
                })

                it("should return [player]." .. fn_name .. "() value", function()
                    assert.is_equal(_G.ThePlayer[fn_name](_G.ThePlayer), Attribute[name]())
                end)

                it("should call [player]." .. fn_name .. "()", function()
                    assert.spy(_G.ThePlayer[fn_name]).was_not_called()
                    Attribute[name]()
                    assert.spy(_G.ThePlayer[fn_name]).was_called(1)
                    assert.spy(_G.ThePlayer[fn_name]).was_called_with(
                        match.is_ref(_G.ThePlayer)
                    )
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(Attribute[name]())
                        end, _G.ThePlayer, fn_name)
                    end)
                end)
            end)
        end

        local function TestGetReplicaAttributePercent(name, component, component_fn_name, value)
            describe(name .. "()", function()
                TestArgPlayer(name, {
                    empty = {},
                    invalid = { "foo" },
                })

                describe("when [player].replica.health is available", function()
                    it("should call the [player].replica.health:GetPercent()", function()
                        EachPlayer(function(player)
                            assert.spy(player.replica[component][component_fn_name])
                                .was_not_called()
                            Attribute[name](player)
                            assert.spy(player.replica[component][component_fn_name]).was_called(1)
                            assert.spy(player.replica[component][component_fn_name])
                                .was_called_with(match.is_ref(player.replica[component]))
                        end)
                    end)

                    it("should return the " .. component .. " percent", function()
                        EachPlayer(function(player)
                            assert.is_equal(value, Attribute[name](player))
                        end)
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        EachPlayer(function(player)
                            AssertChainNil(function()
                                assert.is_nil(Attribute[name](player))
                            end, player, "replica", component)
                        end)
                    end)
                end)
            end)
        end

        local function TestInvalidPercentIsPassed(fn_name)
            describe("when an invalid percent is passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Attribute[fn_name]("foo")
                    end, fn_name, "percent", "must be a percent")
                end)

                it("should return false", function()
                    assert.is_false(Attribute[fn_name]("foo"))
                end)
            end)
        end

        local function TestInvalidPlayerIsPassed(fn_name)
            describe("when an invalid player is passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Attribute[fn_name](25, "foo")
                    end, fn_name, "player", "must be a player")
                end)

                it("should return false", function()
                    assert.is_false(Attribute[fn_name](25, "foo"))
                end)
            end)
        end

        local function TestPlayerIsGhost(fn_name)
            describe("when a player is a ghost", function()
                it("should debug error string", function()
                    AssertDebugError(
                        function()
                            Attribute[fn_name](25, player_dead)
                        end,
                        string.format("SDK.Player.Attribute.%s():", fn_name),
                        "Player shouldn't be a ghost"
                    )
                end)

                it("should return false", function()
                    assert.is_false(Attribute[fn_name](25, player_dead))
                end)
            end)
        end

        local function TestRemoteSetReturnsFalse(fn_name, name, setter)
            describe("and SDK.Remote.Player." .. fn_name .. "() returns false", function()
                local _fn

                setup(function()
                    _fn = SDK.Remote.Player[fn_name]
                end)

                before_each(function()
                    SDK.Remote.Player[fn_name] = spy.new(ReturnValueFn(false))
                end)

                teardown(function()
                    SDK.Remote.Player[fn_name] = _fn
                end)

                it(
                    "shouldn't call [player].components." .. name .. ":" .. fn_name .. "()",
                    function()
                        assert.spy(_G.ThePlayer.components[name][setter]).was_not_called()
                        Attribute[fn_name](25)
                        assert.spy(_G.ThePlayer.components[name][setter]).was_not_called()
                    end
                )

                it("should call SDK.Remote.Player.SetWerenessPercent()", function()
                    assert.spy(SDK.Remote.Player[fn_name]).was_not_called()
                    Attribute[fn_name](25)
                    assert.spy(SDK.Remote.Player[fn_name]).was_called(1)
                    assert.spy(SDK.Remote.Player[fn_name]).was_called_with(
                        25,
                        _G.ThePlayer
                    )
                end)

                it("should return false", function()
                    assert.is_false(Attribute[fn_name](25))
                end)
            end)
        end

        local function TestRemoteSetReturnsTrue(fn_name, name, setter)
            describe("and SDK.Remote.Player." .. fn_name .. "() returns true", function()
                local _fn

                setup(function()
                    _fn = SDK.Remote.Player[fn_name]
                end)

                before_each(function()
                    SDK.Remote.Player[fn_name] = spy.new(ReturnValueFn(true))
                end)

                teardown(function()
                    SDK.Remote.Player[fn_name] = _fn
                end)

                it(
                    "shouldn't call [player].components." .. name .. ":" .. fn_name .. "()",
                    function()
                        assert.spy(_G.ThePlayer.components[name][setter]).was_not_called()
                        Attribute[fn_name](25)
                        assert.spy(_G.ThePlayer.components[name][setter]).was_not_called()
                    end
                )

                it("should call SDK.Remote.Player.SetWerenessPercent()", function()
                    assert.spy(SDK.Remote.Player[fn_name]).was_not_called()
                    Attribute[fn_name](25)
                    assert.spy(SDK.Remote.Player[fn_name]).was_called(1)
                    assert.spy(SDK.Remote.Player[fn_name]).was_called_with(
                        25,
                        _G.ThePlayer
                    )
                end)

                it("should return true", function()
                    assert.is_true(Attribute[fn_name](25))
                end)
            end)
        end

        local function TestSetComponentPercent(fn_name, name, debug, setter, is_reversed)
            setter = setter ~= nil and setter or "SetPercent"

            describe(fn_name .. "()", function()
                TestInvalidPercentIsPassed(fn_name)
                TestInvalidPlayerIsPassed(fn_name)
                TestPlayerIsGhost(fn_name)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestComponentIsAvailable(
                        fn_name,
                        name,
                        setter,
                        debug,
                        is_reversed and 0.75 or 0.25
                    )

                    TestComponentIsNotAvailable(fn_name, name)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    TestRemoteSetReturnsFalse(fn_name, name, setter)
                    TestRemoteSetReturnsTrue(fn_name, name, setter)
                end)
            end)
        end

        describe("GetHealthLimitPercent()", function()
            describe("when a health replica is available", function()
                it("should call [player].replica.health:GetPenaltyPercent()", function()
                    EachPlayer(function(player)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_not_called()
                        Attribute.GetHealthLimitPercent(player)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_called(1)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_called_with(
                            match.is_ref(player.replica.health)
                        )
                    end)
                end)

                it("should return the maximum health percent", function()
                    EachPlayer(function(player)
                        assert.is_equal(60, Attribute.GetHealthLimitPercent(player))
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        AssertChainNil(function()
                            assert.is_nil(Attribute.GetHealthLimitPercent(player))
                        end, player, "replica", "health")
                    end)
                end)
            end)
        end)

        TestGetReplicaAttributePercent("GetHealthPenaltyPercent", "health", "GetPenaltyPercent", 40)
        TestGetReplicaAttributePercent("GetHealthPercent", "health", "GetPercent", 100)
        TestGetReplicaAttributePercent("GetHungerPercent", "hunger", "GetPercent", 100)
        TestGetAttribute("GetMoisturePercent", "GetMoisture")
        TestGetReplicaAttributePercent("GetSanityPercent", "sanity", "GetPercent", 100)
        TestGetAttribute("GetTemperature", "GetTemperature")

        describe("GetWerenessPercent()", function()
            it("should return [player].player_classified.currentwereness:value() value", function()
                assert.is_equal(
                    _G.ThePlayer.player_classified.currentwereness:value(),
                    Attribute.GetWerenessPercent()
                )
            end)

            it("should call [player].player_classified.currentwereness:value()", function()
                assert.spy(_G.ThePlayer.player_classified.currentwereness.value).was_not_called()
                Attribute.GetWerenessPercent()
                assert.spy(_G.ThePlayer.player_classified.currentwereness.value).was_called(1)
                assert.spy(_G.ThePlayer.player_classified.currentwereness.value).was_called_with(
                    match.is_ref(_G.ThePlayer.player_classified.currentwereness)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Attribute.GetWerenessPercent())
                    end, _G.ThePlayer, "player_classified", "currentwereness", "value")
                end)
            end)
        end)

        TestSetComponentPercent("SetHealthLimitPercent", "health", {
            "Health limit:",
            "25.00%",
            "(PlayerInst)",
        }, "SetPenalty", true)

        TestSetComponentPercent("SetHealthPenaltyPercent", "health", {
            "Health penalty:",
            "25.00%",
            "(PlayerInst)",
        }, "SetPenalty")

        TestSetComponentPercent("SetHealthPercent", "health", {
            "Health:",
            "25.00%",
            "(PlayerInst)",
        })

        TestSetComponentPercent("SetHungerPercent", "hunger", {
            "Hunger:",
            "25.00%",
            "(PlayerInst)",
        })

        TestSetComponentPercent("SetMoisturePercent", "moisture", {
            "Moisture:",
            "25.00%",
            "(PlayerInst)",
        })

        TestSetComponentPercent("SetSanityPercent", "sanity", {
            "Sanity:",
            "25.00%",
            "(PlayerInst)",
        })

        describe("SetTemperature()", function()
            describe("when an invalid percent is passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        Attribute.SetTemperature("foo")
                    end, "SetTemperature", "temperature", "must be an entity temperature")
                end)

                it("should return false", function()
                    assert.is_false(Attribute.SetTemperature("foo"))
                end)
            end)

            TestInvalidPlayerIsPassed("SetTemperature")
            TestPlayerIsGhost("SetTemperature")

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestComponentIsAvailable("SetTemperature", "temperature", "SetTemperature", {
                    "Temperature:",
                    "25.00°",
                    "(PlayerInst)",
                }, 25)

                TestComponentIsNotAvailable("SetTemperature", "temperature")
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteSetReturnsFalse("SetTemperature", "temperature", "SetTemperature")
                TestRemoteSetReturnsTrue("SetTemperature", "temperature", "SetTemperature")
            end)
        end)

        describe("SetWerenessPercent()", function()
            TestInvalidPercentIsPassed("SetWerenessPercent")
            TestInvalidPlayerIsPassed("SetWerenessPercent")
            TestPlayerIsGhost("SetWerenessPercent")

            describe("when a player is a ghost", function()
                it("should debug error string", function()
                    AssertDebugError(
                        function()
                            Attribute.SetWerenessPercent(25, player_dead)
                        end,
                        "SDK.Player.Attribute.SetWerenessPercent():",
                        "Player shouldn't be a ghost"
                    )
                end)

                it("should return false", function()
                    assert.is_false(Attribute.SetWerenessPercent(25, player_dead))
                end)
            end)

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                TestComponentIsAvailable("SetWerenessPercent", "wereness", "SetPercent", {
                    "Wereness:",
                    "25.00%",
                    "(PlayerInst)",
                }, 0.25)

                TestComponentIsNotAvailable("SetWerenessPercent", "wereness")
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                TestRemoteSetReturnsFalse("SetWerenessPercent", "wereness", "SetPercent")
                TestRemoteSetReturnsTrue("SetTemperature", "wereness", "SetPercent")
            end)
        end)
    end)
end)
