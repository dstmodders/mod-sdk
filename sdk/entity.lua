----
-- Handles entity functionality.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)
--
-- @module SDK.Entity
-- @see SDK
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Entity = {}

local SDK

--- General
-- @section general

--- Gets an invisible player around a certain point.
-- @tparam Vector3 pt Point, to look around from
-- @tparam number range Range
-- @treturn EntityScript Closest player
-- @treturn number Range squared
function Entity.GetInvisiblePlayerInRange(pt, range)
    local player, dist_sq
    local range_sq = range * range
    for _, v in ipairs(AllPlayers) do
        if not v.entity:IsVisible() then
            dist_sq = v:GetDistanceSqToPoint(pt:Get())
            if dist_sq < range_sq then
                range_sq = dist_sq
                player = v
            end
        end
    end
    return player, player ~= nil and range_sq or nil
end

--- Gets a closest position between two entities.
-- @tparam EntityScript entity1
-- @tparam EntityScript entity2
-- @treturn number
function Entity.GetPositionNearEntities(entity1, entity2)
    local rad1 = SDK.Utils.Chain.Get(entity1, "Physics", "GetRadius", true)
    local rad2 = SDK.Utils.Chain.Get(entity2, "Physics", "GetRadius", true)
    if type(rad1) == "number" and type(rad2) == "number" then
        return entity1:GetPositionAdjacentTo(entity2, rad1 + rad2)
    end
end

--- Gets an entity tags.
-- @tparam EntityScript entity
-- @tparam boolean is_all
-- @treturn table
function Entity.GetTags(entity, is_all)
    is_all = is_all == true

    if not entity or not entity.GetDebugString then
        return
    end

    -- TODO: Find a better way of getting the entity tag instead of using RegEx...
    local debug = entity:GetDebugString()
    local tags = string.match(debug, "Tags: (.-)\n")

    if tags and string.len(tags) > 0 then
        local result = {}

        if is_all then
            for tag in tags:gmatch("%S+") do
                table.insert(result, tag)
            end
        else
            for tag in tags:gmatch("%S+") do
                if not SDK.Utils.Table.HasValue(result, tag) then
                    table.insert(result, tag)
                end
            end
        end

        if #result > 0 then
            return SDK.Utils.Table.SortAlphabetically(result)
        end
    end
end

--- Gets a tent sleeper within a certain range.
--
-- When `sleepingbag` component is available, the `range` parameter is ignored. Otherwise,
-- `Entity.GetInvisiblePlayerInRange` will be used to find the nearest player around a Tent within
-- that range.
--
-- @tparam EntityScript tent A tent, Siesta Lean-to, etc.
-- @tparam[opt] number range Range
-- @treturn EntityScript A sleeper (a player)
function Entity.GetTentSleeper(tent, range)
    range = range ~= nil and range or 100

    local player
    local sleepingbag = SDK.Utils.Chain.Get(tent, "components", "sleepingbag")
    if sleepingbag then
        player = sleepingbag.sleeper
    end

    if not player and tent:HasTag("tent") and tent:HasTag("hassleeper") then
        player = Entity.GetInvisiblePlayerInRange(Vector3(tent.Transform:GetWorldPosition()), range)
    end

    if player and player:HasTag("sleeping") then
        return player
    end
end

--- Sets debug entity.
function Entity.SetDebugEntity(entity)
    if entity then
        SetDebugEntity(entity)
        SDK.Debug.String("New debug entity:", entity:GetDisplayName())
        return true
    end
    return false
end

--- Animation State
-- @section animation-state

--- Gets an entity animation state animation.
-- @see GetAnimStateBank
-- @see GetAnimStateBuild
-- @tparam EntityScript entity
-- @treturn string
function Entity.GetAnimStateAnim(entity)
    -- TODO: Find a better way of getting the entity AnimState anim instead of using RegEx...
    if entity.AnimState then
        local debug = entity:GetDebugString()
        local anim = string.match(debug, "AnimState:.*anim:%s+(%S+)")
        if anim and string.len(anim) > 0 then
            return anim
        end
    end
end

--- Gets an entity animation state bank.
-- @see GetAnimStateBuild
-- @see GetAnimStateAnim
-- @tparam EntityScript entity
-- @treturn string
function Entity.GetAnimStateBank(entity)
    -- @todo: Find a better way of getting the entity AnimState bank instead of using RegEx...
    if entity.AnimState then
        local debug = entity:GetDebugString()
        local bank = string.match(debug, "AnimState:.*bank:%s+(%S+)")
        if bank and string.len(bank) > 0 then
            return bank
        end
    end
end

--- Gets an entity animation state build.
-- @see GetAnimStateBank
-- @see GetAnimStateAnim
-- @tparam EntityScript entity
-- @treturn string
function Entity.GetAnimStateBuild(entity)
    if entity.AnimState then
        return entity.AnimState:GetBuild()
    end
end

--- State Graph
-- @section state-graph

--- Gets an entity state graph name.
-- @see GetStateGraphState
-- @tparam EntityScript entity
-- @treturn string
function Entity.GetStateGraphName(entity)
    -- TODO: Find a better way of getting the entity StateGraph name instead of using RegEx...
    if entity.sg then
        local debug = tostring(entity.sg)
        local name = string.match(debug, 'sg="(%S+)",')
        if name and string.len(name) > 0 then
            return name
        end
    end
end

--- Gets an entity state graph state.
-- @see GetStateGraphName
-- @tparam EntityScript entity
-- @treturn string
function Entity.GetStateGraphState(entity)
    -- TODO: Find a better way of getting the entity StateGraph state instead of using RegEx...
    if entity.sg then
        local debug = tostring(entity.sg)
        local state = string.match(debug, 'state="(%S+)",')
        if state and string.len(state) > 0 then
            return state
        end
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Entity
function Entity._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Entity, "Entity")
end

return Entity
