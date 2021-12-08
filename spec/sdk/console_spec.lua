require("busted.runner")()

describe("#sdk SDK.Console", function()
    -- before_each initialization
    local SDK
    local Console -- luacheck: only

    setup(function()
        SDK = require("yoursubdirectory/sdk/sdk/sdk")
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Console")
        Console = require("yoursubdirectory/sdk/sdk/console")
    end)

    teardown(function()
        LoadSDK()
    end)
end)
