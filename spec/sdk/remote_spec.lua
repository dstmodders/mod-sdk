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
        SDK.LoadModule("Remote")
        Remote = require "yoursubdirectory/sdk/sdk/remote"

        -- spies
        Remote.Send = spy.on(Remote, "Send")
    end)

    after_each(function()
        package.loaded["yoursubdirectory/sdk/sdk/sdk"] = nil
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

    describe("general", function()
        describe("Send()", function()
            describe("when different data types are passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                    end, '1, 0.12, "test"')
                end)
            end)

            describe("when serialized data is passed", function()
                it("should call TheSim:SendRemoteExecute()", function()
                    AssertSendWasCalled(function()
                        Remote.Send("%s:SetTemperature(%s)", SDK.Remote.Serialize({ _G.ThePlayer, 36 }))
                    end, 'LookupPlayerInstByUserID("KU_foobar"):SetTemperature(36)')
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
                describe("when " .. what .. " as one of the values is passed", function()
                    it("should return a serialized value", function()
                        assert.is_same({ serialized }, Remote.Serialize({ value }))
                    end)
                end)
            end

            TestValid("a nil (as a string)", "nil", "nil")
            TestValid("a string", "foo", '"foo"')
            TestValid("a number", 0, "0")
            TestValid("a float number", 0.5, "0.50")
            TestValid("a boolean (true)", true, "true")
            TestValid("a boolean (false)", false, "false")
            TestValid("a player", _G.ThePlayer, 'LookupPlayerInstByUserID("KU_foobar")')
            TestValid("an empty table", {}, "{}")
            TestValid("an array (with only numbers)", { 1, 2, 3 }, "{ 1, 2, 3 }")
            TestValid("an array (with only strings)", { "foo", "bar" }, '{ "foo", "bar" }')
            TestValid("an array (with only booleans)", { true, false }, "{ true, false }")
            TestValid("an array (with only floats)", { 0.25, 0.5, 1.0 }, "{ 0.25, 0.50, 1 }")

            TestValid(
                "an array (with mixed values)",
                { 1, "foo", true, 0.25 },
                '{ 1, "foo", true, 0.25 }'
            )

            TestValid(
                "a table (with key-value pairs)",
                { foo = "foo", bar = "bar" },
                '{ bar = "bar", foo = "foo" }'
            )

            describe("when non-serializable data as one of the values is passed", function()
                it("should return nil", function()
                    assert.is_nil(Remote.Serialize({ "foo", 0, 0.5, 1, true, false, _G.TheSim }))
                end)
            end)
        end)
    end)
end)
