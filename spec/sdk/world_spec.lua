require "busted.runner"()

describe("#sdk SDK.World", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local World

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        -- globals
        _G.SetPause = nil
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheSim = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.SetPause = spy.new(Empty)

        _G.TheNet = mock({
            SendWorldRollbackRequestToServer = Empty,
        })

        _G.ThePlayer = {}

        _G.TheSim = mock({
            GetTimeScale = ReturnValueFn(1),
            SetTimeScale = Empty,
        })

        _G.TheWorld = mock({
            meta = {
                saveversion = "5.031",
                seed = "1574459949",
            },
            net = {
                components = {},
            },
            state = {},
            HasTag = function(_, tag)
                return tag == "forest"
            end
        })

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        SDK.LoadModule("World")
        World = require "yoursubdirectory/sdk/sdk/world"

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
            string.format("SDK.World.%s():", fn_name),
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

    describe("general", function()
        describe("GetMeta()", function()
            describe("when no name is passed", function()
                it("should return TheWorld.meta", function()
                    assert.is_equal(_G.TheWorld.meta, World.GetMeta())
                end)
            end)

            describe("when the name is passed", function()
                it("should return TheWorld.meta field value", function()
                    assert.is_equal(_G.TheWorld.meta.saveversion, World.GetMeta("saveversion"))
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetMeta("saveversion"))
                    end, _G.TheWorld, "meta", "saveversion")
                end)
            end)
        end)

        describe("GetSeed()", function()
            it("should return TheWorld.meta.seed", function()
                assert.is_equal(_G.TheWorld.meta.seed, World.GetSeed())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetSeed())
                    end, _G.TheWorld, "meta", "seed")
                end)
            end)
        end)

        describe("IsPointPassable()", function()
            local pt

            before_each(function()
                _G.TheWorld = {
                    Map = {
                        IsPassableAtPoint = spy.new(ReturnValueFn(true)),
                    },
                }

                pt = {
                    Get = spy.new(ReturnValuesFn(1, 0, -1)),
                }
            end)

            describe("when some passed world fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(World.IsPointPassable(pt))
                    end, _G.TheWorld, "Map", "IsPassableAtPoint")
                end)
            end)

            describe("when some passed pos fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(World.IsPointPassable(pt))
                    end, pt, "Get")
                end)
            end)

            it("should call pos:Get()", function()
                assert.spy(pt.Get).was_called(0)
                World.IsPointPassable(pt)
                assert.spy(pt.Get).was_called(1)
                assert.spy(pt.Get).was_called_with(match.is_ref(pt))
            end)

            it("should call world.Map:IsPassableAtPoint()", function()
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(0)
                World.IsPointPassable(pt)
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called(1)
                assert.spy(_G.TheWorld.Map.IsPassableAtPoint).was_called_with(
                    match.is_ref(_G.TheWorld.Map),
                    1,
                    0,
                    -1
                )
            end)

            it("should return true", function()
                assert.is_true(World.IsPointPassable(pt))
            end)
        end)

        describe("Rollback()", function()
            describe("when invalid days are passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        World.Rollback("foo")
                    end, "Rollback", "days", "must be an unsigned integer")
                end)

                it("should return false", function()
                    assert.is_false(World.Rollback("foo"))
                end)
            end)

            describe("when valid days are passed", function()
                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    it("should debug string", function()
                        AssertDebugString(function()
                            World.Rollback(1)
                        end, "[world]", "Rollback:", "1 day")
                    end)

                    it("should call TheNet:SendWorldRollbackRequestToServer()", function()
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        World.Rollback(1)
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called(1)
                        assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_called_with(
                            match.is_ref(_G.TheNet),
                            1
                        )
                    end)

                    it("should return true", function()
                        assert.is_true(World.SetTimeScale(1))
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    describe("and SDK.Remote.World.Rollback() returns false", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.Rollback
                        end)

                        before_each(function()
                            SDK.Remote.World.Rollback = spy.new(ReturnValueFn(false))
                        end)

                        teardown(function()
                            SDK.Remote.World.Rollback = _fn
                        end)

                        it("should call SDK.Remote.World.Rollback()", function()
                            assert.spy(SDK.Remote.World.Rollback).was_not_called()
                            World.Rollback(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheSim:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            World.Rollback(1)
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        it("should return false", function()
                            assert.is_false(World.Rollback(1))
                        end)
                    end)

                    describe("and SDK.Remote.World.Rollback() returns true", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.Rollback
                        end)

                        before_each(function()
                            SDK.Remote.World.Rollback = spy.new(ReturnValueFn(true))
                        end)

                        teardown(function()
                            SDK.Remote.World.Rollback = _fn
                        end)

                        it("should call SDK.Remote.World.Rollback()", function()
                            assert.spy(SDK.Remote.World.Rollback).was_not_called()
                            World.Rollback(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called(1)
                            assert.spy(SDK.Remote.World.Rollback).was_called_with(1)
                        end)

                        it("shouldn't call TheSim:SendWorldRollbackRequestToServer()", function()
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                            World.Rollback(1)
                            assert.spy(_G.TheNet.SendWorldRollbackRequestToServer).was_not_called()
                        end)

                        it("should return true", function()
                            assert.is_true(World.Rollback(1))
                        end)
                    end)
                end)
            end)
        end)

        describe("SetDeltaTimeScale()", function()
            local _fn

            setup(function()
                _fn = World.SetTimeScale
            end)

            teardown(function()
                World.SetTimeScale = _fn
            end)

            local function TestValidDeltaIsPassed(delta, set, debug)
                describe("when a valid delta is passed", function()
                    describe("(" .. delta .. ")", function()
                        describe("and SDK.World.SetTimeScale() returns true", function()
                            before_each(function()
                                World.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call SDK.World.SetTimeScale()", function()
                                assert.spy(World.SetTimeScale).was_not_called()
                                World.SetDeltaTimeScale(delta)
                                assert.spy(World.SetTimeScale).was_called(1)
                                assert.spy(World.SetTimeScale).was_called_with(set)
                            end)

                            it("should debug string", function()
                                AssertDebugString(function()
                                    World.SetDeltaTimeScale(delta)
                                end, "[world]", "Delta time scale:", debug)
                            end)

                            it("should return true", function()
                                assert.is_true(World.SetDeltaTimeScale(delta))
                            end)
                        end)

                        describe("and SDK.World.SetTimeScale() returns false", function()
                            before_each(function()
                                World.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call SDK.World.SetTimeScale()", function()
                                assert.spy(World.SetTimeScale).was_not_called()
                                World.SetDeltaTimeScale(delta)
                                assert.spy(World.SetTimeScale).was_called(1)
                                assert.spy(World.SetTimeScale).was_called_with(set)
                            end)

                            it("should debug string", function()
                                AssertDebugString(function()
                                    World.SetDeltaTimeScale(delta)
                                end, "[world]", "Delta time scale:", debug)
                            end)

                            it("should return false", function()
                                assert.is_false(World.SetDeltaTimeScale(delta))
                            end)
                        end)
                    end)
                end)
            end

            describe("when an invalid delta is passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        World.SetDeltaTimeScale("foo")
                    end, "SetDeltaTimeScale", "delta", "must be a number")
                end)

                it("should return false", function()
                    assert.is_false(World.SetDeltaTimeScale("foo"))
                end)
            end)

            TestValidDeltaIsPassed(-5, 0, "-5.00")
            TestValidDeltaIsPassed(-0.1, 0.9, "-0.10")
            TestValidDeltaIsPassed(0.1, 1.1, "0.10")
            TestValidDeltaIsPassed(5, 4.00, "5.00")
        end)

        describe("SetTimeScale()", function()
            describe("when an invalid timescale is passed", function()
                it("should debug error string", function()
                    AssertDebugErrorInvalidArg(function()
                        World.SetTimeScale("foo")
                    end, "SetTimeScale", "timescale", "must be an unsigned number")
                end)

                it("should return false", function()
                    assert.is_false(World.SetTimeScale("foo"))
                end)
            end)

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    World.SetTimeScale(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(match.is_ref(_G.TheSim), 1)
                end)

                it("should return true", function()
                    assert.is_true(World.SetTimeScale(1))
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                describe("and SDK.Remote.World.SetTimeScale() returns false", function()
                    local _fn

                    setup(function()
                        _fn = SDK.Remote.World.SetTimeScale
                    end)

                    before_each(function()
                        SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(false))
                    end)

                    teardown(function()
                        SDK.Remote.World.SetTimeScale = _fn
                    end)

                    it("should call SDK.Remote.World.SetTimeScale()", function()
                        assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                        World.SetTimeScale(1)
                        assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                        assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(1)
                    end)

                    it("shouldn't call TheSim:SetTimeScale()", function()
                        assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        World.SetTimeScale(1)
                        assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    end)

                    it("should return false", function()
                        assert.is_false(World.SetTimeScale(1))
                    end)
                end)

                describe("and SDK.Remote.World.SetTimeScale() returns true", function()
                    local _fn

                    setup(function()
                        _fn = SDK.Remote.World.SetTimeScale
                    end)

                    before_each(function()
                        SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(true))
                    end)

                    teardown(function()
                        SDK.Remote.World.SetTimeScale = _fn
                    end)

                    it("should call SDK.Remote.World.SetTimeScale()", function()
                        assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                        World.SetTimeScale(1)
                        assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                        assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(1)
                    end)

                    it("should call TheSim:SetTimeScale()", function()
                        assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        World.SetTimeScale(1)
                        assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                        assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                            match.is_ref(_G.TheSim),
                            1
                        )
                    end)

                    it("should return true", function()
                        assert.is_true(World.SetTimeScale(1))
                    end)
                end)
            end)
        end)
    end)

    describe("pausing", function()
        describe("IsPaused()", function()
            describe("when TheSim:GetTimeScale() returns 0", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(0))
                end)

                it("should return true", function()
                    assert.is_true(World.IsPaused())
                end)
            end)

            describe("when TheSim:GetTimeScale() returns a non-0 value", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(1))
                end)

                it("should return false", function()
                    assert.is_false(World.IsPaused())
                end)
            end)
        end)

        describe("Pause()", function()
            describe("when the world is paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(true))
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        World.Pause()
                    end, "SDK.World.Pause():", "Game is already paused")
                end)

                it("should return false", function()
                    assert.is_false(World.Pause())
                end)
            end)

            describe("when the world is not paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(false))
                end)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    it("should debug string", function()
                        AssertDebugString(function()
                            World.Pause()
                        end, "[world]", "Pause game")
                    end)

                    it("should set World.timescale field", function()
                        World.timescale = nil
                        World.Pause()
                        assert.is_equal(1, World.timescale)
                    end)

                    it("should call TheSim:SetTimeScale()", function()
                        assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        World.Pause()
                        assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                        assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                            match.is_ref(_G.TheSim),
                            0
                        )
                    end)

                    it("should call SetPause()", function()
                        assert.spy(_G.SetPause).was_not_called()
                        World.Pause()
                        assert.spy(_G.SetPause).was_called(1)
                        assert.spy(_G.SetPause).was_called_with(true, "console")
                    end)

                    it("should return true", function()
                        assert.is_true(World.Pause())
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    describe("and SDK.Remote.World.SetTimeScale() returns false", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.SetTimeScale
                        end)

                        before_each(function()
                            SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(false))
                        end)

                        teardown(function()
                            SDK.Remote.World.SetTimeScale = _fn
                        end)

                        it("should call SDK.Remote.World.SetTimeScale()", function()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                            World.Pause()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(0)
                        end)

                        it("shouldn't call TheSim:SetTimeScale()", function()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                            World.Pause()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        end)

                        it("should return false", function()
                            assert.is_false(World.Pause())
                        end)
                    end)

                    describe("and SDK.Remote.World.SetTimeScale() returns true", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.SetTimeScale
                        end)

                        before_each(function()
                            SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(true))
                        end)

                        teardown(function()
                            SDK.Remote.World.SetTimeScale = _fn
                        end)

                        it("should call SDK.Remote.World.SetTimeScale()", function()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                            World.Pause()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(0)
                        end)

                        it("should debug strings", function()
                            assert.spy(SDK.Debug.String).was_not_called()
                            World.Pause()
                            assert.spy(SDK.Debug.String).was_called(2)
                            assert.spy(SDK.Debug.String).was_called_with("[world]", "Pause game")
                            assert.spy(SDK.Debug.String).was_called_with(
                                "[notice]",
                                "SDK.World.Pause():",
                                "Other players will experience a client-side time scale mismatch"
                            )
                        end)

                        it("should set World.timescale field", function()
                            World.timescale = nil
                            World.Pause()
                            assert.is_equal(1, World.timescale)
                        end)

                        it("should call TheSim:SetTimeScale()", function()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                            World.Pause()
                            assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                            assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                                match.is_ref(_G.TheSim),
                                0
                            )
                        end)

                        it("should call SetPause()", function()
                            assert.spy(_G.SetPause).was_not_called()
                            World.Pause()
                            assert.spy(_G.SetPause).was_called(1)
                            assert.spy(_G.SetPause).was_called_with(true, "console")
                        end)

                        it("should return true", function()
                            assert.is_true(World.Pause())
                        end)
                    end)
                end)
            end)
        end)

        describe("Resume()", function()
            describe("when the world is not paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(false))
                end)

                it("should debug error string", function()
                    AssertDebugError(function()
                        World.Resume()
                    end, "SDK.World.Resume():", "Game is already resumed")
                end)

                it("should return false", function()
                    assert.is_false(World.Resume())
                end)
            end)

            describe("when the world is paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(true))
                end)

                describe("when is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    it("should debug string", function()
                        AssertDebugString(function()
                            World.Resume()
                        end, "[world]", "Resume game")
                    end)

                    it("should call TheSim:SetTimeScale()", function()
                        assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        World.Resume()
                        assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                        assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                            match.is_ref(_G.TheSim),
                            World.timescale
                        )
                    end)

                    it("should call SetPause()", function()
                        assert.spy(_G.SetPause).was_not_called()
                        World.Resume()
                        assert.spy(_G.SetPause).was_called(1)
                        assert.spy(_G.SetPause).was_called_with(false, "console")
                    end)

                    it("should return true", function()
                        assert.is_true(World.Resume())
                    end)
                end)

                describe("when is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    describe("and SDK.Remote.World.SetTimeScale() returns false", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.SetTimeScale
                        end)

                        before_each(function()
                            SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(false))
                        end)

                        teardown(function()
                            SDK.Remote.World.SetTimeScale = _fn
                        end)

                        it("should call SDK.Remote.World.SetTimeScale()", function()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                            World.Resume()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(1)
                        end)

                        it("shouldn't call TheSim:SetTimeScale()", function()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                            World.Resume()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                        end)

                        it("should return false", function()
                            assert.is_false(World.Resume())
                        end)
                    end)

                    describe("and SDK.Remote.World.SetTimeScale() returns true", function()
                        local _fn

                        setup(function()
                            _fn = SDK.Remote.World.SetTimeScale
                        end)

                        before_each(function()
                            SDK.Remote.World.SetTimeScale = spy.new(ReturnValueFn(true))
                        end)

                        teardown(function()
                            SDK.Remote.World.SetTimeScale = _fn
                        end)

                        it("should call SDK.Remote.World.SetTimeScale()", function()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_not_called()
                            World.Resume()
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.World.SetTimeScale).was_called_with(1)
                        end)

                        it("should debug strings", function()
                            assert.spy(SDK.Debug.String).was_not_called()
                            World.Resume()
                            assert.spy(SDK.Debug.String).was_called(2)
                            assert.spy(SDK.Debug.String).was_called_with("[world]", "Resume game")
                            assert.spy(SDK.Debug.String).was_called_with(
                                "[notice]",
                                "SDK.World.Resume():",
                                "Other players will experience a client-side time scale mismatch"
                            )
                        end)

                        it("should call TheSim:SetTimeScale()", function()
                            assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                            World.Resume()
                            assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                            assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                                match.is_ref(_G.TheSim),
                                1
                            )
                        end)

                        it("should call SetPause()", function()
                            assert.spy(_G.SetPause).was_not_called()
                            World.Resume()
                            assert.spy(_G.SetPause).was_called(1)
                            assert.spy(_G.SetPause).was_called_with(false, "console")
                        end)

                        it("should return true", function()
                            assert.is_true(World.Resume())
                        end)
                    end)
                end)
            end)
        end)

        describe("TogglePause()", function()
            before_each(function()
                World.Pause = spy.new(Empty)
                World.Resume = spy.new(Empty)
            end)

            describe("when the world is paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(true))
                end)

                it("should call World.Resume()", function()
                    assert.spy(World.Resume).was_not_called()
                    World.TogglePause()
                    assert.spy(World.Resume).was_called(1)
                    assert.spy(World.Resume).was_called_with()
                end)

                it("shouldn't call World.Pause()", function()
                    assert.spy(World.Pause).was_not_called()
                    World.TogglePause()
                    assert.spy(World.Pause).was_not_called()
                end)
            end)

            describe("when the world is not paused", function()
                before_each(function()
                    World.IsPaused = spy.new(ReturnValueFn(false))
                end)

                it("should call World.Pause()", function()
                    assert.spy(World.Pause).was_not_called()
                    World.TogglePause()
                    assert.spy(World.Pause).was_called(1)
                    assert.spy(World.Pause).was_called_with()
                end)

                it("shouldn't call World.Resume()", function()
                    assert.spy(World.Resume).was_not_called()
                    World.TogglePause()
                    assert.spy(World.Resume).was_not_called()
                end)
            end)
        end)
    end)

    describe("phase", function()
        describe("GetPhase()", function()
            before_each(function()
                _G.TheWorld.state.cavephase = "dusk"
                _G.TheWorld.state.phase = "day"
            end)

            describe("when in the cave", function()
                before_each(function()
                    World.IsCave = ReturnValueFn(true)
                end)

                it("should return cave phase", function()
                    assert.equal("dusk", World.GetPhase())
                end)
            end)

            describe("when in the cave", function()
                before_each(function()
                    World.IsCave = ReturnValueFn(false)
                end)

                it("should return phase", function()
                    assert.equal("day", World.GetPhase())
                end)
            end)
        end)

        describe("GetPhaseNext()", function()
            describe("when the phase is passed", function()
                it("should return the next phase", function()
                    assert.is_equal("dusk", World.GetPhaseNext("day"))
                    assert.is_equal("night", World.GetPhaseNext("dusk"))
                    assert.is_equal("day", World.GetPhaseNext("night"))
                end)
            end)

            describe("when the phase is not passed", function()
                it("should return nil", function()
                    assert.is_nil(World.GetPhaseNext())
                end)
            end)
        end)

        describe("GetTimeUntilPhase()", function()
            before_each(function()
                _G.TheWorld.net.components.clock = {
                    GetTimeUntilPhase = spy.new(ReturnValueFn(10)),
                }
            end)

            it("should call TheWorld.net.components.clock:GetTimeUntilPhase()", function()
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_not_called()
                World.GetTimeUntilPhase("day")
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called(1)
                assert.spy(_G.TheWorld.net.components.clock.GetTimeUntilPhase).was_called_with(
                    match.is_ref(_G.TheWorld.net.components.clock),
                    "day"
                )
            end)

            it("should return TheWorld.net.components.clock:GetTimeUntilPhase() value", function()
                assert.is_equal(
                    _G.TheWorld.net.components.clock:GetTimeUntilPhase(),
                    World.GetTimeUntilPhase("day")
                )
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetTimeUntilPhase())
                    end, _G.TheWorld, "net", "components", "clock")
                end)
            end)
        end)
    end)

    describe("weather", function()
        describe("GetWeatherComponent()", function()
            describe("when in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.caveweather = "caveweather"
                    World.IsCave = ReturnValueFn(true)
                end)

                it("should return CaveWeather component", function()
                    assert.is_equal("caveweather", World.GetWeatherComponent())
                end)

                describe("and a caveweather component is missing", function()
                    before_each(function()
                        _G.TheWorld.net.components.caveweather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(World.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when not in the cave", function()
                before_each(function()
                    _G.TheWorld.net.components.weather = "weather"
                    World.IsCave = ReturnValueFn(false)
                end)

                it("should return Weather component", function()
                    assert.is_equal("weather", World.GetWeatherComponent())
                end)

                describe("and a weather component is not available", function()
                    before_each(function()
                        _G.TheWorld.net.components.weather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(World.GetWeatherComponent())
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(World.GetWeatherComponent())
                    end, _G.TheWorld, "net", "net", "components")
                end)
            end)
        end)
    end)
end)
