# Usage

## Step 1. Install

To use this SDK, you need to first add it in your mod directory.

A recommended way is to add a Git submodule into your repository:

```shell script
git submodule add https://github.com/dstmodders/dst-mod-sdk \
  scripts/<your subdirectory>/sdk --name sdk
```

However, you can download the latest release from the [Releases][] page,
or clone the repository to add it manually.

_**NB!** Keep in mind that your mod SDK path must be unique to avoid having
conflicts with another mod which may use the same SDK. It's a good practice to
eliminate potential override conflicts. For example, always put your code into a
unique subdirectory within your mod scrips:_ `scripts/<your subdirectory>/`

## Step 2. Load

The next step after a successful installation is to load it. For this you must
require it as any other Lua module and load it by calling the corresponding
`SDK.Load()` function.

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"
SDK.Load(env, "<your subdirectory>/sdk")
```

A good place to load SDK is `modmain.lua`. You may also pass a third parameter
to `SDK.Load()` to load only the modules you need. For example:

```lua
SDK.Load(env, "<your subdirectory>/sdk", {
    "Config",
    "Console",
    "Constant",
    "Debug",
    "DebugUpvalue",
    "Dump",
    "Entity",
    "FrontEnd",
    "Input",
    "Method",
    "ModMain",
    "PersistentData",
    Player = {
        "Attribute",
        "Craft",
        "Inventory",
    },
    Remote = {
        "Player",
        "World",
    },
    "RPC",
    "Test",
    "Thread",
    World = {
        "SaveData",
        "Season",
        "Weather",
    },
})
```

You can remove the unused modules from production version to decrease the amount
of bundled code. However, as some may use other modules as well, always verify
if your mod works as expected after removing them.

## Step 3. Use

That's it! Start using it directly in your `modmain.lua` or in any other file by
requiring it:

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"
dumptable(SDK.Entity.GetTags(ThePlayer))
```

To see a real world examples of using this SDK, check out the following mods:

- [Auto Join][]
- [Dev Tools][]
- [Keep Following][]

_**NB!** The mentioned mods are currently in the process of migration to SDK.
Check out their_ `sdk` _branches first._

[auto join]: https://github.com/victorpopkov/dst-mod-auto-join
[dev tools]: https://github.com/victorpopkov/dst-mod-dev-tools
[keep following]: https://github.com/victorpopkov/dst-mod-keep-following
[releases]: https://github.com/dstmodders/dst-mod-sdk/releases
