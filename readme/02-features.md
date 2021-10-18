# Features

_**NB!** Not all features are covered yet._

The whole SDK comprises modules and submodules with different functionality:

- [SDK.Debug](#sdkdebug)
- [SDK.DebugUpvalue](#sdkdebugupvalue)
- [SDK.Entity](#sdkentity)
- [SDK.MiniMap](#sdkminimap)
- [SDK.PersistentData](#sdkpersistentdata)
- [SDK.Player](#sdkplayer)
- [SDK.Remote](#sdkremote)
- [SDK.World](#sdkworld)

## SDK.Debug

Module `SDK.Debug` helps with mod debugging.

As it's a common practice to put different messages throughout your code to see
what exactly your function is doing through the console. This enables more
transparency over the business logic and simplifies tracking the unexpected
behaviour.

```lua
SDK.Debug.Enable()
SDK.Debug.String("Hello", "World!") -- prints: [sdk] [your-mod] Hello World!

SDK.Debug.Disable()
SDK.Debug.String("Hello", "World!") -- prints nothing
```

Even though it's really easy to make a similar solution, you can still find mods
which just use `print` for this purpose and pollute the logs giving no option to
disable this behaviour.

### Example

```lua
local function GetComponent(name)
    local component = ThePlayer.components[name]
    if component then
        SDK.Debug.String("Component", name, "is available")
        return component
    end
    SDK.Debug.Error("Component", name, "is not available")
end

SDK.Debug.Enable()

GetComponent("health")
-- prints: [sdk] [your-mod] Component health is available

GetComponent("foobar")
-- prints: [sdk] [your-mod] [error] Component foobar is not available
```

## SDK.DebugUpvalue

_**NB!** Should be used with caution and only as a last resort._

Module `SDK.DebugUpvalue` allows accessing some in-game local variables using
the debug module.

```lua
local fn = TheWorld.net.components.weather.GetDebugString
local _moisturefloor = SDK.DebugUpvalue.GetUpvalue(fn, "_moisturefloor")
print(_moisturefloor:value()) -- prints a moisture floor value
```

Inspired by [UpvalueHacker][] created by Rafael Lizarralde ([@rezecib][]).

## SDK.MiniMap

Not documented yet...

## SDK.PersistentData

Module `SDK.PersistentData` handles storing any data for later access.

It works in 2 modes:

- **DEFAULT** (default): data is stored in a non-server specific way, meaning
  that it can be accessed outside of gameplay and/or no matter in which server
  you are. The data doesn't become stale and is stored permanently until it's
  cleared manually.

- **SERVER**: data is stored in a server specific way, meaning that it can only
  be accessed during gameplay and only on a certain server. When the data has
  not been accessed or stored for a certain amount of time (by default, 30 days)
  it's removed during the next load.

```lua
-- optional, the data is loaded automatically when SDK is loaded
SDK.PersistentData.Load()

-- general data (can be accessed in every server or outside of gameplay)
SDK.PersistentData.SetMode(SDK.PersistentData.DEFAULT)
SDK.PersistentData.Set("foo", "bar")
SDK.PersistentData.Get("foo") -- returns: "bar"

-- server data (can be accessed only on a certain server during gameplay)
SDK.PersistentData.SetMode(SDK.PersistentData.SERVER)
SDK.PersistentData.Set("foo", "bar")
SDK.PersistentData.Get("foo") -- returns: "bar"
```

## SDK.Player

_**NB!** Only available when_ `ThePlayer` _global is available._

_**NB!** Requires_ `SDK.Remote.Player` _to be loaded to work on dedicated
servers with administrator rights. On master instances, it tries to set things
locally by calling the corresponding component function. On non-master instances
(dedicated servers) it calls the corresponding_ `SDK.Remote.Player` _function
for sending a request to change it._

Module `SDK.Player` handles player functionality and consists of 5 submodules:

- [SDK.Player.Attribute](#sdkplayerattribute)
- [SDK.Player.Craft](#sdkplayercraft)
- [SDK.Player.Inventory](#sdkplayerinventory)
- [SDK.Player.MiniMap](#sdkplayerminimap)
- [SDK.Player.Vision](#sdkplayervision)

### SDK.Player.Attribute

Module `SDK.Player.Attribute` handles getting or setting different player
attributes.

```lua
if SDK.Player.Attribute.GetTemperature(ThePlayer) <= 0 then
    SDK.Player.Attribute.SetTemperature(36, ThePlayer)
end
```

#### Example

```lua
local function SetFullAttributes(player)
    SDK.Player.Attribute.SetHealthLimitPercent(100, player)
    SDK.Player.Attribute.SetHealthPercent(100, player)
    SDK.Player.Attribute.SetHungerPercent(100, player)
    SDK.Player.Attribute.SetSanityPercent(100, player)
    SDK.Player.Attribute.SetMoisturePercent(0, player)
    SDK.Player.Attribute.SetTemperature(36, player)
end

print(SDK.Player.Attribute.GetHealthPercent(ThePlayer)) -- prints: 50
SetFullAttributes(ThePlayer)
print(SDK.Player.Attribute.GetHealthPercent(ThePlayer)) -- prints: 100
```

### SDK.Player.Craft

Module `SDK.Player.Craft` handles player crafting.

```lua
if not SDK.Player.Craft.HasFreeCrafting(ThePlayer) then
    SDK.Player.Craft.ToggleFreeCrafting(ThePlayer)
end
```

### SDK.Player.Inventory

Not documented yet...

### SDK.Player.MiniMap

Not documented yet...

### SDK.Player.Vision

Not documented yet...

## SDK.Player

Not documented yet...

## SDK.Remote

Module `SDK.Remote` is responsible for sending different requests to the server.

It consists of 2 submodules:

- [SDK.Remote.Player](#sdkremoteplayer)
- [SDK.Remote.World](#sdkremoteworld)

Not documented yet...

## SDK.World

Not documented yet...

[@rezecib]: https://github.com/rezecib
[upvaluehacker]: https://github.com/rezecib/Rezecib-s-Rebalance/blob/master/scripts/tools/upvaluehacker.lua
