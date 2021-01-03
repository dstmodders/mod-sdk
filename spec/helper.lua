--
-- Packages
--

_G.MOD_SDK_TEST = true

package.path = "./sdk/?.lua;" .. package.path

require "spec/class"
require "spec/vector3"

local preloads = {
    ["yoursubdirectory/sdk/sdk/sdk"] = "sdk/sdk",
    ["yoursubdirectory/sdk/sdk/config"] = "sdk/config",
    ["yoursubdirectory/sdk/sdk/console"] = "sdk/console",
    ["yoursubdirectory/sdk/sdk/constant"] = "sdk/constant",
    ["yoursubdirectory/sdk/sdk/debug"] = "sdk/debug",
    ["yoursubdirectory/sdk/sdk/debugupvalue"] = "sdk/debugupvalue",
    ["yoursubdirectory/sdk/sdk/dump"] = "sdk/dump",
    ["yoursubdirectory/sdk/sdk/entity"] = "sdk/entity",
    ["yoursubdirectory/sdk/sdk/input"] = "sdk/input",
    ["yoursubdirectory/sdk/sdk/inventory"] = "sdk/inventory",
    ["yoursubdirectory/sdk/sdk/method"] = "sdk/method",
    ["yoursubdirectory/sdk/sdk/modmain"] = "sdk/modmain",
    ["yoursubdirectory/sdk/sdk/persistentdata"] = "sdk/persistentdata",
    ["yoursubdirectory/sdk/sdk/player"] = "sdk/player",
    ["yoursubdirectory/sdk/sdk/remote"] = "sdk/remote",
    ["yoursubdirectory/sdk/sdk/rpc"] = "sdk/rpc",
    ["yoursubdirectory/sdk/sdk/test"] = "sdk/test",
    ["yoursubdirectory/sdk/sdk/thread"] = "sdk/thread",
    ["yoursubdirectory/sdk/sdk/utils"] = "sdk/utils",
    ["yoursubdirectory/sdk/sdk/utils/chain"] = "sdk/utils/chain",
    ["yoursubdirectory/sdk/sdk/utils/string"] = "sdk/utils/string",
    ["yoursubdirectory/sdk/sdk/utils/table"] = "sdk/utils/table",
    ["yoursubdirectory/sdk/sdk/utils/value"] = "sdk/utils/value",
    ["yoursubdirectory/sdk/sdk/world"] = "sdk/world",
    ["yoursubdirectory/sdk/spec/class"] = "spec/class",
    ["yoursubdirectory/sdk/spec/vector3"] = "spec/vector3",
}

for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

--
-- SDK
--

-- We load SDK just to use the "Test" module globals. Within tests themselves we will load it
-- separately and use a different path (yoursubdirectory/sdk) to avoid conflicting with an existing
-- one.
--
-- By default, Busted unit testing framework isolates tests, so we don't need to unload packages
-- manually after initializing them. However, if the package has been loaded outside tests we have
-- to make sure that we either use a different path when loading an SDK or unload it first before
-- requiring the same package.
require("sdk/sdk").SetIsSilent(true).Load({
    modname = "dst-mod-sdk",
    AddPrefabPostInit = function() end
}, "", {
    "Dump",
    "Test",
})
