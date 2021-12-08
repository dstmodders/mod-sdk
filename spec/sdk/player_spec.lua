require("busted.runner")()

describe("#sdk SDK.Player", function()
    -- setup
    local match

    -- before_each test data
    local active_screen, inst
    local player_dead, player_hopping, player_over_water, player_running, player_sinking, players

    -- before_each initialization
    local SDK
    local Player

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

    local function MockTheNet(client_table)
        client_table = client_table ~= nil and client_table
            or {
                { userid = "KU_admin", admin = true },
                { userid = "KU_one", admin = false },
            }

        return require("busted").mock({
            GetClientTable = ReturnValueFn(client_table),
            GetClientTableForUser = ReturnValueFn(client_table[1]),
            GetServerIsClientHosted = ReturnValueFn(false),
            SendRemoteExecute = Empty,
            SendRPCToServer = Empty,
        })
    end

    local function MockPlayerInst(guid, name, userid, states, tags, position)
        userid = userid ~= nil and userid or "KU_admin"
        states = states ~= nil and states or { "idle" }
        tags = tags ~= nil and tags or {}
        position = position ~= nil and position or { 1, 2, 3 }

        local animation
        local state_tags = {}

        table.insert(tags, "player")

        if TableHasValue(states, "dead") then
            table.insert(tags, "playerghost")
        end

        if TableHasValue(states, "idle") then
            animation = "idle_loop"
            table.insert(state_tags, "idle")
            table.insert(tags, "idle")
        end

        if TableHasValue(states, "hopping") then
            animation = "boat_jump_loop"
            table.insert(state_tags, "hop_loop")
            table.insert(tags, "ignorewalkableplatforms")
        end

        if TableHasValue(states, "running") then
            animation = "run_loop"
            table.insert(state_tags, "run")
            table.insert(tags, "moving")
        end

        if TableHasValue(states, "sinking") then
            animation = "sink"
            table.insert(state_tags, "sink_fast")
            table.insert(tags, "busy")
        end

        if TableHasValue(states, "werehuman") then
            table.insert(tags, "werehuman")
        end

        return require("busted").mock({
            components = {
                health = {
                    invincible = TableHasValue(states, "godmode"),
                },
                locomotor = {
                    Stop = Empty,
                },
            },
            GUID = guid,
            HUD = {
                HasInputFocus = ReturnValueFn(false),
                IsChatInputScreenOpen = ReturnValueFn(false),
                IsConsoleScreenOpen = ReturnValueFn(false),
            },
            name = name,
            sg = {
                HasStateTag = function(_, tag)
                    return TableHasValue(state_tags, tag)
                end,
            },
            tags = tags,
            userid = userid,
            AnimState = {
                IsCurrentAnimation = function(_, anim)
                    return anim == animation
                end,
            },
            EnableMovementPrediction = Empty,
            GetCurrentPlatform = Empty,
            GetDisplayName = ReturnValueFn(name),
            GetPosition = ReturnValueFn({
                Get = ReturnValuesFn(1, 0, -1),
            }),
            HasTag = function(_, tag)
                return TableHasValue(tags, tag)
            end,
            LightWatcher = {
                GetTimeInDark = ReturnValueFn(3),
                GetTimeInLight = ReturnValueFn(0),
                IsInLight = ReturnValueFn(false),
            },
            Transform = {
                GetWorldPosition = function()
                    return unpack(position)
                end,
            },
        })
    end

    setup(function()
        match = require("luassert.match")
    end)

    teardown(function()
        -- globals
        _G.ACTIONS = nil
        _G.RPC = nil
        _G.TheFrontEnd = nil
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- test data
        active_screen = {}

        inst = MockPlayerInst(1, "PlayerInst", nil, {
            "godmode",
            "idle",
            "werehuman",
        }, {
            "wereness",
        })

        player_dead = MockPlayerInst(2, "PlayerDead", "KU_one", { "dead", "idle" })
        player_hopping = MockPlayerInst(3, "PlayerHopping", "KU_two", { "hopping" })
        player_running = MockPlayerInst(4, "PlayerRunning", "KU_four", { "running" })
        player_sinking = MockPlayerInst(5, "PlayerSinking", "KU_five", { "sinking" })

        player_over_water = MockPlayerInst(
            6,
            "PlayerOverWater",
            "KU_three",
            nil,
            nil,
            { 100, 0, 100 }
        )

        players = {
            inst,
            player_dead,
            player_hopping,
            player_over_water,
            player_running,
            player_sinking,
        }

        -- globals
        _G.ACTIONS = {
            WALKTO = {
                code = 177,
            },
        }

        _G.RPC = {
            LeftClick = 28,
        }

        _G.ThePlayer = inst

        _G.TheFrontEnd = mock({
            GetActiveScreen = ReturnValueFn(active_screen),
        })

        _G.TheNet = MockTheNet({
            {
                userid = inst.userid,
                admin = true,
            },
            {
                userid = "KU_one",
                admin = false,
            },
            {
                userid = "KU_two",
                admin = false,
            },
            {
                userid = "KU_three",
                admin = false,
            },
            {
                userid = "KU_four",
                admin = false,
            },
            {
                userid = "KU_five",
                admin = false,
            },
            {
                userid = "KU_host",
                admin = true,
                performance = 1,
            },
        })

        _G.TheWorld = {}

        -- initialization
        SDK = require("yoursubdirectory/sdk/sdk/sdk")
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Player")
        SDK.LoadModule("Remote")
        Player = require("yoursubdirectory/sdk/sdk/player")

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.Player." .. fn_name .. "():", ...)
    end

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[player]", ...)
    end

    describe("general", function()
        describe("GetClientTable()", function()
            describe("when a player is passed", function()
                local fn = function()
                    return Player.GetClientTable(_G.ThePlayer)
                end

                it("should call TheNet:GetClientTableForUser()", function()
                    assert.spy(_G.TheNet.GetClientTableForUser).was_not_called()
                    fn()
                    assert.spy(_G.TheNet.GetClientTableForUser).was_called(1)
                    assert.spy(_G.TheNet.GetClientTableForUser).was_called_with(
                        _G.TheNet,
                        _G.ThePlayer.userid
                    )
                end)

                it("should return a client table for user", function()
                    assert.is_equal(_G.ThePlayer.userid, fn().userid)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(fn())
                        end, _G.TheNet, "GetClientTableForUser")
                    end)
                end)
            end)

            describe("when a player is not passed", function()
                describe("and the host is not ignored", function()
                    it("shouldn't call TheNet:GetServerIsClientHosted()", function()
                        assert.spy(_G.TheNet.GetServerIsClientHosted).was_not_called()
                        Player.GetClientTable()
                        assert.spy(_G.TheNet.GetServerIsClientHosted).was_not_called()
                    end)

                    it("should return a client table with a host", function()
                        local table = Player.GetClientTable()
                        assert.is_equal(_G.TheNet:GetClientTable(), table)
                        assert.is_equal(TableCount(_G.TheNet:GetClientTable()), TableCount(table))
                    end)
                end)

                describe("and the host is ignored", function()
                    it("should call TheNet:GetServerIsClientHosted()", function()
                        assert.spy(_G.TheNet.GetServerIsClientHosted).was_not_called()
                        Player.GetClientTable(nil, true)
                        assert.spy(_G.TheNet.GetServerIsClientHosted).was_called(1)
                        assert.spy(_G.TheNet.GetServerIsClientHosted).was_called_with(_G.TheNet)
                    end)

                    it("should return a client table without a host", function()
                        local table = Player.GetClientTable(nil, true)
                        assert.is_not_equal(_G.TheNet:GetClientTable(), table)
                        assert.is_equal(
                            TableCount(_G.TheNet:GetClientTable()) - 1,
                            TableCount(table)
                        )
                    end)
                end)

                it("should call TheNet:GetClientTable()", function()
                    assert.spy(_G.TheNet.GetClientTable).was_not_called()
                    Player.GetClientTable()
                    assert.spy(_G.TheNet.GetClientTable).was_called(1)
                    assert.spy(_G.TheNet.GetClientTable).was_called_with(_G.TheNet)
                end)

                it("shouldn't call TheNet:GetClientTableForUser()", function()
                    assert.spy(_G.TheNet.GetClientTableForUser).was_not_called()
                    Player.GetClientTable()
                    assert.spy(_G.TheNet.GetClientTableForUser).was_not_called()
                end)

                describe("when some chain fields are missing", function()
                    it("should return an empty table", function()
                        AssertChainNil(function()
                            assert.is_same({}, Player.GetClientTable())
                        end, _G.TheNet, "GetClientTable")
                    end)
                end)
            end)
        end)

        describe("GetHUD()", function()
            it("should return [player].HUD", function()
                assert.is_equal(_G.ThePlayer.HUD, Player.GetHUD())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.GetHUD())
                    end, _G.ThePlayer, "HUD")
                end)
            end)
        end)

        describe("IsAdmin()", function()
            describe("when the TheNet:GetClientTable() returns an empty table", function()
                before_each(function()
                    _G.TheNet = MockTheNet({})
                end)

                it("should call TheNet:GetClientTable()", function()
                    EachPlayer(function(player)
                        Player.IsAdmin(player)
                        assert.spy(_G.TheNet.GetClientTable).was_called(1)
                    end, {}, function()
                        _G.TheNet.GetClientTable:clear()
                    end)
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(Player.IsAdmin(player))
                    end)
                end)
            end)

            describe("when a player is an admin", function()
                local fn = function()
                    return Player.IsAdmin(inst)
                end

                it("should call TheNet:GetClientTable()", function()
                    assert.spy(_G.TheNet.GetClientTable).was_not_called()
                    fn()
                    assert.spy(_G.TheNet.GetClientTable).was_called(1)
                    assert.spy(_G.TheNet.GetClientTable).was_called_with(_G.TheNet)
                end)

                TestReturnTrue(fn)
            end)

            describe("when a player is not an admin", function()
                it("should call TheNet:GetClientTable()", function()
                    EachPlayer(function(player)
                        Player.IsAdmin(player)
                        assert.spy(_G.TheNet.GetClientTable).was_called(1)
                        assert.spy(_G.TheNet.GetClientTable).was_called_with(_G.TheNet)
                    end, {
                        inst,
                    }, function()
                        _G.TheNet.GetClientTable:clear()
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsAdmin(player))
                    end, {
                        inst,
                    })
                end)
            end)

            describe("when some chain fields are missing", function()
                EachPlayer(function(player)
                    AssertChainNil(function()
                        assert.is_nil(Player.IsAdmin(player))
                    end, _G.TheNet, "GetClientTable")
                end)
            end)
        end)

        describe("IsGhost()", function()
            describe("when a player is dead", function()
                local player

                local fn = function()
                    return Player.IsGhost(player)
                end

                setup(function()
                    player = player_dead
                end)

                it("should call [player]:HasTag()", function()
                    assert.spy(player.HasTag).was_not_called()
                    fn()
                    assert.spy(player.HasTag).was_called(1)
                    assert.spy(player.HasTag).was_called_with(match.is_ref(player), "playerghost")
                end)

                TestReturnTrue(fn)
            end)

            describe("when a player is not dead", function()
                it("should call [player]:HasTag()", function()
                    EachPlayer(function(player)
                        assert.spy(player.HasTag).was_not_called()
                        Player.IsGhost(player)
                        assert.spy(player.HasTag).was_called(1)
                        assert.spy(player.HasTag).was_called_with(
                            match.is_ref(player),
                            "playerghost"
                        )
                    end, {
                        player_dead,
                    })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsGhost(player))
                    end, {
                        player_dead,
                    })
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsGhost())
                    end, _G.ThePlayer, "HasTag")
                end)
            end)
        end)

        describe("IsHUDChatInputScreenOpen()", function()
            local fn = function()
                return Player.IsHUDChatInputScreenOpen()
            end

            it("should return [player].HUD:IsChatInputScreenOpen() value", function()
                assert.is_equal(_G.ThePlayer.HUD.IsChatInputScreenOpen(), fn())
            end)

            it("should call [player].HUD:IsChatInputScreenOpen()", function()
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_not_called()
                fn()
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_called(1)
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_called_with(
                    match.is_ref(_G.ThePlayer.HUD)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(fn())
                    end, _G.ThePlayer, "HUD", "IsChatInputScreenOpen")
                end)
            end)
        end)

        describe("IsHUDConsoleScreenOpen()", function()
            local fn = function()
                return Player.IsHUDConsoleScreenOpen()
            end

            it("should return [player].HUD.IsConsoleScreenOpen() value", function()
                assert.is_equal(_G.ThePlayer.HUD.IsConsoleScreenOpen(), fn())
            end)

            it("should call [player].HUD:IsConsoleScreenOpen()", function()
                assert.spy(_G.ThePlayer.HUD.IsConsoleScreenOpen).was_not_called()
                fn()
                assert.spy(_G.ThePlayer.HUD.IsConsoleScreenOpen).was_called(1)
                assert.spy(_G.ThePlayer.HUD.IsConsoleScreenOpen).was_called_with(
                    match.is_ref(_G.ThePlayer.HUD)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(fn())
                    end, _G.ThePlayer, "HUD", "IsConsoleScreenOpen")
                end)
            end)
        end)

        describe("IsHUDHasInputFocus()", function()
            local fn = function()
                return Player.IsHUDHasInputFocus()
            end

            it("should return [player].HUD.HasInputFocus() value", function()
                assert.is_equal(_G.ThePlayer.HUD.HasInputFocus(), fn())
            end)

            it("should call [player].HUD.HasInputFocus()", function()
                assert.spy(_G.ThePlayer.HUD.HasInputFocus).was_not_called()
                fn()
                assert.spy(_G.ThePlayer.HUD.HasInputFocus).was_called(1)
                assert.spy(_G.ThePlayer.HUD.HasInputFocus).was_called_with(
                    match.is_ref(_G.ThePlayer.HUD)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(fn())
                    end, _G.ThePlayer, "HUD", "HasInputFocus")
                end)
            end)
        end)

        describe("IsHUDWriteableScreenActive()", function()
            local fn = function()
                return Player.IsHUDWriteableScreenActive()
            end

            describe("when [player].HUD.writeablescreen is an active one", function()
                before_each(function()
                    _G.ThePlayer.HUD.writeablescreen = active_screen
                end)

                TestReturnTrue(fn)
            end)

            describe("when [player].HUD.writeablescreen is not an active one", function()
                before_each(function()
                    _G.ThePlayer.HUD.writeablescreen = nil
                end)

                TestReturnFalse(fn)
            end)

            it("should call TheFrontEnd:GetActiveScreen()", function()
                assert.spy(_G.TheFrontEnd.GetActiveScreen).was_not_called()
                fn()
                assert.spy(_G.TheFrontEnd.GetActiveScreen).was_called(1)
                assert.spy(_G.TheFrontEnd.GetActiveScreen).was_called_with(
                    match.is_ref(_G.TheFrontEnd)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(fn())
                    end, _G.TheFrontEnd, "GetActiveScreen")
                end)
            end)
        end)

        describe("IsIdle()", function()
            describe("when a player is idle", function()
                describe("based on the state graph", function()
                    local function TestIdle(player)
                        local fn = function()
                            return Player.IsIdle(player)
                        end

                        it("should call [player].sg.HasStateTag()", function()
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            fn()
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "idle"
                            )
                        end)

                        it("shouldn't call [player].AnimState:IsCurrentAnimation()", function()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            fn()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end)

                        TestReturnTrue(fn)
                    end

                    describe("and is a normal player", function()
                        TestIdle(inst)
                    end)

                    describe("and is a dead player", function()
                        TestIdle(player_dead)
                    end)

                    describe("and is a player over water", function()
                        TestIdle(player_over_water)
                    end)
                end)

                describe("based on the animation", function()
                    local function TestIdle(player)
                        local fn = function()
                            return Player.IsIdle(player)
                        end

                        before_each(function()
                            player.sg = nil
                        end)

                        it("should call [player].AnimState.IsCurrentAnimation()", function()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            fn()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                                match.is_ref(player.AnimState),
                                "idle_loop"
                            )
                        end)

                        TestReturnTrue(fn)
                    end

                    describe("and is a normal player", function()
                        TestIdle(inst)
                    end)

                    describe("and is a dead player", function()
                        TestIdle(player_dead)
                    end)

                    describe("and is a player over water", function()
                        TestIdle(player_over_water)
                    end)
                end)
            end)

            describe("when a player is not idle", function()
                describe("based on the state graph", function()
                    it("should call [player].sg.HasStateTag()", function()
                        EachPlayer(function(player)
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "idle"
                            )
                        end)
                    end)

                    it("shouldn't call [player].AnimState:IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, {
                            player_hopping,
                            player_running,
                            player_sinking,
                            player_over_water,
                        })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsIdle(player))
                        end, {
                            inst,
                            player_dead,
                            player_over_water,
                        })
                    end)
                end)

                describe("based on the animation", function()
                    before_each(function()
                        EachPlayer(function(player)
                            player.sg = nil
                        end, {
                            inst,
                            player_dead,
                            player_over_water,
                        })
                    end)

                    it("should call [player].AnimState.IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                                match.is_ref(player.AnimState),
                                "idle_loop"
                            )
                        end, {
                            inst,
                            player_dead,
                            player_over_water,
                        })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsIdle(player))
                        end, {
                            inst,
                            player_dead,
                            player_over_water,
                        })
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        player.sg = nil
                        AssertChainNil(function()
                            assert.is_nil(Player.IsIdle(player))
                        end, player, "AnimState", "IsCurrentAnimation")
                    end)
                end)
            end)
        end)

        describe("IsInvincible()", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsInvincible())
                    end, _G.ThePlayer, "components", "health", "invincible")
                end)
            end)
        end)

        describe("IsOnPlatform()", function()
            local fn = function()
                return Player.IsOnPlatform()
            end

            before_each(function()
                _G.TheWorld = {
                    Map = {
                        GetPlatformAtPoint = spy.new(ReturnValueFn({})),
                    },
                }
            end)

            describe("when some of the world chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(fn, _G.TheWorld, "Map", "GetPlatformAtPoint")
                end)
            end)

            describe("when some of inst chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(fn, _G.ThePlayer, "GetPosition", "Get")
                end)
            end)

            describe("when both world and inst are set", function()
                it("should call [player]:GetPosition()", function()
                    assert.spy(_G.ThePlayer.GetPosition).was_called(0)
                    fn()
                    assert.spy(_G.ThePlayer.GetPosition).was_called(1)
                    assert.spy(_G.ThePlayer.GetPosition).was_called_with(match.is_ref(_G.ThePlayer))
                end)

                it("should call TheWorld.Map:GetPlatformAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called(0)
                    fn()
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        1,
                        0,
                        -1
                    )
                end)

                TestReturnTrue(fn)
            end)
        end)

        describe("IsOverWater()", function()
            setup(function()
                _G.GROUND = {
                    INVALID = 255,
                }
            end)

            before_each(function()
                _G.TheWorld = mock({
                    Map = {
                        GetSize = function()
                            return 300, 300
                        end,
                        GetTileAtPoint = function(_, x, y, z)
                            -- 6: GROUND.GRASS
                            -- 201: GROUND.OCEAN_COASTAL
                            return x == 100 and y == 0 and z == 100 and 201 or 6
                        end,
                        IsVisualGroundAtPoint = function(_, x, y, z)
                            return not (x == 100 and y == 0 and z == 100) and true or false
                        end,
                    },
                })
            end)

            teardown(function()
                _G.GROUND = nil
                _G.TheWorld = nil
            end)

            describe("when a player is over water", function()
                local player

                local fn = function()
                    return Player.IsOverWater(player)
                end

                before_each(function()
                    player = player_over_water
                end)

                it("should call [player].Transform:GetWorldPosition()", function()
                    assert.spy(player.Transform.GetWorldPosition).was_not_called()
                    fn()
                    assert.spy(player.Transform.GetWorldPosition).was_called(1)
                    assert.spy(player.Transform.GetWorldPosition).was_called_with(
                        match.is_ref(player.Transform)
                    )
                end)

                it("should call TheWorld.Map:IsVisualGroundAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    fn()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn call TheWorld.Map:GetTileAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    fn()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("should call [player]:GetCurrentPlatform()", function()
                    assert.spy(player.GetCurrentPlatform).was_not_called()
                    fn()
                    assert.spy(player.GetCurrentPlatform).was_called(1)
                    assert.spy(player.GetCurrentPlatform).was_called_with(match.is_ref(player))
                end)

                TestReturnTrue(fn)
            end)

            describe("when a player is not over water", function()
                it("should call [player].Transform:GetWorldPosition()", function()
                    EachPlayer(function(player)
                        assert.spy(player.Transform.GetWorldPosition).was_not_called()
                        Player.IsOverWater(player)
                        assert.spy(player.Transform.GetWorldPosition).was_called(1)
                        assert.spy(player.Transform.GetWorldPosition).was_called_with(
                            match.is_ref(player.Transform)
                        )
                    end, {
                        player_over_water,
                    })
                end)

                it("should call TheWorld.Map:IsVisualGroundAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        _G.ThePlayer.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn't call TheWorld.Map:GetTileAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                end)

                it("shouldn't call [player]:GetCurrentPlatform()", function()
                    EachPlayer(function(player)
                        assert.spy(player.GetCurrentPlatform).was_not_called()
                        Player.IsOverWater(player)
                        assert.spy(player.GetCurrentPlatform).was_not_called()
                    end, {
                        player_over_water,
                    })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsOverWater(player))
                    end, {
                        player_over_water,
                    })
                end)
            end)

            describe("when some player chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        player.sg = nil
                        AssertChainNil(function()
                            assert.is_nil(Player.IsOverWater(player))
                        end, player, "Transform", "GetWorldPosition")
                    end)
                end)
            end)
        end)

        describe("IsOwner()", function()
            describe("when a player is an owner", function()
                TestReturnTrue(function()
                    return Player.IsOwner(inst)
                end)
            end)

            describe("when a player is not an owner", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsOwner(player))
                    end, {
                        inst,
                    })
                end)
            end)
        end)

        describe("IsReal()", function()
            describe("when a player is real", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_true(Player.IsReal(player))
                    end)
                end)
            end)

            describe("when a player is not real", function()
                before_each(function()
                    EachPlayer(function(player)
                        player.userid = ""
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsReal(player))
                    end)
                end)
            end)

            describe("when the userid is missing", function()
                before_each(function()
                    EachPlayer(function(player)
                        player.userid = nil
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsReal(player))
                    end)
                end)
            end)
        end)

        describe("IsRunning()", function()
            describe("when a player is running", function()
                local player

                local fn = function()
                    return Player.IsRunning(player)
                end

                before_each(function()
                    player = player_running
                end)

                describe("and the state graph is available", function()
                    it("should call [player].sg:HasStateTag()", function()
                        assert.spy(player.sg.HasStateTag).was_not_called()
                        fn()
                        assert.spy(player.sg.HasStateTag).was_called(1)
                        assert.spy(player.sg.HasStateTag).was_called_with(
                            match.is_ref(player.sg),
                            "run"
                        )
                    end)

                    it("shouldn't call [player].AnimState:IsCurrentAnimation()", function()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        fn()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                    end)

                    TestReturnTrue(fn)
                end)

                describe("and the state graph is not available", function()
                    before_each(function()
                        player.sg = nil
                    end)

                    it("should call [player].AnimState:IsCurrentAnimation()", function()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called(2)
                        fn()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called(2)
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                            match.is_ref(player.AnimState),
                            "run_pre"
                        )
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                            match.is_ref(player.AnimState),
                            "run_loop"
                        )
                    end)

                    TestReturnTrue(fn)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            AssertChainNil(function()
                                assert.is_nil(fn())
                            end, player, "AnimState", "IsCurrentAnimation")
                        end)
                    end)
                end)
            end)

            describe("when a player is not running", function()
                describe("and the state graph is available", function()
                    it("should call [player].sg:HasStateTag()", function()
                        EachPlayer(function(player)
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "run"
                            )
                        end, {
                            player_running,
                        }, function(player)
                            player.sg.HasStateTag:clear()
                        end)
                    end)

                    it("shouldn't call [player].AnimState:IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, {
                            player_running,
                        }, function(player)
                            player.AnimState.IsCurrentAnimation:clear()
                        end)
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsRunning(player))
                        end, {
                            player_running,
                        })
                    end)
                end)

                describe("and the state graph is not available", function()
                    before_each(function()
                        player_running.sg = nil
                    end)

                    it("should call [player].AnimState:IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, {
                            player_running,
                        }, function(player)
                            player.AnimState.IsCurrentAnimation:clear()
                        end)
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsRunning(player))
                        end, {
                            player_running,
                        })
                    end)
                end)
            end)
        end)

        describe("IsSinking()", function()
            describe("when a player is sinking", function()
                local player

                local fn = function()
                    return Player.IsSinking(player)
                end

                setup(function()
                    player = player_sinking
                end)

                it("should call [player].AnimState:IsCurrentAnimation()", function()
                    assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                    fn()
                    assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                    assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                        match.is_ref(player.AnimState),
                        "sink"
                    )
                    assert.spy(player.AnimState.IsCurrentAnimation).was_not_called_with(
                        match.is_ref(player.AnimState),
                        "plank_hop"
                    )
                end)

                TestReturnTrue(fn)
            end)

            describe("when a player is not sinking", function()
                it("should call [player].AnimState:IsCurrentAnimation()", function()
                    EachPlayer(function(player)
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        Player.IsSinking(player)
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called(2)
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                            match.is_ref(player.AnimState),
                            "sink"
                        )
                        assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                            match.is_ref(player.AnimState),
                            "plank_hop"
                        )
                    end, {
                        player_sinking,
                    })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsSinking(player))
                    end, {
                        player_sinking,
                    })
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsSinking())
                    end, _G.ThePlayer, "AnimState", "IsCurrentAnimation")
                end)
            end)
        end)
    end)

    describe("light watcher", function()
        describe("IsInLight()", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsInLight())
                    end, _G.ThePlayer, "LightWatcher", "IsInLight")
                end)
            end)
        end)

        describe("GetTimeInDark()", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.GetTimeInDark())
                    end, _G.ThePlayer, "LightWatcher", "GetTimeInDark")
                end)
            end)
        end)

        describe("GetTimeInLight()", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.GetTimeInLight())
                    end, _G.ThePlayer, "LightWatcher", "GetTimeInLight")
                end)
            end)
        end)
    end)

    describe("movement prediction", function()
        describe("HasMovementPrediction()", function()
            local fn = function()
                return Player.HasMovementPrediction(inst)
            end

            describe("when a locomotor component is available", function()
                before_each(function()
                    inst.components = {
                        locomotor = {},
                    }
                end)

                TestReturnTrue(fn)
            end)

            describe("when a locomotor component is not available", function()
                before_each(function()
                    inst.components = {
                        locomotor = nil,
                    }
                end)

                TestReturnFalse(fn)
            end)

            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(Player.HasMovementPrediction())
                    end, _G.ThePlayer, "components", "locomotor")
                end)
            end)
        end)

        describe("SetMovementPrediction()", function()
            before_each(function()
                _G.TheSim = {
                    SetSetting = spy.new(Empty),
                }
            end)

            local function TestSetSettingCalls(fn, calls, ...)
                local args = { ... }
                it(
                    (calls > 0 and "should" or "shouldn't") .. " call TheSim:SetSetting()",
                    function()
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                        fn()
                        assert.spy(_G.TheSim.SetSetting).was_called(calls)
                        if calls > 0 and #args > 0 then
                            assert.spy(_G.TheSim.SetSetting).was_called_with(
                                match.is_ref(_G.TheSim),
                                unpack(args)
                            )
                        end
                    end
                )
            end

            local function TestSetSetting(fn, ...)
                TestSetSettingCalls(fn, 1, ...)
            end

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                describe("and enabling", function()
                    local fn = function()
                        return Player.SetMovementPrediction(true, inst)
                    end

                    TestDebugError(
                        fn,
                        "SetMovementPrediction",
                        "Can't be toggled on the master simulation"
                    )

                    it("shouldn't call [player]:EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        fn()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                    end)

                    TestSetSettingCalls(fn, 0)
                    TestReturnFalse(fn)
                end)

                describe("and disabling", function()
                    local fn = function()
                        return Player.SetMovementPrediction(false, inst)
                    end

                    it("shouldn't call [player]:EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        fn()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                    end)

                    TestSetSettingCalls(fn, 0)
                    TestReturnFalse(fn)
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                describe("and enabling", function()
                    local fn = function()
                        return Player.SetMovementPrediction(true, inst)
                    end

                    it("shouldn't call [player].components.locomotor:Stop()", function()
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                        fn()
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                    end)

                    it("should call [player]:EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        fn()
                        assert.spy(inst.EnableMovementPrediction).was_called(1)
                        assert.spy(inst.EnableMovementPrediction).was_called_with(
                            match.is_ref(inst),
                            true
                        )
                    end)

                    TestSetSetting(fn, "misc", "movementprediction", "true")
                    TestDebugString(fn, "Movement prediction:", "enabled")
                    TestReturnTrue(fn)
                end)

                describe("and disabling", function()
                    local fn = function()
                        return Player.SetMovementPrediction(false, inst)
                    end

                    it("should call [player].components.locomotor:Stop()", function()
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                        fn()
                        assert.spy(inst.components.locomotor.Stop).was_called(1)
                        assert.spy(inst.components.locomotor.Stop).was_called_with(
                            match.is_ref(inst.components.locomotor)
                        )
                    end)

                    it("should call [player]:EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        fn()
                        assert.spy(inst.EnableMovementPrediction).was_called(1)
                        assert.spy(inst.EnableMovementPrediction).was_called_with(
                            match.is_ref(inst),
                            false
                        )
                    end)

                    TestSetSetting(fn, "misc", "movementprediction", "false")
                    TestDebugString(fn, "Movement prediction:", "disabled")
                    TestReturnFalse(fn)
                end)
            end)
        end)

        describe("ToggleMovementPrediction()", function()
            local fn = function()
                return Player.ToggleMovementPrediction(inst)
            end

            describe("when movement prediction is enabled", function()
                before_each(function()
                    Player.HasMovementPrediction = spy.new(ReturnValueFn(true))
                end)

                TestReturnFalse(fn)
            end)

            describe("when movement prediction is disabled", function()
                before_each(function()
                    Player.HasMovementPrediction = spy.new(ReturnValueFn(false))
                end)

                TestReturnTrue(fn)
            end)
        end)
    end)
end)
