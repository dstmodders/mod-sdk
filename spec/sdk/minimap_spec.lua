require "busted.runner"()

describe("#sdk SDK.MiniMap", function()
    -- before_each initialization
    local SDK
    local MiniMap

    setup(function()
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("MiniMap")
        MiniMap = require "yoursubdirectory/sdk/sdk/minimap"
    end)

    teardown(function()
        LoadSDK()
    end)

    describe("general", function()
        describe("should have a", function()
            describe("getter", function()
                local getters = {
                    is_clearing = "IsClearing",
                    is_fog_of_war = "IsFogOfWar",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(MiniMap, field, getter)
                    end)
                end
            end)
        end)
    end)
end)
