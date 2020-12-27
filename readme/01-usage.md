# Usage

## Step 1. Install

In order to start using this SDK you need to first add it in your mod directory.

A recommended way is to add a Git submodule into your repository:

```shell script
git submodule add https://github.com/victorpopkov/dst-mod-sdk \
  scripts/<your subdirectory>/sdk --name sdk
```

However, you can download the latest release from the [Releases][] page or clone
the repository as well in order to add it manually.

_**NB!** Keep in mind, that your mod SDK path must be unique in order to avoid
having conflicts with another mod which may be using this SDK as well. This rule
doesn't really apply only to SDK but in general. For example, you should always
put your code into a unique subdirectory within your mod scrips:_
`scripts/<your subdirectory>/`.

## Step 2. Load

The next step after successful installation is to load it. For this you'll need
to require it as any other Lua module and then load it by calling the
corresponding `SDK.Load()` function.

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"

SDK.Load(env, "<your subdirectory>/sdk")
```

A good place to load SDK is `modmain.lua`. You may also pass a third parameter
to `SDK.Load()` in order to load only the modules you really need. For example:

```lua
SDK.Load(env, "<your subdirectory>/sdk", {
    "Config",
    "Console",
    "Constant",
    "Debug",
    "DebugUpvalue",
    "Dump",
    "Entity",
    "Input",
    "Inventory",
    "ModMain",
    "PersistentData",
    "Player",
    "Thread",
    "World",
})
```

In some cases you can even remove the modules you don't really use in your
production version to decrease the amount of bundled code. However, since they
are not really isolated from one another you should always verify if your mod
works as expected after removing them.

## Step 3. Use

That's it! You may now use SDK by requiring it in any of your mod files:

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"

dumptable(SDK.Entity.GetTags(ThePlayer))
```

To see a real world examples of using this SDK, check out the following mods:

- [Auto Join][]
- [Dev Tools][]
- [Keep Following][]

[auto join]: https://github.com/victorpopkov/dst-mod-auto-join
[dev tools]: https://github.com/victorpopkov/dst-mod-dev-tools
[keep following]: https://github.com/victorpopkov/dst-mod-keep-following
[releases]: https://github.com/victorpopkov/dst-mod-sdk/releases
