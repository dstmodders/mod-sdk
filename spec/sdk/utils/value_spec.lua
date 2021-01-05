require "busted.runner"()

describe("#sdk SDK.Utils.Value", function()
    -- before_each initialization
    local Value

    setup(function()
        _G.PREFABFILES = { "foo", "bar", "foobar" }
        _G.TUNING = {
            MIN_ENTITY_TEMP = -20,
            MAX_ENTITY_TEMP = 90,
        }
    end)

    teardown(function()
        _G.PREFABFILES = nil
        _G.TUNING = nil
    end)

    before_each(function()
        Value = require "sdk/utils/value"
    end)

    local function TestChecker(name, valid, invalid)
        describe(name .. "()", function()
            describe("when a valid value is passed", function()
                it("should return true", function()
                    for _, v in pairs(valid) do
                        assert.is_true(Value[name](v))
                    end
                end)
            end)

            describe("when an invalid value is passed", function()
                it("should return false", function()
                    for _, v in pairs(invalid) do
                        assert.is_false(Value[name](v))
                    end
                end)
            end)
        end)
    end

    describe("checkers", function()
        TestChecker("IsBoolean", { false, true }, { "string", 0, {} })
        TestChecker("IsEntity", { { GUID = 1, } }, { "string", 0, false, true, {} })

        TestChecker("IsEntityTemperature", {
            0,
            _G.TUNING.MAX_ENTITY_TEMP,
            _G.TUNING.MIN_ENTITY_TEMP,
        }, {
            100,
            _G.TUNING.MAX_ENTITY_TEMP + 1,
            _G.TUNING.MIN_ENTITY_TEMP - 1,
            false,
            true,
            {},
        })

        TestChecker("IsInteger", { 0, -1, 1 }, { "string", -0.5, 0.5, false, true, {} })
        TestChecker("IsNumber", { 0, -1, 1 }, { "string", false, true, {} })
        TestChecker("IsPercent", { 0, 50, 100 }, { "string", -1, 101, false, true, {} })

        TestChecker("IsPlayer", {
            {
                GUID = 1,
                userid = "KU_foobar",
                HasTag = function(_, tag)
                    return tag == "player"
                end,
            }
        }, { "string", 0, false, true, {} })

        TestChecker("IsPoint", {
            Vector3(1, 0, 3),
            { x = 1, y = 0, z = 3 },
        }, {
            "string",
            0,
            false,
            true,
            {},
        })

        TestChecker("IsPrefab", { "foo", "bar" }, { "string", 0, false, true, {} })

        TestChecker("IsSeason", {
            "autumn",
            "spring",
            "summer",
            "winter",
        }, {
            "string",
            0,
            false,
            true,
            {},
        })

        TestChecker("IsString", { "string" }, { 0, false, true, {} })
        TestChecker("IsUnitInterval", { 0, 0.5, 1 }, { -1, 2, false, true, {} })
        TestChecker("IsUnsigned", { 0, 0.5, 1 }, { -1, -0.5, false, true, {} })
    end)

    describe("converters", function()
        describe("ToClock()", function()
            describe("when a seconds value is passed", function()
                it("should return hours, minutes and seconds", function()
                    local h, m, s

                    h, m, s = Value.ToClock(30615)
                    assert.is_equal(8, h)
                    assert.is_equal(30, m)
                    assert.is_equal(15, s)

                    h, m, s = Value.ToClock(0)
                    assert.is_equal(0, h)
                    assert.is_equal(0, m)
                    assert.is_equal(0, s)
                end)
            end)

            describe("when a non-seconds value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToClock(true))
                end)
            end)
        end)

        describe("ToClockString()", function()
            describe("when a seconds value is passed", function()
                describe("and has_no_hours is not passed", function()
                    it("should return a clock string", function()
                        assert.is_equal("08:30:15", Value.ToClockString(30615))
                        assert.is_equal("00:00:00", Value.ToClockString(0))
                    end)
                end)

                describe("and has_no_hours is passed", function()
                    it("should return a clock string", function()
                        assert.is_equal("30:15", Value.ToClockString(30615, true))
                        assert.is_equal("00:00", Value.ToClockString(0, true))
                    end)
                end)
            end)

            describe("when a non-seconds value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToClockString(true))
                end)
            end)
        end)

        describe("ToDaysString()", function()
            describe("when a days value is passed", function()
                it("should return a float string", function()
                    assert.is_equal("-1 day", Value.ToDaysString(-1))
                    assert.is_equal("0 days", Value.ToDaysString(0))
                    assert.is_equal("0.5 day", Value.ToDaysString(0.5))
                    assert.is_equal("1 day", Value.ToDaysString(1))
                    assert.is_equal("100 days", Value.ToDaysString(100))
                end)
            end)

            describe("when a non-days value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToDaysString(true))
                end)
            end)
        end)

        describe("ToFloatString()", function()
            describe("when a number value is passed", function()
                it("should return a float string", function()
                    assert.is_equal("-1.00", Value.ToFloatString(-1))
                    assert.is_equal("0.00", Value.ToFloatString(0))
                    assert.is_equal("0.50", Value.ToFloatString(0.5))
                    assert.is_equal("1.00", Value.ToFloatString(1))
                end)
            end)

            describe("when a non-number value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToFloatString(true))
                end)
            end)
        end)

        describe("ToPercentString()", function()
            describe("when a number value is passed", function()
                it("should return a percent string", function()
                    assert.is_equal("-1.00%", Value.ToPercentString(-1))
                    assert.is_equal("0.00%", Value.ToPercentString(0))
                    assert.is_equal("0.50%", Value.ToPercentString(0.5))
                    assert.is_equal("1.00%", Value.ToPercentString(1))
                    assert.is_equal("100.00%", Value.ToPercentString(100))
                end)
            end)

            describe("when a non-number value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToPercentString(true))
                end)
            end)
        end)

        describe("ToDegreeString()", function()
            describe("when a number value is passed", function()
                it("should return a degrees string", function()
                    assert.is_equal("-1.00°", Value.ToDegreeString(-1))
                    assert.is_equal("0.00°", Value.ToDegreeString(0))
                    assert.is_equal("0.50°", Value.ToDegreeString(0.5))
                    assert.is_equal("1.00°", Value.ToDegreeString(1))
                    assert.is_equal("100.00°", Value.ToDegreeString(100))
                end)
            end)

            describe("when a non-number value is passed", function()
                it("should return nil", function()
                    assert.is_nil(Value.ToDegreeString(true))
                end)
            end)
        end)
    end)
end)
