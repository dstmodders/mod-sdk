require "busted.runner"()

describe("#sdk SDK.Remote", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Remote

    setup(function()
        match = require "luassert.match"
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 2, 3
            end,
        })

        -- initialization
        SDK = require "sdk/sdk"
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        Remote = require "sdk/remote"
        Remote._DoInit(SDK)
    end)

    teardown(function()
        _G.TheNet = nil
        _G.TheSim = nil
    end)

    describe("general", function()
        describe("Send", function()
            it("should call TheSim:GetPosition()", function()
                assert.spy(_G.TheSim.GetPosition).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.GetPosition).was_called(1)
                assert.spy(_G.TheSim.GetPosition).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:GetPosition()", function()
                assert.spy(_G.TheSim.ProjectScreenPos).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.ProjectScreenPos).was_called(1)
                assert.spy(_G.TheSim.ProjectScreenPos).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:SendRemoteExecute()", function()
                assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheNet.SendRemoteExecute).was_called(1)
                assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                    match.is_ref(_G.TheNet),
                    'TheWorld:PushEvent("ms_setseason", "autumn")',
                    1,
                    3
                )
            end)

            it("should add data correctly", function()
                Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                    match.is_ref(_G.TheNet),
                    '1, 0.12, "test"',
                    1,
                    3
                )
            end)
        end)
    end)
end)
