require "busted.runner"()

describe("#sdk SDK.Console", function()
    -- before_each initialization
    local SDK
    local Console

    before_each(function()
        SDK = require "sdk/sdk"
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        Console = require "sdk/console"
        Console._DoInit(SDK)
    end)
end)
