require "busted.runner"()
require "class"

describe("#sdk SDK.Player", function()
    -- setup
    local match

    -- before_each test data
    local inst
    local player_dead, player_hopping, player_over_water, player_running, player_sinking, players

    -- before_each initialization
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
        client_table = client_table ~= nil and client_table or {
            { userid = "KU_admin", admin = true },
            { userid = "KU_one", admin = false },
        }

        return require("busted").mock({
            GetClientTable = function()
                return client_table
            end,
            SendRemoteExecute = Empty,
        })
    end

    local function MockPlayerInst(name, userid, states, tags, position)
        userid = userid ~= nil and userid or "KU_admin"
        states = states ~= nil and states or { "idle" }
        tags = tags ~= nil and tags or {}
        position = position ~= nil and position or { 1, 2, 3 }

        local animation
        local state_tags = {}

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

        return require("busted").mock({
            components = {
                health = {
                    invincible = TableHasValue(states, "godmode"),
                },
                locomotor = {
                    Stop = Empty,
                },
            },
            HUD = {
                IsChatInputScreenOpen = ReturnValueFn(false),
                IsConsoleScreenOpen = ReturnValueFn(false),
            },
            name = name,
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
            sg = {
                HasStateTag = function(_, tag)
                    return TableHasValue(state_tags, tag)
                end,
            },
            userid = userid,
            AnimState = {
                IsCurrentAnimation = function(_, anim)
                    return anim == animation
                end,
            },
            EnableMovementPrediction = Empty,
            GetCurrentPlatform = Empty,
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
        match = require "luassert.match"
    end)

    teardown(function()
        _G.ThePlayer = nil
        _G.TheNet = nil
    end)

    before_each(function()
        -- test data
        inst = MockPlayerInst("PlayerInst", nil, { "godmode", "idle" }, { "wereness" })
        player_dead = MockPlayerInst("PlayerDead", "KU_one", { "dead", "idle" })
        player_hopping = MockPlayerInst("PlayerHopping", "KU_two", { "hopping" })
        player_running = MockPlayerInst("PlayerRunning", "KU_four", { "running" })
        player_sinking = MockPlayerInst("PlayerSinking", "KU_five", { "sinking" })
        player_over_water = MockPlayerInst("PlayerOverWater", "KU_three", nil, nil, { 100, 0, 100 })

        players = {
            inst,
            player_dead,
            player_hopping,
            player_over_water,
            player_running,
            player_sinking,
        }

        -- globals
        _G.ThePlayer = inst
        _G.TheNet = MockTheNet({
            {
                userid = inst.userid,
                admin = true
            },
            {
                userid = "KU_one",
                admin = false
            },
            {
                userid = "KU_two",
                admin = false
            },
            {
                userid = "KU_three",
                admin = false
            },
            {
                userid = "KU_four",
                admin = false
            },
            {
                userid = "KU_five",
                admin = false
            },
        })

        -- initialization
        Player = require "sdk/player"
    end)

    describe("general", function()
        describe("GetHUD", function()
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

        describe("IsAdmin", function()
            local GetClientTable

            before_each(function()
                GetClientTable = TheNet.GetClientTable
            end)

            describe("when the TheNet.GetClientTable() returns an empty table", function()
                before_each(function()
                    _G.TheNet = MockTheNet({})
                    GetClientTable = TheNet.GetClientTable
                end)

                it("should call TheNet.GetClientTable()", function()
                    EachPlayer(function(player)
                        Player.IsAdmin(player)
                        assert.spy(GetClientTable).was_called(1)
                    end, {}, function()
                        GetClientTable:clear()
                    end)
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(Player.IsAdmin(player))
                    end)
                end)
            end)

            describe("when the player is an admin", function()
                it("should call TheNet.GetClientTable()", function()
                    assert.spy(GetClientTable).was_not_called()
                    Player.IsAdmin(inst)
                    assert.spy(GetClientTable).was_called(1)
                    assert.spy(GetClientTable).was_called_with(TheNet)
                end)

                it("should return true", function()
                    assert.is_true(Player.IsAdmin(inst))
                end)
            end)

            describe("when the player is not an admin", function()
                it("should call TheNet.GetClientTable()", function()
                    EachPlayer(function(player)
                        Player.IsAdmin(player)
                        assert.spy(GetClientTable).was_called(1)
                        assert.spy(GetClientTable).was_called_with(TheNet)
                    end, { inst }, function()
                        GetClientTable:clear()
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsAdmin(player))
                    end, { inst })
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

        describe("IsGhost", function()
            describe("when the player is dead", function()
                local player

                setup(function()
                    player = player_dead
                end)

                it("should call [player]:HasTag()", function()
                    assert.spy(player.HasTag).was_not_called()
                    Player.IsGhost(player)
                    assert.spy(player.HasTag).was_called(1)
                    assert.spy(player.HasTag).was_called_with(match.is_ref(player), "playerghost")
                end)

                it("should return true", function()
                    assert.is_true(Player.IsGhost(player))
                end)
            end)

            describe("when the player is not dead", function()
                it("should call [player]:HasTag()", function()
                    EachPlayer(function(player)
                        assert.spy(player.HasTag).was_not_called()
                        Player.IsGhost(player)
                        assert.spy(player.HasTag).was_called(1)
                        assert.spy(player.HasTag).was_called_with(
                            match.is_ref(player),
                            "playerghost"
                        )
                    end, { player_dead })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsGhost(player))
                    end, { player_dead })
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

        describe("IsHUDChatInputScreenOpen", function()
            it("should return [player].HUD.IsChatInputScreenOpen() value", function()
                assert.is_equal(
                    _G.ThePlayer.HUD.IsChatInputScreenOpen(),
                    Player.IsHUDChatInputScreenOpen()
                )
            end)

            it("should call [player].HUD.IsChatInputScreenOpen()", function()
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_not_called()
                Player.IsHUDChatInputScreenOpen()
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_called(1)
                assert.spy(_G.ThePlayer.HUD.IsChatInputScreenOpen).was_called_with(
                    match.is_ref(_G.ThePlayer.HUD)
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsHUDChatInputScreenOpen())
                    end, _G.ThePlayer, "HUD", "IsChatInputScreenOpen")
                end)
            end)
        end)

        describe("IsIdle", function()
            describe("when the player is idle", function()
                describe("based on the state graph", function()
                    local function TestIdle(player)
                        it("should call [player].sg.HasStateTag()", function()
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "idle"
                            )
                        end)

                        it("shouldn't call [player].AnimState.IsCurrentAnimation()", function()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end)

                        it("should return true", function()
                            assert.is_true(Player.IsIdle(player))
                        end)
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
                        before_each(function()
                            player.sg = nil
                        end)

                        it("should call [player].AnimState.IsCurrentAnimation()", function()
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                                match.is_ref(player.AnimState),
                                "idle_loop"
                            )
                        end)

                        it("should return true", function()
                            assert.is_true(Player.IsIdle(player))
                        end)
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

            describe("when the player is not idle", function()
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

                    it("shouldn't call [player].AnimState.IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, { player_hopping, player_running, player_sinking, player_over_water })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsIdle(player))
                        end, { inst, player_dead, player_over_water })
                    end)
                end)

                describe("based on the animation", function()
                    before_each(function()
                        EachPlayer(function(player)
                            player.sg = nil
                        end, { inst, player_dead, player_over_water })
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
                        end, { inst, player_dead, player_over_water })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsIdle(player))
                        end, { inst, player_dead, player_over_water })
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

        describe("IsInvincible", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsInvincible())
                    end, _G.ThePlayer, "components", "health", "invincible")
                end)
            end)
        end)

        describe("IsOnPlatform", function()
            before_each(function()
                _G.TheWorld = {
                    Map = {
                        GetPlatformAtPoint = spy.new(ReturnValueFn({})),
                    },
                }
            end)

            describe("when some of the world chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        Player.IsOnPlatform()
                    end, _G.TheWorld, "Map", "GetPlatformAtPoint")
                end)
            end)

            describe("when some of inst chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        Player.IsOnPlatform()
                    end, _G.ThePlayer, "GetPosition", "Get")
                end)
            end)

            describe("when both world and inst are set", function()
                it("should call self.inst:GetPosition()", function()
                    assert.spy(_G.ThePlayer.GetPosition).was_called(0)
                    Player.IsOnPlatform()
                    assert.spy(_G.ThePlayer.GetPosition).was_called(1)
                    assert.spy(_G.ThePlayer.GetPosition).was_called_with(match.is_ref(_G.ThePlayer))
                end)

                it("should call self.world.Map:GetPlatformAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called(0)
                    Player.IsOnPlatform()
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.GetPlatformAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        1,
                        0,
                        -1
                    )
                end)

                it("should return true", function()
                    assert.is_true(Player.IsOnPlatform())
                end)
            end)
        end)

        describe("IsOverWater", function()
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

            describe("when the player is over water", function()
                local player

                before_each(function()
                    player = player_over_water
                end)

                it("should call [player].Transform.GetWorldPosition()", function()
                    assert.spy(player.Transform.GetWorldPosition).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(player.Transform.GetWorldPosition).was_called(1)
                    assert.spy(player.Transform.GetWorldPosition).was_called_with(
                        match.is_ref(player.Transform)
                    )
                end)

                it("should call TheWorld.Map.IsVisualGroundAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn call TheWorld.Map.GetTileAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("should call [player].GetCurrentPlatform()", function()
                    assert.spy(player.GetCurrentPlatform).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(player.GetCurrentPlatform).was_called(1)
                    assert.spy(player.GetCurrentPlatform).was_called_with(match.is_ref(player))
                end)

                it("should return true", function()
                    assert.is_true(Player.IsOverWater(player))
                end)
            end)

            describe("when the player is not over water", function()
                it("should call [player].Transform.GetWorldPosition()", function()
                    EachPlayer(function(player)
                        assert.spy(player.Transform.GetWorldPosition).was_not_called()
                        Player.IsOverWater(player)
                        assert.spy(player.Transform.GetWorldPosition).was_called(1)
                        assert.spy(player.Transform.GetWorldPosition).was_called_with(
                            match.is_ref(player.Transform)
                        )
                    end, { player_over_water })
                end)

                it("should call TheWorld.Map.IsVisualGroundAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        _G.ThePlayer.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn't call TheWorld.Map.GetTileAtPoint()", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                end)

                it("shouldn't call [player].GetCurrentPlatform()", function()
                    EachPlayer(function(player)
                        assert.spy(player.GetCurrentPlatform).was_not_called()
                        Player.IsOverWater(player)
                        assert.spy(player.GetCurrentPlatform).was_not_called()
                    end, { player_over_water })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsOverWater(player))
                    end, { player_over_water })
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

        describe("IsOwner", function()
            describe("when the player is an owner", function()
                it("should return true", function()
                    assert.is_true(Player.IsOwner(inst))
                end)
            end)

            describe("when the player is not an owner", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsOwner(player))
                    end, { inst })
                end)
            end)
        end)

        describe("IsReal", function()
            describe("when the player is real", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_true(Player.IsReal(player))
                    end)
                end)
            end)

            describe("when the player is not real", function()
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

        describe("IsRunning", function()
            describe("when the player is running", function()
                local player

                before_each(function()
                    player = player_running
                end)

                describe("and the state graph is available", function()
                    it("should call [player].sg.HasStateTag()", function()
                        assert.spy(player.sg.HasStateTag).was_not_called()
                        Player.IsRunning(player)
                        assert.spy(player.sg.HasStateTag).was_called(1)
                        assert.spy(player.sg.HasStateTag).was_called_with(
                            match.is_ref(player.sg),
                            "run"
                        )
                    end)

                    it("shouldn't call [player].AnimState.IsCurrentAnimation()", function()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        Player.IsRunning(player)
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                    end)

                    it("should return true", function()
                        assert.is_true(Player.IsRunning(player))
                    end)
                end)

                describe("and the state graph is not available", function()
                    before_each(function()
                        player.sg = nil
                    end)

                    it("should call [player].AnimState.IsCurrentAnimation()", function()
                        assert.spy(player.AnimState.IsCurrentAnimation).was_not_called(2)
                        Player.IsRunning(player)
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

                    it("should return true", function()
                        assert.is_true(Player.IsRunning(player))
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            AssertChainNil(function()
                                assert.is_nil(Player.IsRunning(player))
                            end, player, "AnimState", "IsCurrentAnimation")
                        end)
                    end)
                end)
            end)

            describe("when the player is not running", function()
                describe("and the state graph is available", function()
                    it("should call [player].sg.HasStateTag()", function()
                        EachPlayer(function(player)
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "run"
                            )
                        end, { player_running }, function(player)
                            player.sg.HasStateTag:clear()
                        end)
                    end)

                    it("shouldn't call [player].AnimState.IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, { player_running }, function(player)
                            player.AnimState.IsCurrentAnimation:clear()
                        end)
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsRunning(player))
                        end, { player_running })
                    end)
                end)

                describe("and the state graph is not available", function()
                    before_each(function()
                        player_running.sg = nil
                    end)

                    it("should call [player].AnimState.IsCurrentAnimation()", function()
                        EachPlayer(function(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                            Player.IsRunning(player)
                            assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                        end, { player_running }, function(player)
                            player.AnimState.IsCurrentAnimation:clear()
                        end)
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(Player.IsRunning(player))
                        end, { player_running })
                    end)
                end)
            end)
        end)

        describe("IsSinking", function()
            describe("when the player is sinking", function()
                local player

                setup(function()
                    player = player_sinking
                end)

                it("should call [player].AnimState.IsCurrentAnimation()", function()
                    assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
                    Player.IsSinking(player)
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

                it("should return true", function()
                    assert.is_true(Player.IsSinking(player))
                end)
            end)

            describe("when the player is not sinking", function()
                it("should call [player].AnimState.IsCurrentAnimation()", function()
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
                    end, { player_sinking })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(Player.IsSinking(player))
                    end, { player_sinking })
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

    describe("attributes", function()
        local function TestReplicaAttributePercent(name, fn_name, component_fn_name, value)
            describe("when [player].replica.health is available", function()
                it("should call the [player].replica.health:GetPercent()", function()
                    EachPlayer(function(player)
                        assert.spy(player.replica[name][component_fn_name]).was_not_called()
                        Player[fn_name](player)
                        assert.spy(player.replica[name][component_fn_name]).was_called(1)
                        assert.spy(player.replica[name][component_fn_name]).was_called_with(
                            match.is_ref(player.replica[name])
                        )
                    end)
                end)

                it("should return the " .. name .. " percent", function()
                    EachPlayer(function(player)
                        assert.is_equal(value, Player[fn_name](player))
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        AssertChainNil(function()
                            assert.is_nil(Player[fn_name](player))
                        end, player, "replica", name)
                    end)
                end)
            end)
        end

        describe("GetHealthPercent", function()
            TestReplicaAttributePercent("health", "GetHealthPercent", "GetPercent", 100)
        end)

        describe("GetHealthLimitPercent", function()
            describe("and the Health replica component is available", function()
                it("should call the Health:GetPenaltyPercent()", function()
                    EachPlayer(function(player)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_not_called()
                        Player.GetHealthLimitPercent(player)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_called(1)
                        assert.spy(player.replica.health.GetPenaltyPercent).was_called_with(
                            match.is_ref(player.replica.health)
                        )
                    end)
                end)

                it("should return the maximum health percent", function()
                    EachPlayer(function(player)
                        assert.is_equal(60, Player.GetHealthLimitPercent(player))
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        AssertChainNil(function()
                            assert.is_nil(Player.GetHealthLimitPercent(player))
                        end, player, "replica", "health")
                    end)
                end)
            end)
        end)

        describe("GetHealthPenaltyPercent", function()
            TestReplicaAttributePercent("health", "GetHealthPenaltyPercent", "GetPenaltyPercent", 40)
        end)

        describe("GetHungerPercent", function()
            TestReplicaAttributePercent("hunger", "GetHungerPercent", "GetPercent", 100)
        end)

        describe("GetSanityPercent", function()
            TestReplicaAttributePercent("sanity", "GetSanityPercent", "GetPercent", 100)
        end)
    end)

    describe("light watcher", function()
        describe("IsInLight", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.IsInLight())
                    end, _G.ThePlayer, "LightWatcher", "IsInLight")
                end)
            end)
        end)

        describe("GetTimeInDark", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Player.GetTimeInDark())
                    end, _G.ThePlayer, "LightWatcher", "GetTimeInDark")
                end)
            end)
        end)

        describe("GetTimeInLight", function()
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
        describe("HasMovementPrediction", function()
            describe("when locomotor component is available", function()
                before_each(function()
                    inst.components = {
                        locomotor = {},
                    }
                end)

                it("should return true", function()
                    assert.is_true(Player.HasMovementPrediction(inst))
                end)
            end)

            describe("when locomotor component is not available", function()
                before_each(function()
                    inst.components = {
                        locomotor = nil,
                    }
                end)

                it("should return false", function()
                    assert.is_false(Player.HasMovementPrediction(inst))
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(Player.HasMovementPrediction())
                    end, _G.ThePlayer, "components", "locomotor")
                end)
            end)
        end)

        describe("SetMovementPrediction", function()
            before_each(function()
                _G.TheSim = {
                    SetSetting = spy.new(Empty)
                }
            end)

            describe("when master simulation", function()
                before_each(function()
                    _G.TheWorld = {
                        ismastersim = true,
                    }
                end)

                describe("and enabling", function()
                    it("shouldn't call [player].EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        Player.SetMovementPrediction(true, inst)
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                    end)

                    it("shouldn't call TheSim:SetSetting()", function()
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                    end)

                    it("should return false", function()
                        assert.is_false(Player.SetMovementPrediction(true, inst))
                    end)
                end)

                describe("and disabling", function()
                    it("shouldn't call [player].EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                    end)

                    it("shouldn't call TheSim:SetSetting()", function()
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                    end)

                    it("should return false", function()
                        assert.is_false(Player.SetMovementPrediction(false, inst))
                    end)
                end)
            end)

            describe("when non-master simulation", function()
                before_each(function()
                    _G.TheWorld = {
                        ismastersim = false,
                    }
                end)

                describe("and enabling", function()
                    it("shouldn't call [player].components.locomotor:Stop()", function()
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                        Player.SetMovementPrediction(true, inst)
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                    end)

                    it("should call [player].EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        Player.SetMovementPrediction(true, inst)
                        assert.spy(inst.EnableMovementPrediction).was_called(1)
                        assert.spy(inst.EnableMovementPrediction).was_called_with(
                            match.is_ref(inst),
                            true
                        )
                    end)

                    it("should call TheSim:SetSetting()", function()
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(_G.TheSim.SetSetting).was_called(1)
                        assert.spy(_G.TheSim.SetSetting).was_called_with(
                            match.is_ref(_G.TheSim),
                            "misc",
                            "movementprediction",
                            "false"
                        )
                    end)

                    it("should return true", function()
                        assert.is_true(Player.SetMovementPrediction(true, inst))
                    end)
                end)

                describe("and disabling", function()
                    it("should call [player].components.locomotor:Stop()", function()
                        assert.spy(inst.components.locomotor.Stop).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(inst.components.locomotor.Stop).was_called(1)
                        assert.spy(inst.components.locomotor.Stop).was_called_with(
                            match.is_ref(inst.components.locomotor)
                        )
                    end)

                    it("should call [player].EnableMovementPrediction()", function()
                        assert.spy(inst.EnableMovementPrediction).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(inst.EnableMovementPrediction).was_called(1)
                        assert.spy(inst.EnableMovementPrediction).was_called_with(
                            match.is_ref(inst),
                            false
                        )
                    end)

                    it("should call TheSim:SetSetting()", function()
                        assert.spy(_G.TheSim.SetSetting).was_not_called()
                        Player.SetMovementPrediction(false, inst)
                        assert.spy(_G.TheSim.SetSetting).was_called(1)
                        assert.spy(_G.TheSim.SetSetting).was_called_with(
                            match.is_ref(_G.TheSim),
                            "misc",
                            "movementprediction",
                            "false"
                        )
                    end)

                    it("should return false", function()
                        assert.is_false(Player.SetMovementPrediction(false, inst))
                    end)
                end)
            end)
        end)

        describe("ToggleMovementPrediction", function()
            describe("when movement prediction is enabled", function()
                before_each(function()
                    Player.HasMovementPrediction = spy.new(ReturnValueFn(true))
                end)

                it("should return false", function()
                    assert.is_false(Player.ToggleMovementPrediction(inst))
                end)
            end)

            describe("when movement prediction is disabled", function()
                before_each(function()
                    Player.HasMovementPrediction = spy.new(ReturnValueFn(false))
                end)

                it("should return false", function()
                    assert.is_true(Player.ToggleMovementPrediction(inst))
                end)
            end)
        end)
    end)
end)
