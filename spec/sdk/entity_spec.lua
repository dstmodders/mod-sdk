require "busted.runner"()
require "class"

describe("#sdk SDK.Entity", function()
    -- setup
    local test_debug_string

    -- before_each initialization
    local Entity

    setup(function()
        -- globals
        _G.AllPlayers = mock({
            {
                GUID = 100000,
                entity = { IsVisible = ReturnValueFn(false) },
                GetDisplayName = ReturnValueFn("Willow"),
                GetDistanceSqToPoint = ReturnValueFn(27),
                HasTag = ReturnValueFn(false),
            },
            {
                GUID = 100001,
                entity = { IsVisible = ReturnValueFn(false) },
                GetDisplayName = ReturnValueFn("Wilson"),
                GetDistanceSqToPoint = ReturnValueFn(9),
                HasTag = function(_, tag)
                    return tag == "sleeping"
                end,
            },
            {
                GUID = 100002,
                entity = { IsVisible = ReturnValueFn(true) },
                GetDisplayName = ReturnValueFn("Wendy"),
                GetDistanceSqToPoint = ReturnValueFn(9),
                HasTag = ReturnValueFn(false),
            },
        })

        -- test data
        test_debug_string = [[117500 - wendy age 7.43]] .. "\n" ..
            [[GUID:117500 Name:  Tags: _sheltered trader _health inspectable freezable player idle _builder]] .. "\n" .. -- luacheck: only
            [[Prefab: wendy]] .. "\n" ..
            [[AnimState: bank: wilson build: wendy_rose anim: idle_loop anim/player_idles.zip:idle_loop Frame: 47.00/66 Facing: 3]] .. "\n" .. -- luacheck: only
            [[Transform: Pos=(-59.07,0.00,179.48) Scale=(1.00,1.00,1.00) Heading=-45.00]]
    end)

    teardown(function()
        _G.AllPlayers = nil
    end)

    before_each(function()
        Entity = require "sdk/entity"
    end)

    describe("general", function()
        describe("GetTags", function()
            local entity

            setup(function()
                entity = {
                    GetDebugString = ReturnValueFn(test_debug_string),
                }
            end)

            it("should return tags", function()
                assert.is_equal(8, #Entity.GetTags(entity))
            end)
        end)

        describe("FindClosestInvisiblePlayerInRange", function()
            local pt

            setup(function()
                pt = {
                    Get = ReturnValuesFn(1, 0, -1),
                }
            end)

            describe("when there is an invisible player in the range", function()
                it("should return the player and the squared range", function()
                    local closest, range_sq = Entity.GetInvisiblePlayerInRange(pt, 27)
                    assert.is_equal(100001, closest.GUID)
                    assert.is_equal(9, range_sq)
                    assert.is_false(closest.entity:IsVisible())
                end)
            end)

            describe("when there is no invisible player in the range", function()
                it("should return nil values", function()
                    local closest, range_sq = Entity.GetInvisiblePlayerInRange(pt, 3)
                    assert.is_nil(closest)
                    assert.is_nil(range_sq)
                end)
            end)
        end)

        describe("GetTentSleeper", function()
            local entity

            before_each(function()
                entity = {
                    components = {
                        sleepingbag = {
                            sleeper = _G.AllPlayers[2],
                        },
                    },
                    GetDisplayName = spy.new(ReturnValueFn("Tent")),
                    HasTag = spy.new(function(_, tag)
                        return tag == "tent" or tag == "hassleeper"
                    end),
                    Transform = {
                        GetWorldPosition = ReturnValuesFn(1, 0, -1),
                    },
                }
            end)

            describe('when the "sleepingbag" component is available', function()
                before_each(function()
                    entity.components.sleepingbag.sleeper = _G.AllPlayers[2]
                end)

                describe("and some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            Entity.GetTentSleeper(entity)
                        end, entity, "components", "sleepingbag", "sleeper")
                    end)
                end)

                it("should return sleeper", function()
                    assert.is_equal(_G.AllPlayers[2], Entity.GetTentSleeper(entity))
                end)
            end)

            describe('when the "sleepingbag" component is not available', function()
                before_each(function()
                    entity.components.sleepingbag = nil
                end)

                describe('and the passed entity has no "tent" and "hassleeper" tags', function()
                    before_each(function()
                        entity.HasTag = spy.new(ReturnValueFn(false))
                    end)

                    it("should return nil", function()
                        assert.is_nil(Entity.GetTentSleeper(entity))
                    end)
                end)

                describe('and the passed entity has "tent" and "hassleeper" tags', function()
                    it("should return sleeper", function()
                        assert.is_equal(_G.AllPlayers[2], Entity.GetTentSleeper(entity))
                    end)
                end)
            end)
        end)
    end)

    describe("animation state", function()
        local entity

        setup(function()
            entity = {
                AnimState = {},
                GetDebugString = ReturnValueFn(test_debug_string),
            }
        end)

        describe("GetAnimStateBank", function()
            it("should return the entity animation state bank", function()
                assert.is_equal("wilson", Entity.GetAnimStateBank(entity))
            end)
        end)

        describe("GetAnimStateBuild", function()
            setup(function()
                entity.AnimState = {
                    GetBuild = ReturnValueFn("test"),
                }
            end)

            it("should return the entity animation state build", function()
                assert.is_equal("test", Entity.GetAnimStateBuild(entity))
            end)
        end)

        describe("GetAnimStateAnim", function()
            it("should return the entity animation state animation", function()
                assert.is_equal("idle_loop", Entity.GetAnimStateAnim(entity))
            end)
        end)
    end)

    describe("state graph", function()
        local entity

        setup(function()
            entity = {
                sg = 'sg="wilson", state="idle", time=1.57, tags = "idle,canrotate,"',
            }
        end)

        describe("GetStateGraphName", function()
            it("should return the state graph name", function()
                assert.is_equal("wilson", Entity.GetStateGraphName(entity))
            end)
        end)

        describe("GetStateGraphState", function()
            it("should return the state graph state", function()
                assert.is_equal("idle", Entity.GetStateGraphState(entity))
            end)
        end)
    end)
end)
