----
-- Handles world functionality.
--
-- _**NB!** Only available when_ `TheWorld` _global is available._
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.World
-- @see SDK
-- @see SDK.World.SaveData
-- @see SDK.World.Season
-- @see SDK.World.Weather
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local World = {
    nr_of_walrus_camps = 0,
}

local SDK
local Chain
local Value

--- Helpers
-- @section helpers

local function DebugErrorFn(fn_name, ...)
    SDK._DebugErrorFn(World, fn_name, ...)
end

local function DebugErrorInvalidArg(fn_name, arg_name, explanation)
    SDK._DebugErrorInvalidArg(World, fn_name, arg_name, explanation)
end

local function DebugString(...)
    SDK._DebugString("[world]", ...)
end

--- General
-- @section general

--- Gets a meta.
-- @tparam[opt] string name Meta name
-- @treturn[1] table Meta table, when no name passed
-- @treturn[2] string Meta value, when the name is passed
function World.GetMeta(name)
    local meta = TheWorld.meta
    if meta and name ~= nil and type(meta[name]) ~= nil then
        return meta[name]
    end
    return meta
end

--- Gets a number of Walrus Camps.
--
-- Returns a number of Walrus Camps guessed earlier by the `_GuessNrOfWalrusCamps`.
--
-- @see _GuessNrOfWalrusCamps
-- @treturn number
function World.GetNrOfWalrusCamps()
    return World.nr_of_walrus_camps
end

--- Gets a seed.
-- @treturn string
function World.GetSeed()
    return World.GetMeta("seed")
end

--- Gets a state.
-- @tparam[opt] string name State name
-- @treturn[1] table State table, when no name passed
-- @treturn[2] string State value, when the name is passed
function World.GetState(name)
    local state = TheWorld.state
    if state and name ~= nil and type(state[name]) ~= nil then
        return state[name]
    end
    return state
end

--- Checks if it's a cave world.
-- @treturn boolean
function World.IsCave()
    return TheWorld:HasTag("cave")
end

--- Checks if it's a master simulated world.
-- @treturn boolean
function World.IsMasterSim()
    return TheWorld.ismastersim
end

--- Checks if a certain point is passable.
-- @tparam Vector3 pt Point to check
-- @treturn boolean
function World.IsPointPassable(pt)
    return SDK.Utils.Chain.Validate(TheWorld, "Map", "IsPassableAtPoint")
            and SDK.Utils.Chain.Validate(pt, "Get")
            and TheWorld.Map:IsPassableAtPoint(pt:Get())
        or false
end

--- Rollbacks a world.
-- @tparam number days
-- @treturn boolean
function World.Rollback(days)
    days = days ~= nil and days or 0

    if not Value.IsUnsigned(days) or not Value.IsInteger(days) then
        DebugErrorInvalidArg("Rollback", "days", "must be an unsigned integer")
        return false
    end

    if World.IsMasterSim() then
        DebugString("Rollback:", Value.ToDaysString(days))
        TheNet:SendWorldRollbackRequestToServer(days)
        return true
    end

    return SDK.Remote.World.Rollback(days)
end

--- Phase
-- @section phase

--- Gets a day phase.
-- @tparam string phase Phase
-- @treturn number
function World.GetPhase()
    return World.IsCave() and World.GetState("cavephase") or World.GetState("phase")
end

--- Gets a next day phase.
--
-- Returns the value based on the following logic:
--
--   - day => dusk
--   - dusk => night
--   - night => day
--
-- @tparam string phase Current phase
-- @treturn string Next phase
function World.GetPhaseNext(phase)
    return SDK.Utils.Table.NextValue({ "day", "dusk", "night" }, phase)
end

--- Gets the time until a certain phase.
--
-- This is a convenience method returning:
--
--    TheWorld.net.components.clock:GetTimeUntilPhase(phase)
--
-- @tparam string phase
-- @treturn number
function World.GetTimeUntilPhase(phase)
    local clock = SDK.Utils.Chain.Get(TheWorld, "net", "components", "clock")
    return clock and clock:GetTimeUntilPhase(phase)
end

--- Internal
-- @section internal

--- Guesses the number of Walrus Camps.
--
-- To get the guessed value use `GetNrOfWalrusCamps`.
--
-- Uses the topology IDs data to predict how many Walrus Camps and is called automatically when the
-- world loads.
--
-- @see GetNrOfWalrusCamps
-- @treturn boolean
function World._GuessNrOfWalrusCamps()
    local ids = Chain.Get(TheWorld, "topology", "ids")
    if not ids then
        DebugErrorFn("_GuessNrOfWalrusCamps", "No world topology IDs found")
        return false
    end

    DebugString("Guessing the number of Walrus Camps...")
    World.nr_of_walrus_camps = 0
    for _, id in pairs(ids) do
        if
            string.match(id, "WalrusHut_Grassy")
            or string.match(id, "WalrusHut_Plains")
            or string.match(id, "WalrusHut_Rocky")
        then
            World.nr_of_walrus_camps = World.nr_of_walrus_camps + 1
        end
    end

    DebugString(
        "Found",
        tostring(World.nr_of_walrus_camps),
        (World.nr_of_walrus_camps == 0 or World.nr_of_walrus_camps ~= 1)
                and "Walrus Camps"
            or "Walrus Camp"
    )
    return true
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @tparam table submodules
-- @treturn SDK.World
function World._DoInit(sdk, submodules)
    SDK = sdk
    Chain = SDK.Utils.Chain
    Value = SDK.Utils.Value

    submodules = submodules ~= nil and submodules
        or {
            Season = "sdk/world/season",
            Weather = "sdk/world/weather",
        }

    SDK._SetModuleName(SDK, World, "World")
    SDK.LoadSubmodules(World, submodules)
    SDK.OnEnterCharacterSelect(World._GuessNrOfWalrusCamps)
    SDK.OnPlayerActivated(World._GuessNrOfWalrusCamps)

    return SDK._DoInitModule(SDK, World, "World", "TheWorld")
end

return World
