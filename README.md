# dst-mod-sdk

[![CI](https://img.shields.io/github/workflow/status/dstmodders/dst-mod-sdk/CI?label=ci)](https://github.com/dstmodders/dst-mod-sdk/actions/workflows/ci.yml)
[![Deploy](https://img.shields.io/github/workflow/status/dstmodders/dst-mod-sdk/Deploy?label=deploy)](https://github.com/dstmodders/dst-mod-sdk/actions/workflows/deploy.yml)
[![Codecov](https://img.shields.io/codecov/c/github/dstmodders/dst-mod-sdk.svg)](https://codecov.io/gh/dstmodders/dst-mod-sdk)

## Overview

SDK for making [Don't Starve Together][] mods.

- [Why?](#why)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [Documentation](#documentation)

## Why?

The story is always the same...

As I was making a few mods for the game, the amount of code that could be reused
has kept growing. The maintenance cost has increased, and the feeling of writing
the same solutions has popped into my head more frequently. So, I've made a
separate repository to store all the existing solutions and wrap it in an SDK.

I don't know what final form this project ends up with. At this stage I have no
aim in covering everything and just planning to extend it based on my own needs.
However, even though I don't think that this project will be useful to anyone
else, you can open an issue or a pull request to extend it. I appreciate any
contributions!

### Pros

- **Blameability:** you can always blame this project instead of your own code
- **Modularity:** use only what you need
- **Reusability:** write less and stop "reinventing the wheel"
- **Stability:** no one seems insane enough to write tests for mods

### Cons

- **Bloatedness:** your solution can end up much smaller

## Quick Start

First, this project is still in active development, so I can't guarantee
anything at this stage. But if you are one of those who enjoys living on the
verge and has decided to try it out, then it could be done in 3 steps:

**Step 1/3**. Clone it into your unique mod subdirectory:

```shell script
git submodule add https://github.com/dstmodders/dst-mod-sdk \
  scripts/<your subdirectory>/sdk --name sdk
```

**Step 2/3**. Require and load it is your `modmain.lua`:

```lua
local SDK = require("<your subdirectory>/sdk/sdk/sdk").Load(env, "<your subdirectory>/sdk")
```

**Step 3/3**. Start using it directly in your `modmain.lua` or in any other file
by requiring it:

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"
dumptable(SDK.Entity.GetTags(ThePlayer))
```

To learn more, explore the [usage][].

## Features

_**NB!** Not all features are covered yet._

The whole SDK comprises modules and submodules with different functionality:

- [Debug Upvalue](readme/02-features.md#debug-upvalue)
- [Debug](readme/02-features.md#debug)
- [Persistent Data](readme/02-features.md#persistent-data)
- [Player](readme/02-features.md#player)

## Examples

_**NB!** The mentioned mods are currently in the process of migration to SDK.
Check out their `sdk` branches first._

The best way to see if this project is worth it, check out my following mods
which use this SDK:

- [Auto Join][]
- [Dev Tools][]
- [Keep Following][]

Or you could explore the [documentation][] as some functions may have usage
examples.

## Documentation

The [LDoc][] documentation generator has been used for generating documentation,
and the most recent version can be found here:
http://github.victorpopkov.com/dst-mod-sdk/

- [Usage][]
- [Features][]

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).

[auto join]: https://github.com/victorpopkov/dst-mod-auto-join
[dev tools]: https://github.com/victorpopkov/dst-mod-dev-tools
[documentation]: http://github.victorpopkov.com/dst-mod-sdk/
[don't starve together]: https://www.klei.com/games/dont-starve-together
[features]: readme/02-features.md
[keep following]: https://github.com/victorpopkov/dst-mod-keep-following
[ldoc]: https://stevedonovan.github.io/ldoc/
[trello]: https://trello.com/
[usage]: readme/01-usage.md
