require "busted.runner"()

describe("#sdk SDK.Remote.World", function()
    -- before_each initialization
    local SDK
    local World

    teardown(function()
        -- globals
        _G.TheNet = nil
        _G.ThePlayer = nil
        _G.TheSim = nil
        _G.TheWorld = nil
        _G.TUNING = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.ThePlayer = mock({
            GUID = 1,
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 0, 3
            end,
        })

        _G.TheWorld = mock({
            HasTag = ReturnValueFn(false),
        })

        _G.TUNING = {
            MIN_ENTITY_TEMP = -20,
            MAX_ENTITY_TEMP = 90,
        }

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Remote")
        World = SDK.Remote.World

        SetTestModule(World)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function TestRemoteValid(name, debug, data, ...)
        local send = type(data) == "table" and data or {}
        if type(data) == "string" then
            send.data = data
        end

        send.x = send.x or 1
        send.z = send.y or 3

        _G.TestRemoteValid(name, {
            debug = {
                name = "world",
                args = debug,
            },
            send = send,
        }, ...)
    end

    describe("general", function()
        describe("PushEvent()", function()
            local fn_name = "PushEvent"

            TestArgString(fn_name, {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { true },
                valid = { "foo" },
            }, "event")

            TestRemoteInvalid(fn_name)
            TestRemoteInvalid(fn_name, nil, true)

            TestRemoteValid(
                fn_name,
                nil,
                'TheWorld:PushEvent("ms_advanceseason")',
                "ms_advanceseason"
            )

            TestRemoteValid(
                fn_name,
                nil,
                'TheWorld:PushEvent("ms_forceprecipitation", true)',
                "ms_forceprecipitation",
                true
            )

            TestRemoteValid(
                fn_name,
                nil,
                'TheWorld:PushEvent("ms_forceprecipitation", false)',
                "ms_forceprecipitation",
                false
            )

            TestRemoteValid(
                fn_name,
                nil,
                'TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 20 })',
                "ms_setseasonlength",
                { season = "autumn", length = 20 }
            )
        end)

        describe("Rollback()", function()
            local fn_name = "Rollback"

            TestArgUnsignedInteger(fn_name, {
                empty = {},
                invalid = { -1 },
                valid = { 1 },
            }, "days")

            TestArgUnsignedInteger(fn_name, {
                invalid = { 0.5 },
            }, "days")

            TestRemoteInvalid(fn_name, nil, -1)
            TestRemoteInvalid(fn_name, nil, 0.5)

            TestRemoteValid(
                fn_name,
                { "Rollback:", "0 days" },
                "TheNet:SendWorldRollbackRequestToServer(0)"
            )

            TestRemoteValid(
                fn_name,
                { "Rollback:", "1 day" },
                "TheNet:SendWorldRollbackRequestToServer(1)",
                1
            )

            TestRemoteValid(
                fn_name,
                { "Rollback:", "3 days" },
                "TheNet:SendWorldRollbackRequestToServer(3)",
                3
            )
        end)
    end)

    describe("season", function()
        describe("AdvanceSeason()", function()
            local fn_name = "AdvanceSeason"

            TestArgUnsignedInteger(fn_name, {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { -10 },
                valid = { 10 }
            }, "days")

            TestRemoteInvalid(fn_name, nil, -10)

            TestRemoteValid(
                fn_name,
                { "Advance season:", "10 days" },
                {
                    calls = 10,
                    data = 'TheWorld:PushEvent("ms_advanceseason")',
                },
                10
            )
        end)

        describe("RetreatSeason()", function()
            local fn_name = "RetreatSeason"

            TestArgUnsignedInteger(fn_name, {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { -10 },
                valid = { 10 }
            }, "days")

            TestRemoteInvalid(fn_name, nil, -10)

            TestRemoteValid(
                fn_name,
                { "Retreat season:", "10 days" },
                {
                    calls = 10,
                    data = 'TheWorld:PushEvent("ms_retreatseason")',
                },
                10
            )
        end)

        describe("SetSeason()", function()
            local fn_name = "SetSeason"

            TestArgSeason(fn_name, {
                empty = {
                    args = {},
                    calls = 1,
                },
                invalid = { "foo" },
                valid = { "autumn" },
            })

            TestRemoteInvalid(fn_name, nil, "foo")

            TestRemoteValid(
                fn_name,
                { "Season:", "autumn" },
                'TheWorld:PushEvent("ms_setseason", "autumn")',
                "autumn"
            )
        end)

        describe("SetSeasonLength()", function()
            local fn_name = "SetSeasonLength"

            TestArgSeason(fn_name, {
                empty = {
                    args = { nil, 10 },
                    calls = 1,
                },
                invalid = { "foo", 10 },
                valid = { "autumn", 10 },
            })

            TestArgUnsignedInteger(fn_name, {
                empty = {
                    args = { "autumn" },
                    calls = 1,
                },
                invalid = { "autumn", -10 },
                valid = { "autumn", 10 },
            }, "length")

            TestRemoteInvalid(fn_name, nil, "foo", 10)
            TestRemoteInvalid(fn_name, nil, "autumn", -10)

            TestRemoteValid(
                fn_name,
                { "Season length:", "autumn", "(10 days)" },
                'TheWorld:PushEvent("ms_setseasonlength", { season = "autumn", length = 10 })',
                "autumn",
                10
            )
        end)
    end)

    describe("weather", function()
        describe("ForcePrecipitation()", function()
            local fn_name = "ForcePrecipitation"

            TestRemoteValid(
                fn_name,
                { "Force precipitation:", "true" },
                'TheWorld:PushEvent("ms_forceprecipitation", true)'
            )

            TestRemoteValid(
                fn_name,
                { "Force precipitation:", "true" },
                'TheWorld:PushEvent("ms_forceprecipitation", true)',
                true
            )

            TestRemoteValid(
                fn_name,
                { "Force precipitation:", "false" },
                'TheWorld:PushEvent("ms_forceprecipitation", false)',
                false
            )
        end)

        describe("SendLightningStrike()", function()
            local pt
            local fn_name = "SendLightningStrike"

            setup(function()
                pt = Vector3(1, 0, 3)
            end)

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestRemoteInvalid(fn_name, {
                    explanation = "must be in a forest",
                    message = "Invalid world type",
                }, pt)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestArgPoint(fn_name, {
                    empty = {
                        args = {},
                        calls = 1,
                    },
                    invalid = { "foo" },
                    valid = { pt },
                })

                TestRemoteInvalid(fn_name, nil, "foo")

                TestRemoteValid(
                    fn_name,
                    { "Send lighting strike:", "(1.00, 0.00, 3.00)" },
                    'TheWorld:PushEvent("ms_sendlightningstrike", Vector3(1.00, 0.00, 3.00))',
                    pt
                )
            end)
        end)

        describe("SendMiniEarthquake()", function()
            local fn_name = "SendMiniEarthquake"

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "forest"
                    end)
                end)

                TestRemoteInvalid(fn_name, {
                    explanation = "must be in a cave",
                    message = "Invalid world type",
                })
            end)

            describe("when in a cave world", function()
                before_each(function()
                    _G.TheWorld.HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)
                end)

                TestRemoteInvalid(fn_name, nil, "foo", 20, 2.5, _G.ThePlayer)
                TestRemoteInvalid(fn_name, nil, 20, -10, 2.5, _G.ThePlayer)
                TestRemoteInvalid(fn_name, nil, 20, 20, true, _G.ThePlayer)
                TestRemoteInvalid(fn_name, nil, 20, 20, 2.5, "foo")

                TestRemoteValid(
                    fn_name,
                    { "Send mini earthquake:", "Player" },
                    'TheWorld:PushEvent("ms_miniquake", { '
                        .. 'target = LookupPlayerInstByUserID("KU_foobar"), '
                        .. "num = 20, "
                        .. "rad = 20, "
                        .. "duration = 2.50 "
                        .. '})'
                )

                TestRemoteValid(
                    fn_name,
                    { "Send mini earthquake:", "Player" },
                    'TheWorld:PushEvent("ms_miniquake", { '
                        .. 'target = LookupPlayerInstByUserID("KU_foobar"), '
                        .. "num = 20, "
                        .. "rad = 20, "
                        .. "duration = 2.50 "
                        .. '})',
                    20,
                    20,
                    2.5,
                    _G.ThePlayer
                )
            end)
        end)

        describe("SetDeltaMoisture()", function()
            local fn_name = "SetDeltaMoisture"

            TestArgNumber(fn_name, {
                empty = {},
                invalid = { "foo" },
                valid = { 1 },
            }, "delta")

            TestRemoteInvalid(fn_name, nil, "foo")

            TestRemoteValid(
                fn_name,
                { "Delta moisture:", "0.00" },
                'TheWorld:PushEvent("ms_deltamoisture", 0)'
            )

            TestRemoteValid(
                fn_name,
                { "Delta moisture:", "1.00" },
                'TheWorld:PushEvent("ms_deltamoisture", 1)',
                1
            )
        end)

        describe("SetDeltaWetness()", function()
            local fn_name = "SetDeltaWetness"

            TestArgNumber(fn_name, {
                empty = {},
                invalid = { "foo" },
                valid = { 1 },
            }, "delta")

            TestRemoteInvalid(fn_name, nil, "foo")

            TestRemoteValid(
                fn_name,
                { "Delta wetness:", "0.00" },
                'TheWorld:PushEvent("ms_deltawetness", 0)'
            )

            TestRemoteValid(
                fn_name,
                { "Delta wetness:", "1.00" },
                'TheWorld:PushEvent("ms_deltawetness", 1)',
                1
            )
        end)

        describe("SetSnowLevel()", function()
            local fn_name = "SetSnowLevel"

            TestArgUnitInterval(fn_name, {
                empty = {},
                invalid = { 2 },
                valid = { 1 },
            }, "level")

            describe("when not in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(true)
                end)

                TestRemoteInvalid(fn_name, {
                    explanation = "must be in a forest",
                    message = "Invalid world type",
                }, 1)
            end)

            describe("when in a forest world", function()
                before_each(function()
                    _G.TheWorld.HasTag = ReturnValueFn(false)
                end)

                TestRemoteInvalid(fn_name, nil, 2)

                TestRemoteValid(
                    fn_name,
                    { "Snow level:", "0.00" },
                    'TheWorld:PushEvent("ms_setsnowlevel", 0)'
                )

                TestRemoteValid(fn_name,
                    { "Snow level:", "0.50" },
                    'TheWorld:PushEvent("ms_setsnowlevel", 0.50)',
                    0.5
                )

                TestRemoteValid(
                    fn_name,
                    { "Snow level:", "1.00" },
                    'TheWorld:PushEvent("ms_setsnowlevel", 1)',
                    1
                )
            end)
        end)
    end)
end)
