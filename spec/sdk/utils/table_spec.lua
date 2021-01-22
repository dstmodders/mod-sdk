require "busted.runner"()

describe("#sdk SDK.Utils.Table", function()
    -- before_each initialization
    local Table

    before_each(function()
        Table = require "sdk/utils/table"
    end)

    describe("Compare()", function()
        describe("when both tables have the same reference", function()
            TestReturnTrue(function()
                local t = {}
                return Table.Compare(t, t)
            end)
        end)

        describe("when both tables with nested ones are the same", function()
            TestReturnTrue(function()
                local a = { first = {}, second = { third = {} } }
                local b = { first = {}, second = { third = {} } }
                return Table.Compare(a, b)
            end)
        end)

        describe("when one of the tables is nil", function()
            it("should return false", function()
                local t = {}
                assert.is_false(Table.Compare(nil, t))
                assert.is_false(Table.Compare(t, nil))
            end)
        end)

        describe("when one of the tables is not a table type", function()
            it("should return false", function()
                local t = {}
                assert.is_false(Table.Compare("table", t))
                assert.is_false(Table.Compare(t, "table"))
            end)
        end)

        describe("when both tables with nested ones are not the same", function()
            TestReturnFalse(function()
                local a = { first = {}, second = { third = {} } }
                local b = { first = {}, second = { third = { "fourth" } } }
                return Table.Compare(a, b)
            end)
        end)
    end)

    describe("Count()", function()
        describe("when the passed parameter is not a table", function()
            TestReturnFalse(function()
                return Table.Count("test")
            end)
        end)

        describe("when the table with default indexes", function()
            it("should return the number of elements", function()
                local t = { one = 1, two = 2, three = 3, four = 4, five = 5 }
                assert.is_equal(5, Table.Count(t))
            end)
        end)

        describe("when the table with custom indexes", function()
            it("should return the number of elements", function()
                local t = { 1, 2, 3, 4, 5 }
                assert.is_equal(5, Table.Count(t))
            end)
        end)
    end)

    describe("HasValue()", function()
        describe("when the passed parameter is not a table", function()
            TestReturnFalse(function()
                return Table.HasValue("test")
            end)
        end)

        describe("when the table with default indexes", function()
            describe("and the element is in the table", function()
                TestReturnTrue(function()
                    local t = { one = 1, two = 2, three = 3, four = 4, five = 5 }
                    return Table.HasValue(t, 3)
                end)
            end)

            describe("and the element is not in the table", function()
                TestReturnFalse(function()
                    local t = { one = 1, two = 2, three = 3, four = 4, five = 5 }
                    return Table.HasValue(t, 6)
                end)
            end)
        end)

        describe("when the table with custom indexes", function()
            describe("and the element is in the table", function()
                TestReturnTrue(function()
                    local t = { 1, 2, 3, 4, 5 }
                    return Table.HasValue(t, 3)
                end)
            end)

            describe("and the element is not in the table", function()
                TestReturnFalse(function()
                    local t = { one = 1, two = 2, three = 3, four = 4, five = 5 }
                    return Table.HasValue(t, 6)
                end)
            end)
        end)
    end)

    describe("KeyByValue()", function()
        describe("when the passed parameter is not a table", function()
            TestReturnFalse(function()
                return Table.KeyByValue("test")
            end)
        end)

        describe("when the valid table and value passed", function()
            it("should return the key", function()
                local t = { one = 1, two = 2, three = 3, four = 4, five = 5 }
                assert.is_equal("two", Table.KeyByValue(t, 2))
            end)
        end)
    end)

    describe("Merge()", function()
        it("should return two combined simple tables", function()
            local a = { a = "a", b = "b", c = "c" }
            local b = { d = "d", e = "e", a = "f" }
            assert.is_same(
                { a = "f", b = "b", c = "c", d = "d", e = "e" },
                Table.Merge(a, b)
            )
        end)

        it("should return two combined simple ipaired tables", function()
            local a = { "a", "b", "c" }
            local b = { "d", "e", "f" }
            assert.is_same({ "a", "b", "c", "d", "e", "f" }, Table.Merge(a, b))
        end)
    end)

    describe("NextValue()", function()
        describe("when there is a next value", function()
            it("should return the next value", function()
                local t = { "a", "b", "c" }
                assert.is_equal("c", Table.NextValue(t, "b"))
            end)
        end)

        describe("when there is no next value", function()
            it("should return the first value", function()
                local t = { "a", "b", "c" }
                assert.is_equal("a", Table.NextValue(t, "c"))
            end)
        end)
    end)

    describe("SortAlphabetically()", function()
        describe("when the passed parameter is not a table", function()
            TestReturnFalse(function()
                return Table.SortAlphabetically("test")
            end)
        end)

        describe("when both tables with nested ones are the same", function()
            it("should return true", function()
                local test = { "one", "two", "three", "four", "five" }
                local expected = { "five", "four", "one", "three", "two" }
                local result = Table.SortAlphabetically(test)

                assert.is_equal(#expected, #result)
                for k, v in pairs(result) do
                    assert.is_equal(expected[k], v)
                end
            end)
        end)
    end)
end)
