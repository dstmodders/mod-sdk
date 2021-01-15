local Submodule = {}

function Submodule.Bar()
    return "bar"
end

function Submodule._DoInit()
    return Submodule
end

return Submodule
