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
            },
            name = name,
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
            GetCurrentPlatform = ReturnValueFn(nil),
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

        describe("IsIdle", function()
            describe("when the player is idle", function()
                describe("based on the state graph", function()
                    local function TestIdle(player)
                        it("should call [player].sg.HasStateTag", function()
                            assert.spy(player.sg.HasStateTag).was_not_called()
                            Player.IsIdle(player)
                            assert.spy(player.sg.HasStateTag).was_called(1)
                            assert.spy(player.sg.HasStateTag).was_called_with(
                                match.is_ref(player.sg),
                                "idle"
                            )
                        end)

                        it("shouldn't call [player].AnimState.IsCurrentAnimation", function()
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

                        it("should call [player].AnimState.IsCurrentAnimation", function()
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
                    it("should call [player].sg.HasStateTag", function()
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

                    it("shouldn't call [player].AnimState.IsCurrentAnimation", function()
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

                    it("should call [player].AnimState.IsCurrentAnimation", function()
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

        describe("IsMovementPrediction", function()
            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(Player.IsMovementPrediction())
                    end, _G.ThePlayer, "components", "locomotor")
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

                it("should call [player].Transform.GetWorldPosition", function()
                    assert.spy(player.Transform.GetWorldPosition).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(player.Transform.GetWorldPosition).was_called(1)
                    assert.spy(player.Transform.GetWorldPosition).was_called_with(
                        match.is_ref(player.Transform)
                    )
                end)

                it("should call TheWorld.Map.IsVisualGroundAtPoint", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn call TheWorld.Map.GetTileAtPoint", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    Player.IsOverWater(player)
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        player.Transform.GetWorldPosition()
                    )
                end)

                it("should call [player].GetCurrentPlatform", function()
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
                it("should call [player].Transform.GetWorldPosition", function()
                    EachPlayer(function(player)
                        assert.spy(player.Transform.GetWorldPosition).was_not_called()
                        Player.IsOverWater(player)
                        assert.spy(player.Transform.GetWorldPosition).was_called(1)
                        assert.spy(player.Transform.GetWorldPosition).was_called_with(
                            match.is_ref(player.Transform)
                        )
                    end, { player_over_water })
                end)

                it("should call TheWorld.Map.IsVisualGroundAtPoint", function()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called(1)
                    assert.spy(_G.TheWorld.Map.IsVisualGroundAtPoint).was_called_with(
                        match.is_ref(_G.TheWorld.Map),
                        _G.ThePlayer.Transform.GetWorldPosition()
                    )
                end)

                it("shouldn't call TheWorld.Map.GetTileAtPoint", function()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                    Player.IsOverWater()
                    assert.spy(_G.TheWorld.Map.GetTileAtPoint).was_not_called()
                end)

                it("shouldn't call [player].GetCurrentPlatform", function()
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
                    it("should call [player].sg.HasStateTag", function()
                        assert.spy(player.sg.HasStateTag).was_not_called()
                        Player.IsRunning(player)
                        assert.spy(player.sg.HasStateTag).was_called(1)
                        assert.spy(player.sg.HasStateTag).was_called_with(
                            match.is_ref(player.sg),
                            "run"
                        )
                    end)

                    it("shouldn't call [player].AnimState.IsCurrentAnimation", function()
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

                    it("should call [player].AnimState.IsCurrentAnimation", function()
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
                    it("should call [player].sg.HasStateTag", function()
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

                    it("shouldn't call [player].AnimState.IsCurrentAnimation", function()
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

                    it("should call [player].AnimState.IsCurrentAnimation", function()
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
end)
