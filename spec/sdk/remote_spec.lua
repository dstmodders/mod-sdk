require "busted.runner"()

describe("#sdk SDK.Remote", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Remote

    setup(function()
        -- match
        match = require "luassert.match"

        -- globals
        _G.ThePlayer = mock({
            GUID = 1,
            userid = "KU_foobar",
        })
    end)

    teardown(function()
        -- globals
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheSim = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 0, 3
            end,
        })

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        Remote = require "yoursubdirectory/sdk/sdk/remote"

        SetTestModule(Remote)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end

        Remote.Send = spy.on(Remote, "Send")
    end)

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

    local function TestRemoteValid(name, debug, send, ...)
        local args = { ... }
        local description = "when no arguments are passed"
        if #args > 1 then
            description = "when valid arguments are passed"
        elseif #args == 1 then
            description = "when a valid argument is passed"
        end

        describe(description, function()
            local fn = function()
                return Remote[name](unpack(args))
            end

            it("should debug string", function()
                AssertDebugString(fn, "[remote]", unpack(debug))
            end)

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(fn, send)
            end)

            TestReturnTrue(fn)
        end)
    end

    describe("general", function()
        describe("Send()", function()
            describe("when different data types are passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                    end, '1, 0.12, "test"')
                end)
            end)

            describe("when serialized data is passed without is_serialized", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send(
                            "%s.components.temperature:SetTemperature(%s)",
                            SDK.Remote.Serialize({ _G.ThePlayer, 36 })
                        )
                    end, 'LookupPlayerInstByUserID("KU_foobar")'
                        .. '.components.temperature:SetTemperature(36)')
                end)
            end)

            describe("when serialized data is passed with is_serialized", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send(
                            "%s.components.temperature:SetTemperature(%s)",
                            { _G.ThePlayer, 36 },
                            true
                        )
                    end, 'LookupPlayerInstByUserID("KU_foobar")'
                        .. '.components.temperature:SetTemperature(36)')
                end)
            end)

            it("should call TheSim:GetPosition()", function()
                assert.spy(_G.TheSim.GetPosition).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.GetPosition).was_called(1)
                assert.spy(_G.TheSim.GetPosition).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:ProjectScreenPos()", function()
                assert.spy(_G.TheSim.ProjectScreenPos).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.ProjectScreenPos).was_called(1)
                assert.spy(_G.TheSim.ProjectScreenPos).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:SendRemoteExecute()", function()
                AssertSendWasCalled(function()
                    Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                end, 'TheWorld:PushEvent("ms_setseason", "autumn")')
            end)
        end)

        describe("Serialize()", function()
            local function TestValid(what, value, serialized)
                describe("when " .. what .. " as a single value is passed", function()
                    it("should return a serialized value", function()
                        assert.is_same(serialized, Remote.Serialize(value))
                    end)
                end)
            end

            local function TestValidTable(what, value, serialized)
                describe("when " .. what .. " as one of the values is passed", function()
                    it("should return serialized values", function()
                        assert.is_same({ serialized }, Remote.Serialize({ value }))
                    end)
                end)
            end

            TestValid("a boolean (false)", false, "false")
            TestValid("a boolean (true)", true, "true")
            TestValid("a float number", 0.5, "0.50")
            TestValid("a nil (as a string)", "nil", "nil")
            TestValid("a number", 0, "0")
            TestValid("a point", Vector3(1, 0, 3), "Vector3(1.00, 0.00, 3.00)")
            TestValid("a string", "foo", '"foo"')
            TestValid("ThePlayer", _G.ThePlayer, 'LookupPlayerInstByUserID("KU_foobar")')

            TestValidTable("a boolean (false)", false, "false")
            TestValidTable("a boolean (true)", true, "true")
            TestValidTable("a float number", 0.5, "0.50")
            TestValidTable("a nil (as a string)", "nil", "nil")
            TestValidTable("a number", 0, "0")
            TestValidTable("a string", "foo", '"foo"')
            TestValidTable("an array (with only booleans)", { true, false }, "{ true, false }")
            TestValidTable("an array (with only floats)", { 0.25, 0.5, 1.0 }, "{ 0.25, 0.50, 1 }")
            TestValidTable("an array (with only numbers)", { 1, 2, 3 }, "{ 1, 2, 3 }")
            TestValidTable("an array (with only strings)", { "foo", "bar" }, '{ "foo", "bar" }')

            TestValidTable(
                "an array (with mixed values)",
                { 1, "foo", true, 0.25 },
                '{ 1, "foo", true, 0.25 }'
            )

            TestValidTable("an empty table", {}, "{}")
            TestValidTable("ThePlayer", _G.ThePlayer, 'LookupPlayerInstByUserID("KU_foobar")')

            TestValidTable(
                "a table (with key-value pairs)",
                { foo = "foo", bar = "bar" },
                '{ bar = "bar", foo = "foo" }'
            )

            describe("when non-serializable data as one of the values is passed", function()
                TestReturnNil(function()
                    return Remote.Serialize({ "foo", 0, 0.5, 1, true, false, _G.TheSim })
                end)
            end)
        end)

        describe("SetTimeScale()", function()
            local fn_name = "SetTimeScale"

            TestArgUnsigned(fn_name, {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { "foo" },
                valid = { 1 },
            }, "time_scale")

            TestRemoteInvalid(fn_name, nil, "foo")
            TestRemoteValid(fn_name, { "Time scale:", "1.00" }, 'TheSim:SetTimeScale(1)', 1)
            TestRemoteValid(fn_name, { "Time scale:", "0.50" }, 'TheSim:SetTimeScale(0.50)', 0.5)
        end)
    end)
end)
