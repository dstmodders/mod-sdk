local Module = {}

local SDK

function Module._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Module, "Module", "ThePlayer")
end

function Module.Foo()
    return "bar"
end

return Module
