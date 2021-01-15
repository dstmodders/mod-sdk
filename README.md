# dst-mod-sdk

[![GitHub Workflow CI Status][]](https://github.com/victorpopkov/dst-mod-sdk/actions?query=workflow%3ACI)
[![GitHub Workflow Documentation Status][]](https://github.com/victorpopkov/dst-mod-sdk/actions?query=workflow%3ADocumentation)
[![Codecov][]](https://codecov.io/gh/victorpopkov/dst-mod-sdk)

## Overview

SDK for making [Don't Starve Together][] mods.

- [Why?](#why)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [Documentation](#documentation)
- [Roadmap](#roadmap)

## Why?

The story is always the same...

Since I've made a few mods for this game the amount of code that could be reused
has kept growing and the maintenance costs have started to increase. The feeling
that I keep writing more or less the same solutions over and over again has
started to pop into my head more frequently, so I've decided to make a separate
repository to store all the existing solutions and wrap it in a form of an SDK.

I don't really know what final form this project will end up with as I don't
really have an aim in covering everything except extending it based on my own
needs. However, even though I don't really think that this project will be
useful to anyone else, you can always open an issue or a pull request in order
to extend it. It's always appreciated!

### Pros

- **Blameability:** you can always blame this project instead of your own code
- **Modularity:** use only what you need
- **Reusability:** write less and stop "reinventing the wheel"
- **Stability:** no one seems insane enough to write tests for mods

### Cons

- **Bloatedness:** your solution can end up much smaller

## Quick Start

First, this project is still in active development, so I can't guarantee
anything at this stage. But if you are one of those who likes to live
dangerously and has decided to try it out, then it could be done in 3 steps:

**Step 1/3**. Clone it into your unique mod subdirectory:

```shell script
git submodule add https://github.com/victorpopkov/dst-mod-sdk scripts/<your subdirectory>/sdk --name sdk
```

**Step 2/3**. Require and load it is your `modmain.lua`:

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"

SDK.Load(env, "<your subdirectory>/sdk")
```

**Step 3/3**. Start using it directly in your `modmain.lua` or in any other file
by requiring it:

```lua
local SDK = require "<your subdirectory>/sdk/sdk/sdk"

dumptable(SDK.Entity.GetTags(ThePlayer))
```

To learn more, explore the [usage][].

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
- [Development][]

## Roadmap

You can always find and track the current state of the upcoming features/fixes
on the following [Trello][] board: https://trello.com/b/aWiJ6azY

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).

[auto join]: https://github.com/victorpopkov/dst-mod-auto-join
[codecov]: https://img.shields.io/codecov/c/github/victorpopkov/dst-mod-sdk.svg
[dev tools]: https://github.com/victorpopkov/dst-mod-dev-tools
[development]: readme/02-development.md
[documentation]: http://github.victorpopkov.com/dst-mod-sdk/
[don't starve together]: https://www.klei.com/games/dont-starve-together
[github workflow ci status]: https://img.shields.io/github/workflow/status/victorpopkov/dst-mod-sdk/CI?label=CI
[github workflow documentation status]: https://img.shields.io/github/workflow/status/victorpopkov/dst-mod-sdk/Documentation?label=Documentation
[keep following]: https://github.com/victorpopkov/dst-mod-keep-following
[ldoc]: https://stevedonovan.github.io/ldoc/
[trello]: https://trello.com/
[usage]: readme/01-usage.md
