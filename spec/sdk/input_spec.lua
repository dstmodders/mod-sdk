require "busted.runner"()

describe("#sdk SDK.Input", function()
    -- before_each initialization
    local SDK
    local Input

    setup(function()
    end)

    teardown(function()
        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("FrontEnd")
        SDK.LoadModule("Input")
        Input = require "yoursubdirectory/sdk/sdk/input"

        SetTestModule(Input)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    after_each(function()
        package.loaded["yoursubdirectory/sdk/sdk/sdk"] = nil
    end)

    local function TestDebugError(fn, fn_name, ...)
        _G.TestDebugError(fn, "SDK.Input." .. fn_name .. "():", ...)
    end

    local function TestDebugErrorOptions(fn, fn_name, key, msg)
        TestDebugError(fn, fn_name, "[" .. key .. "]", "Invalid options passed (" .. msg .. ")")
    end

    describe("helper", function()
        describe("PrepareOptions()", function()
            local fn_name, key, options

            setup(function()
                fn_name = "Test"
                key = "test"
            end)

            describe("when options as string type is passed", function()
                options = ""

                local fn = function()
                    return Input._PrepareOptions(fn_name, key, options)
                end

                TestDebugErrorOptions(fn, fn_name, key, "must be a table")
                TestReturnFalse(fn)
            end)

            describe("when options as number type is passed", function()
                options = 1

                local fn = function()
                    return Input._PrepareOptions(fn_name, key, options)
                end

                TestDebugErrorOptions(fn, fn_name, key, "must be a table")
                TestReturnFalse(fn)
            end)

            describe("when options as nil type is passed", function()
                options = nil

                local fn = function()
                    return Input._PrepareOptions(fn_name, key)
                end

                it("should return default options", function()
                    assert.is_same({
                        ignore_screens = {},
                    }, fn())
                end)
            end)

            describe("when options as table type is passed", function()
                local fn

                options = {}

                fn = function()
                    return Input._PrepareOptions(fn_name, key, options)
                end

                it("should return options", function()
                    assert.is_same(options, fn())
                end)

                describe("and options.ignore_screens is invalid (string)", function()
                    options = {
                        ignore_screens = "",
                    }

                    fn = function()
                        return Input._PrepareOptions(fn_name, key, options)
                    end

                    TestDebugErrorOptions(fn, fn_name, key, "ignore_screens must be a table")
                    TestReturnFalse(fn)
                end)

                describe("and options.ignore_screens is valid (table)", function()
                    options = {
                        ignore_screens = { "ConsoleScreen" },
                    }

                    fn = function()
                        return Input._PrepareOptions(fn_name, key, options)
                    end

                    it("should return options", function()
                        assert.is_same(options, fn())
                    end)
                end)

                describe("and options.ignore_has_input_focus is invalid (string)", function()
                    options = {
                        ignore_has_input_focus = "",
                    }

                    fn = function()
                        return Input._PrepareOptions(fn_name, key, options)
                    end

                    TestDebugErrorOptions(
                        fn,
                        fn_name,
                        key,
                        "ignore_has_input_focus must be a boolean or a table"
                    )
                    TestReturnFalse(fn)
                end)

                describe("and options.ignore_has_input_focus is valid (boolean)", function()
                    options = {
                        ignore_has_input_focus = true,
                    }

                    fn = function()
                        return Input._PrepareOptions(fn_name, key, options)
                    end

                    it("should return options", function()
                        assert.is_same(options, fn())
                    end)
                end)

                describe("and options.ignore_has_input_focus is valid (table)", function()
                    options = {
                        ignore_has_input_focus = { "ServerListingScreen" },
                    }

                    fn = function()
                        return Input._PrepareOptions(fn_name, key, options)
                    end

                    it("should return options", function()
                        assert.is_same(options, fn())
                    end)
                end)
            end)
        end)

        describe("HandleKey()", function()
            local GetActiveScreenName, HasInputFocus, IsScreenOpen
            local options, spy_fn
            local fn

            setup(function()
                GetActiveScreenName = SDK.FrontEnd.GetActiveScreenName
                HasInputFocus = SDK.FrontEnd.HasInputFocus
                IsScreenOpen = SDK.FrontEnd.IsScreenOpen
            end)

            teardown(function()
                SDK.FrontEnd.GetActiveScreenName = GetActiveScreenName
                SDK.FrontEnd.HasInputFocus = HasInputFocus
                SDK.FrontEnd.IsScreenOpen = IsScreenOpen
            end)

            before_each(function()
                spy_fn = spy.new(Empty)
            end)

            describe("when doesn't have an input focus", function()
                before_each(function()
                    SDK.FrontEnd.HasInputFocus = ReturnValueFn(false)
                end)

                describe("and empty options are passed", function()
                    options = {}
                    fn = function()
                        return Input._HandleKey(options, spy_fn)
                    end

                    it("should call function", function()
                        assert.spy(spy_fn).was_not_called()
                        fn()
                        assert.spy(spy_fn).was_called(1)
                    end)
                end)

                describe("and ignore_screens option is passed", function()
                    setup(function()
                        options = { ignore_screens = { "ConsoleScreen" } }
                    end)

                    describe("and matches an open screen", function()
                        fn = function()
                            return Input._HandleKey(options, spy_fn)
                        end

                        before_each(function()
                            SDK.FrontEnd.IsScreenOpen = ReturnValueFn(true)
                        end)

                        it("shouldn't call function", function()
                            assert.spy(spy_fn).was_not_called()
                            fn()
                            assert.spy(spy_fn).was_not_called()
                        end)
                    end)

                    describe("and doesn't match an open screen", function()
                        fn = function()
                            return Input._HandleKey(options, spy_fn)
                        end

                        before_each(function()
                            SDK.FrontEnd.IsScreenOpen = ReturnValueFn(false)
                        end)

                        it("should call function", function()
                            assert.spy(spy_fn).was_not_called()
                            fn()
                            assert.spy(spy_fn).was_called(1)
                        end)
                    end)
                end)
            end)

            describe("when has an input focus", function()
                before_each(function()
                    SDK.FrontEnd.HasInputFocus = ReturnValueFn(true)
                end)

                describe("and empty options are passed", function()
                    options = {}
                    fn = function()
                        return Input._HandleKey(options, spy_fn)
                    end

                    it("shouldn't call function", function()
                        assert.spy(spy_fn).was_not_called()
                        fn()
                        assert.spy(spy_fn).was_not_called()
                    end)
                end)

                describe("and ignore_has_input_focus option is passed", function()
                    describe("and it's false", function()
                        options = { ignore_has_input_focus = false }
                        fn = function()
                            return Input._HandleKey(options, spy_fn)
                        end

                        it("should call function", function()
                            assert.spy(spy_fn).was_not_called()
                            fn()
                            assert.spy(spy_fn).was_not_called()
                        end)
                    end)

                    describe("and it's true", function()
                        options = { ignore_has_input_focus = true }
                        fn = function()
                            return Input._HandleKey(options, spy_fn)
                        end

                        it("should call function", function()
                            assert.spy(spy_fn).was_not_called()
                            fn()
                            assert.spy(spy_fn).was_called(1)
                        end)
                    end)

                    describe("and it's a table", function()
                        options = { ignore_has_input_focus = { "ServerListingScreen" } }
                        fn = function()
                            return Input._HandleKey(options, spy_fn)
                        end

                        describe("and doesn't match an open screen", function()
                            before_each(function()
                                SDK.FrontEnd.GetActiveScreenName = ReturnValueFn("MainScreen")
                            end)

                            it("shouldn't call function", function()
                                assert.spy(spy_fn).was_not_called()
                                fn()
                                assert.spy(spy_fn).was_not_called()
                            end)
                        end)

                        describe("and matches an open screen", function()
                            before_each(function()
                                SDK.FrontEnd.GetActiveScreenName = ReturnValueFn(
                                    "ServerListingScreen"
                                )
                            end)

                            it("should call function", function()
                                assert.spy(spy_fn).was_not_called()
                                fn()
                                assert.spy(spy_fn).was_called(1)
                            end)
                        end)
                    end)
                end)
            end)

            describe("when options.ignore_screens is passed", function()
                describe("and matches an open screen", function()
                    options = { ignore_screens = { "ConsoleScreen" } }
                    fn = function()
                        return Input._HandleKey(options, spy_fn)
                    end

                    before_each(function()
                        SDK.FrontEnd.IsScreenOpen = spy.new(ReturnValueFn(true))
                    end)

                    it("shouldn't call function", function()
                        assert.spy(spy_fn).was_not_called()
                        fn()
                        assert.spy(spy_fn).was_not_called()
                    end)
                end)

                describe("and doesn't match an open screen", function()
                    options = { ignore_screens = { "ConsoleScreen" } }
                    fn = function()
                        return Input._HandleKey(options, spy_fn)
                    end

                    before_each(function()
                        SDK.FrontEnd.IsScreenOpen = spy.new(ReturnValueFn(false))
                    end)

                    it("should call function", function()
                        assert.spy(spy_fn).was_not_called()
                        fn()
                        assert.spy(spy_fn).was_called(1)
                    end)
                end)
            end)
        end)
    end)
end)
