require("busted.runner")()

describe("#sdk SDK.MiniMap", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local MiniMap

    setup(function()
        match = require("luassert.match")
    end)

    teardown(function()
        -- globals
        _G.RESOLUTION_X = nil
        _G.RESOLUTION_Y = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.RESOLUTION_X = 1280
        _G.RESOLUTION_Y = 720

        _G.TheSim = mock({
            GetScreenSize = ReturnValuesFn(2560, 1440),
        })

        _G.TheWorld = mock({
            minimap = {
                MiniMap = {
                    shown = false,
                    ContinuouslyClearRevealedAreas = Empty,
                    EnableFogOfWar = Empty,
                    GetZoom = ReturnValueFn(2),
                    WorldPosToMapPos = ReturnValuesFn(-193.48, 346.21, -200),
                },
            },
        })

        -- initialization
        SDK = require("yoursubdirectory/sdk/sdk/sdk")
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("MiniMap")
        MiniMap = require("yoursubdirectory/sdk/sdk/minimap")
    end)

    local function TestDebugString(fn, ...)
        _G.TestDebugString(fn, "[minimap]", ...)
    end

    local function TestReturnMiniMapMethod(fn, name, ...)
        local args = { ... }

        before_each(function()
            _G.TheWorld.minimap.MiniMap[name] = spy.new(ReturnValueFn(2))
        end)

        it("should call TheWorld.minimap.MiniMap:" .. name .. "()", function()
            assert.spy(_G.TheWorld.minimap.MiniMap[name]).was_not_called()
            fn()
            assert.spy(_G.TheWorld.minimap.MiniMap[name]).was_called(1)
            assert.spy(_G.TheWorld.minimap.MiniMap[name]).was_called_with(
                match.is_ref(_G.TheWorld.minimap.MiniMap),
                unpack(args)
            )
        end)

        it("should return TheWorld.minimap.MiniMap:" .. name .. "() value", function()
            assert.is_equal(_G.TheWorld.minimap.MiniMap[name](), fn())
        end)
    end

    local function TestSetModuleField(fn, name, from, to)
        it("should set " .. name .. " field", function()
            assert.is_equal(from, MiniMap[name])
            fn()
            assert.is_equal(to, MiniMap[name])
        end)
    end

    describe("general", function()
        describe("should have a", function()
            describe("getter", function()
                local getters = {
                    is_clearing = "IsClearing",
                    is_fog_of_war = "IsFogOfWar",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(MiniMap, field, getter)
                    end)
                end
            end)
        end)

        describe("GetZoom()", function()
            TestReturnMiniMapMethod(function()
                return MiniMap.GetZoom()
            end, "GetZoom")
        end)

        describe("IsShown()", function()
            before_each(function()
                _G.TheWorld.minimap.MiniMap.shown = true
            end)

            it("should return TheWorld.minimap.MiniMap.shown", function()
                assert.is_equal(_G.TheWorld.minimap.MiniMap.shown, MiniMap.IsShown())
            end)
        end)

        describe("ToggleClearing()", function()
            local fn = function()
                return MiniMap.ToggleClearing()
            end

            describe("when enabled", function()
                before_each(function()
                    MiniMap.is_clearing = true
                end)

                TestDebugString(fn, "Clearing:", "disabled")
                TestSetModuleField(fn, "is_clearing", true, false)
                TestReturnTrue(fn)
            end)

            describe("when not enabled", function()
                before_each(function()
                    MiniMap.is_clearing = false
                end)

                TestDebugString(fn, "Clearing:", "enabled")
                TestSetModuleField(fn, "is_clearing", false, true)
                TestReturnTrue(fn)
            end)
        end)

        describe("ToggleFogOfWar()", function()
            local fn = function()
                return MiniMap.ToggleFogOfWar()
            end

            describe("when enabled", function()
                before_each(function()
                    MiniMap.is_fog_of_war = true
                end)

                TestDebugString(fn, "Fog of war:", "disabled")
                TestSetModuleField(fn, "is_fog_of_war", true, false)
                TestReturnTrue(fn)
            end)

            describe("when not enabled", function()
                before_each(function()
                    MiniMap.is_fog_of_war = false
                end)

                TestDebugString(fn, "Fog of war:", "enabled")
                TestSetModuleField(fn, "is_fog_of_war", false, true)
                TestReturnTrue(fn)
            end)
        end)
    end)

    describe("position", function()
        describe("MapPosToWorldPos()", function()
            TestReturnMiniMapMethod(function()
                return MiniMap.MapPosToWorldPos(1, 0, 3)
            end, "MapPosToWorldPos", 1, 0, 3)
        end)

        describe("WorldPosToMapPos()", function()
            TestReturnMiniMapMethod(function()
                return MiniMap.WorldPosToMapPos(1, 0, 3)
            end, "WorldPosToMapPos", 1, 0, 3)
        end)

        describe("WorldPosToScreenPos()", function()
            before_each(function()
                _G.TheWorld.minimap.MiniMap.WorldPosToMapPos = ReturnValuesFn(-193.48, 346.21, -200)
            end)

            it("should return screen position", function()
                local x, y = MiniMap.WorldPosToScreenPos(0, 0, 0)
                assert.is_equal(-246374.4, x)
                assert.is_equal(249991.19999999998254, y)
            end)
        end)
    end)
end)
