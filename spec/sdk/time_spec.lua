require("busted.runner")()

describe("#sdk SDK.Time", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Time

    setup(function()
        match = require("luassert.match")
    end)

    teardown(function()
        -- globals
        _G.SetPause = nil
        _G.TheSim = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.SetPause = spy.new(Empty)

        _G.TheSim = mock({
            GetTimeScale = ReturnValueFn(1),
            SetTimeScale = Empty,
        })

        _G.TheWorld = {
            ismastersim = false,
        }

        -- initialization
        SDK = require("yoursubdirectory/sdk/sdk/sdk")
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Time")
        Time = require("yoursubdirectory/sdk/sdk/time")

        SetTestModule(Time)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.Time." .. fn_name .. "():", ...)
    end

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[time]", ...)
    end

    describe("pause", function()
        describe("IsPaused()", function()
            local fn = function()
                return Time.IsPaused()
            end

            describe("when TheSim:GetTimeScale() returns 0", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(0))
                end)

                TestReturnTrue(fn)
            end)

            describe("when TheSim:GetTimeScale() returns a non-0 value", function()
                before_each(function()
                    _G.TheSim.GetTimeScale = spy.new(ReturnValueFn(1))
                end)

                TestReturnFalse(fn)
            end)
        end)

        describe("Pause()", function()
            local fn = function()
                return Time.Pause()
            end

            local function TestLocal()
                it("should set Time.time_scale_prev field", function()
                    Time.time_scale_prev = nil
                    fn()
                    assert.is_equal(1, Time.time_scale_prev)
                end)

                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    fn()
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(match.is_ref(_G.TheSim), 0)
                end)

                it("should call SetPause()", function()
                    assert.spy(_G.SetPause).was_not_called()
                    fn()
                    assert.spy(_G.SetPause).was_called(1)
                    assert.spy(_G.SetPause).was_called_with(true, "console")
                end)

                TestReturnTrue(fn)
            end

            describe("when the game is paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(true))
                    SDK.Debug.Error = spy.new(ReturnValueFn(true))
                end)

                TestDebugError(fn, "Pause", "Game is already paused")
                TestReturnFalse(fn)
            end)

            describe("when the game is not paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(false))
                end)

                describe("and in a gameplay", function()
                    before_each(function()
                        _G.InGamePlay = spy.new(ReturnValueFn(true))
                    end)

                    describe("and is master simulation", function()
                        before_each(function()
                            _G.TheWorld.ismastersim = true
                        end)

                        TestLocal()
                    end)

                    describe("and is non-master simulation", function()
                        setup(function()
                            SDK.LoadModule("Remote")
                        end)

                        teardown(function()
                            SDK.UnloadModule("Remote")
                        end)

                        before_each(function()
                            _G.TheWorld.ismastersim = false
                        end)

                        describe("and SDK.Remote.SetTimeScale() returns false", function()
                            before_each(function()
                                SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call SDK.Remote.SetTimeScale()", function()
                                assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.SetTimeScale).was_called_with(0)
                            end)

                            TestDebugString(fn, "Pause game")
                            TestLocal()
                        end)

                        describe("and SDK.Remote.SetTimeScale() returns true", function()
                            before_each(function()
                                SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call SDK.Remote.SetTimeScale()", function()
                                assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.SetTimeScale).was_called_with(0)
                            end)

                            it("should debug strings", function()
                                if SDK.IsLoaded("Debug") then
                                    assert.spy(SDK.Debug.String).was_not_called()
                                    fn()
                                    assert.spy(SDK.Debug.String).was_called(2)
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[time]",
                                        "Pause game"
                                    )
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[notice]",
                                        "SDK.Time.Pause():",
                                        "Other players will experience a client-side time scale "
                                            .. "mismatch"
                                    )
                                end
                            end)

                            TestLocal()
                        end)
                    end)
                end)
            end)
        end)

        describe("Resume()", function()
            local fn = function()
                return Time.Resume()
            end

            local function TestLocal()
                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    fn()
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(
                        match.is_ref(_G.TheSim),
                        Time.time_scale_prev
                    )
                end)

                it("should call SetPause()", function()
                    assert.spy(_G.SetPause).was_not_called()
                    fn()
                    assert.spy(_G.SetPause).was_called(1)
                    assert.spy(_G.SetPause).was_called_with(false, "console")
                end)

                TestReturnTrue(fn)
            end

            describe("when the game is not paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(false))
                end)

                TestDebugError(fn, "Resume", "Game is already resumed")
                TestReturnFalse(fn)
            end)

            describe("when the game is paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(true))
                end)

                describe("and in a gameplay", function()
                    before_each(function()
                        _G.InGamePlay = spy.new(ReturnValueFn(true))
                    end)

                    describe("and is master simulation", function()
                        before_each(function()
                            _G.TheWorld.ismastersim = true
                        end)

                        TestDebugString(fn, "Resume game")
                        TestLocal()
                    end)

                    describe("and is non-master simulation", function()
                        setup(function()
                            SDK.LoadModule("Remote")
                        end)

                        teardown(function()
                            SDK.UnloadModule("Remote")
                        end)

                        before_each(function()
                            _G.TheWorld.ismastersim = false
                        end)

                        describe("and Time.Remote.SetTimeScale() returns false", function()
                            before_each(function()
                                SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call SDK.Remote.SetTimeScale()", function()
                                assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.SetTimeScale).was_called_with(
                                    Time.time_scale_prev
                                )
                            end)

                            TestDebugString(fn, "Resume game")
                            TestLocal()
                        end)

                        describe("and SDK.Remote.SetTimeScale() returns true", function()
                            before_each(function()
                                SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call SDK.Remote.SetTimeScale()", function()
                                assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                                assert.spy(SDK.Remote.SetTimeScale).was_called_with(
                                    Time.time_scale_prev
                                )
                            end)

                            it("should debug strings", function()
                                if SDK.IsLoaded("Debug") then
                                    assert.spy(SDK.Debug.String).was_not_called()
                                    fn()
                                    assert.spy(SDK.Debug.String).was_called(2)
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[time]",
                                        "Resume game"
                                    )
                                    assert.spy(SDK.Debug.String).was_called_with(
                                        "[notice]",
                                        "SDK.Time.Resume():",
                                        "Other players will experience a client-side time scale "
                                            .. "mismatch"
                                    )
                                end
                            end)

                            TestLocal()
                        end)
                    end)
                end)
            end)
        end)

        describe("TogglePause()", function()
            local fn = function()
                return Time.TogglePause()
            end

            before_each(function()
                Time.Pause = spy.new(Empty)
                Time.Resume = spy.new(Empty)
            end)

            describe("when the world is paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(true))
                end)

                it("should call Time.Resume()", function()
                    assert.spy(Time.Resume).was_not_called()
                    fn()
                    assert.spy(Time.Resume).was_called(1)
                    assert.spy(Time.Resume).was_called_with()
                end)

                it("shouldn't call Time.Pause()", function()
                    assert.spy(Time.Pause).was_not_called()
                    fn()
                    assert.spy(Time.Pause).was_not_called()
                end)
            end)

            describe("when the world is not paused", function()
                before_each(function()
                    Time.IsPaused = spy.new(ReturnValueFn(false))
                end)

                it("should call Time.Pause()", function()
                    assert.spy(Time.Pause).was_not_called()
                    fn()
                    assert.spy(Time.Pause).was_called(1)
                    assert.spy(Time.Pause).was_called_with()
                end)

                it("shouldn't call Time.Resume()", function()
                    assert.spy(Time.Resume).was_not_called()
                    fn()
                    assert.spy(Time.Resume).was_not_called()
                end)
            end)
        end)
    end)

    describe("time scale", function()
        describe("SetDeltaTimeScale()", function()
            local _fn

            setup(function()
                _fn = Time.SetTimeScale
            end)

            teardown(function()
                Time.SetTimeScale = _fn
            end)

            local function TestValidDeltaIsPassed(delta, set, debug)
                local fn = function()
                    return Time.SetDeltaTimeScale(delta)
                end

                describe("when a valid delta is passed", function()
                    describe("(" .. delta .. ")", function()
                        describe("and Time.SetTimeScale() returns true", function()
                            before_each(function()
                                Time.SetTimeScale = spy.new(ReturnValueFn(true))
                            end)

                            it("should call Time.SetTimeScale()", function()
                                assert.spy(Time.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(Time.SetTimeScale).was_called(1)
                                assert.spy(Time.SetTimeScale).was_called_with(set)
                            end)

                            TestDebugString(fn, "Delta time scale:", debug)
                            TestReturnTrue(fn)
                        end)

                        describe("and Time.SetTimeScale() returns false", function()
                            before_each(function()
                                Time.SetTimeScale = spy.new(ReturnValueFn(false))
                            end)

                            it("should call Time.SetTimeScale()", function()
                                assert.spy(Time.SetTimeScale).was_not_called()
                                fn()
                                assert.spy(Time.SetTimeScale).was_called(1)
                                assert.spy(Time.SetTimeScale).was_called_with(set)
                            end)

                            TestDebugString(fn, "Delta time scale:", debug)
                            TestReturnFalse(fn)
                        end)
                    end)
                end)
            end

            TestArgNumber("SetDeltaTimeScale", {
                empty = {},
                invalid = { "foo" },
                valid = { 0.5 },
            }, "delta")

            TestValidDeltaIsPassed(-5, 0, "-5.00")
            TestValidDeltaIsPassed(-0.1, 0.9, "-0.10")
            TestValidDeltaIsPassed(0.1, 1.1, "0.10")
            TestValidDeltaIsPassed(5, 4.00, "5.00")
        end)

        describe("SetTimeScale()", function()
            local fn = function()
                return Time.SetTimeScale(1)
            end

            local function TestLocal()
                it("should call TheSim:SetTimeScale()", function()
                    assert.spy(_G.TheSim.SetTimeScale).was_not_called()
                    fn()
                    assert.spy(_G.TheSim.SetTimeScale).was_called(1)
                    assert.spy(_G.TheSim.SetTimeScale).was_called_with(match.is_ref(_G.TheSim), 1)
                end)

                TestReturnTrue(fn)
            end

            TestArgUnsigned("SetTimeScale", {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { -1 },
                valid = { 1 },
            }, "time_scale")

            describe("and in a gameplay", function()
                before_each(function()
                    _G.InGamePlay = spy.new(ReturnValueFn(true))
                end)

                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    TestLocal()
                end)

                describe("and is non-master simulation", function()
                    setup(function()
                        SDK.LoadModule("Remote")
                    end)

                    teardown(function()
                        SDK.UnloadModule("Remote")
                    end)

                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    describe("and SDK.Remote.SetTimeScale() returns false", function()
                        before_each(function()
                            SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(false))
                        end)

                        it("should call SDK.Remote.SetTimeScale()", function()
                            assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                            fn()
                            assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.SetTimeScale).was_called_with(1)
                        end)

                        TestLocal()
                    end)

                    describe("and SDK.Remote.SetTimeScale() returns true", function()
                        before_each(function()
                            SDK.Remote.SetTimeScale = spy.new(ReturnValueFn(true))
                        end)

                        it("should call SDK.Remote.SetTimeScale()", function()
                            assert.spy(SDK.Remote.SetTimeScale).was_not_called()
                            fn()
                            assert.spy(SDK.Remote.SetTimeScale).was_called(1)
                            assert.spy(SDK.Remote.SetTimeScale).was_called_with(1)
                        end)

                        TestLocal()
                    end)
                end)
            end)
        end)
    end)
end)
