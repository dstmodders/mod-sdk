local Module = {}

local SDK

function Module.Foo()
    return "bar"
end

function Module._DoInit(sdk, submodules)
    SDK = sdk

    submodules = submodules ~= nil and submodules or {
        Submodule = "spec/submodule",
    }

    SDK._SetModuleName(SDK, Module, "Module")
    SDK.LoadSubmodules(Module, submodules)

    return SDK._DoInitModule(SDK, Module, "Module", "TheWorld")
end

return Module
