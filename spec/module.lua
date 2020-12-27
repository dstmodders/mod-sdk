local Module = {}

local SDK

function Module._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Module, "Module")
end

return Module
