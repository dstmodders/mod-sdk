require "busted.runner"()

describe("#sdk SDK.Method", function()
    -- setup
    local Dest, Src

    -- before_each instances
    local src, dest

    -- before_each initialization
    local SDK
    local Method

    before_each(function()
        -- destination
        Dest = Class(function()
        end)

        dest = Dest()

        -- source
        Src = Class(function(self)
            self.bar = "foo"
            self.bool = true
            self.foo = "bar"
        end)

        function Src:ReturnMultiple(value)
            return value, self.foo
        end

        function Src:ReturnPassedValue(value) -- luacheck: only
            return value
        end

        function Src:ReturnSelf()
            return self
        end

        src = Src()

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Method")
        Method = require "yoursubdirectory/sdk/sdk/method"
    end)

    after_each(function()
        package.loaded["yoursubdirectory/sdk/sdk/sdk"] = nil
    end)

    local function TestReturnSelf(fn_name, ...)
        local args = { ... }
        it("should return self", function()
            AssertReturnSelf(Method, fn_name, unpack(args))
        end)
    end

    describe("helper", function()
        describe("AddMethodToAnotherClass()", function()
            it("should add methods from one class to another", function()
                assert.is_nil(dest.ReturnMultiple)
                assert.is_nil(dest.ReturnPassedValue)
                assert.is_nil(dest.ReturnSelf)

                Method._AddMethodToAnotherClass(src, dest, "ReturnMultiple", "ReturnMultiple")
                Method._AddMethodToAnotherClass(src, dest, "ReturnPassedValue", "ReturnPassedValue")
                Method._AddMethodToAnotherClass(src, dest, "ReturnSelf", "ReturnSelf")

                assert.is_not_nil(dest.ReturnMultiple)
                assert.is_not_nil(dest.ReturnPassedValue)
                assert.is_not_nil(dest.ReturnSelf)

                -- ReturnMultiple
                local value, foo

                value, foo = dest:ReturnMultiple("test")
                assert.is_equal("test", value)
                assert.is_equal(src.foo, foo)

                -- ReturnPassedValue
                value = dest:ReturnPassedValue("test")
                assert.is_equal("test", value)

                -- ReturnSelf
                assert.is_equal(src, dest:ReturnSelf())
            end)
        end)

        describe("RemoveMethod()", function()
            it("should remove method", function()
                assert.is_not_nil(src.ReturnMultiple)
                Method._RemoveMethod(src, "ReturnMultiple")
                assert.is_nil(src.ReturnMultiple)
            end)
        end)
    end)

    describe("general", function()
        describe("GetClass()", function()
            before_each(function()
                Method.SetClass(src)
            end)

            it("should return class", function()
                assert.is_equal(src, Method.GetClass())
            end)
        end)

        describe("SetClass()", function()
            before_each(function()
                Method.SetClass(nil)
            end)

            it("should set class", function()
                assert.is_nil(Method.GetClass())
                Method.SetClass(src)
                assert.is_equal(src, Method.GetClass())
            end)
        end)
    end)

    describe("add", function()
        describe("AddGetter()", function()
            it("should add a getter", function()
                assert.is_nil(src.GetFoo)
                Method.AddGetter("foo", "GetFoo", src)
                assert.is_not_nil(src.GetFoo)
                assert.is_equal("bar", src:GetFoo())

                src.foo = true
                assert.is_true(src:GetFoo())

                src.foo = false
                assert.is_false(src:GetFoo())
            end)

            TestReturnSelf("AddGetter", "foo", "GetFoo", src)
        end)

        describe("AddGetters()", function()
            it("should add getters", function()
                assert.is_nil(src.GetFoo)
                assert.is_nil(src.GetBar)
                Method.AddGetters({
                    foo = "GetFoo",
                    bar = "GetBar",
                }, src)
                assert.is_not_nil(src.GetFoo)
                assert.is_not_nil(src.GetBar)
                assert.is_equal("bar", src:GetFoo())
                assert.is_equal("foo", src:GetBar())
            end)

            TestReturnSelf("AddGetters", {
                foo = "GetFoo",
                bar = "GetBar",
            }, src)
        end)

        describe("AddSetter()", function()
            describe("when is_return_self is not passed", function()
                it("should add a setter", function()
                    assert.is_nil(src.SetFoo)
                    Method.AddSetter("foo", "SetFoo", nil, src)
                    assert.is_not_nil(src.SetFoo)
                    assert.is_equal("bar", src.foo)

                    src:SetFoo(true)
                    assert.is_true(src.foo)

                    src:SetFoo(false)
                    assert.is_false(src.foo)
                end)

                it("should return nil", function()
                    Method.AddSetter("foo", "SetFoo", nil, src)
                    assert.is_nil(src:SetFoo(true))
                end)

                TestReturnSelf("AddSetter", "foo", "SetFoo", nil, src)
            end)

            describe("when is_return_self is passed", function()
                it("should add a setter", function()
                    assert.is_nil(src.SetFoo)
                    Method.AddSetter("foo", "SetFoo", true, src)
                    assert.is_not_nil(src.SetFoo)
                    assert.is_equal("bar", src.foo)

                    src:SetFoo(true)
                    assert.is_true(src.foo)

                    src:SetFoo(false)
                    assert.is_false(src.foo)
                end)

                it("should return self", function()
                    Method.AddSetter("foo", "SetFoo", true, src)
                    assert.is_equal(src, src:SetFoo(true))
                end)

                TestReturnSelf("AddSetter", "foo", "SetFoo", true, src)
            end)
        end)

        describe("AddSetters()", function()
            describe("when is_return_self is not passed", function()
                it("should add setters", function()
                    assert.is_nil(src.SetFoo)
                    assert.is_nil(src.SetBar)
                    Method.AddSetters({
                        foo = "SetFoo",
                        bar = "SetBar",
                    }, nil, src)
                    assert.is_not_nil(src.SetFoo)
                    assert.is_not_nil(src.SetBar)

                    src:SetFoo(true)
                    assert.is_true(src.foo)
                    src:SetBar(true)
                    assert.is_true(src.bar)

                    src:SetFoo(false)
                    assert.is_false(src.foo)
                    src:SetBar(false)
                    assert.is_false(src.bar)
                end)

                it("should return nil", function()
                    Method.AddSetters({
                        foo = "SetFoo",
                        bar = "SetBar",
                    }, nil, src)
                    assert.is_nil(src:SetFoo(true))
                    assert.is_nil(src:SetBar(true))
                end)

                TestReturnSelf("AddSetters", {
                    foo = "SetFoo",
                    bar = "SetBar",
                }, nil, src)
            end)

            describe("when is_return_self is passed", function()
                it("should add setters", function()
                    assert.is_nil(src.SetFoo)
                    assert.is_nil(src.SetBar)
                    Method.AddSetters({
                        foo = "SetFoo",
                        bar = "SetBar",
                    }, true, src)
                    assert.is_not_nil(src.SetFoo)
                    assert.is_not_nil(src.SetBar)

                    src:SetFoo(true)
                    assert.is_true(src.foo)
                    src:SetBar(true)
                    assert.is_true(src.bar)

                    src:SetFoo(false)
                    assert.is_false(src.foo)
                    src:SetBar(false)
                    assert.is_false(src.bar)
                end)

                it("should return self", function()
                    Method.AddSetters({
                        foo = "SetFoo",
                        bar = "SetBar",
                    }, true, src)
                    assert.is_equal(src, src:SetFoo(true))
                    assert.is_equal(src, src:SetBar(true))
                end)

                TestReturnSelf("AddSetters", {
                    foo = "SetFoo",
                    bar = "SetBar",
                }, true, src)
            end)
        end)

        describe("AddToAnotherClass()", function()
            describe("when a single method is passed as a string", function()
                it("should add methods from one class to another", function()
                    assert.is_nil(dest.ReturnMultiple)
                    Method.AddToAnotherClass(dest, "ReturnMultiple", src)
                    assert.is_not_nil(dest.ReturnMultiple)
                end)

                TestReturnSelf("AddToAnotherClass", dest, "ReturnMultiple", src)
            end)

            describe("when multiple methods are passed as a table", function()
                describe("and without new names", function()
                    it("should add methods from one class to another", function()
                        assert.is_nil(dest.ReturnMultiple)
                        assert.is_nil(dest.ReturnPassedValue)
                        assert.is_nil(dest.ReturnSelf)

                        Method.AddToAnotherClass(dest, {
                            "ReturnMultiple",
                            "ReturnPassedValue",
                            "ReturnSelf",
                        }, src)

                        assert.is_not_nil(dest.ReturnMultiple)
                        assert.is_not_nil(dest.ReturnPassedValue)
                        assert.is_not_nil(dest.ReturnSelf)
                    end)

                    TestReturnSelf("AddToAnotherClass", dest, {
                        "ReturnMultiple",
                        "ReturnPassedValue",
                        "ReturnSelf",
                    }, src)
                end)

                describe("and with some new names", function()
                    it("should add methods from one class to another", function()
                        assert.is_nil(dest.NewReturnMultiple)
                        assert.is_nil(dest.ReturnPassedValue)
                        assert.is_nil(dest.ReturnSelf)

                        Method.AddToAnotherClass(dest, {
                            NewReturnMultiple = "ReturnMultiple",
                            "ReturnPassedValue",
                            "ReturnSelf",
                        }, src)

                        assert.is_nil(dest.ReturnMultiple)
                        assert.is_not_nil(dest.NewReturnMultiple)
                        assert.is_not_nil(dest.ReturnPassedValue)
                        assert.is_not_nil(dest.ReturnSelf)
                    end)

                    TestReturnSelf("AddToAnotherClass", dest, {
                        NewReturnMultiple = "ReturnMultiple",
                        "ReturnPassedValue",
                        "ReturnSelf",
                    }, src)
                end)
            end)
        end)

        describe("AddToggler()", function()
            describe("when is_return_self is not passed", function()
                it("should add a setter", function()
                    assert.is_nil(src.ToggleBool)
                    Method.AddToggler("bool", "ToggleBool", nil, src)
                    assert.is_not_nil(src.ToggleBool)
                    assert.is_true(src.bool)

                    src:ToggleBool()
                    assert.is_false(src.bool)

                    src:ToggleBool()
                    assert.is_true(src.bool)
                end)

                it("should return nil", function()
                    Method.AddToggler("bool", "ToggleBool", nil, src)
                    assert.is_nil(src:ToggleBool())
                end)

                TestReturnSelf("AddToggler","bool", "ToggleBool", nil, src)
            end)

            describe("when is_return_self is passed", function()
                it("should add a setter", function()
                    assert.is_nil(src.ToggleBool)
                    Method.AddToggler("bool", "ToggleBool", true, src)
                    assert.is_not_nil(src.ToggleBool)
                    assert.is_true(src.bool)

                    src:ToggleBool()
                    assert.is_false(src.bool)

                    src:ToggleBool()
                    assert.is_true(src.bool)
                end)

                it("should return self", function()
                    Method.AddToggler("bool", "ToggleBool", true, src)
                    assert.is_equal(src, src:ToggleBool())
                end)

                TestReturnSelf("AddToggler", "bool", "ToggleBool", true, src)
            end)
        end)

        describe("AddTogglers()", function()
            describe("when is_return_self is not passed", function()
                it("should add setters", function()
                    assert.is_nil(src.ToggleBool)
                    Method.AddTogglers({
                        bool = "ToggleBool",
                    }, nil, src)
                    assert.is_not_nil(src.ToggleBool)
                    assert.is_true(src.bool)

                    src:ToggleBool()
                    assert.is_false(src.bool)

                    src:ToggleBool()
                    assert.is_true(src.bool)
                end)

                it("should return nil", function()
                    Method.AddTogglers({
                        bool = "ToggleBool",
                    }, nil, src)
                    assert.is_nil(src:ToggleBool())
                end)

                TestReturnSelf("AddTogglers", {
                    bool = "ToggleBool",
                }, nil, src)
            end)

            describe("when is_return_self is passed", function()
                it("should add setters", function()
                    assert.is_nil(src.ToggleBool)
                    Method.AddTogglers({
                        bool = "ToggleBool",
                    }, true, src)
                    assert.is_not_nil(src.ToggleBool)
                    assert.is_true(src.bool)

                    src:ToggleBool()
                    assert.is_false(src.bool)

                    src:ToggleBool()
                    assert.is_true(src.bool)
                end)

                it("should return self", function()
                    Method.AddTogglers({
                        bool = "ToggleBool",
                    }, true, src)
                    assert.is_equal(src, src:ToggleBool())
                end)

                TestReturnSelf("AddTogglers", {
                    bool = "ToggleBool",
                }, true, src)
            end)
        end)

        describe("AddToString()", function()
            describe("when a class is passed", function()
                it("should add metatable __tostring()", function()
                    assert.is_not_equal("foo", tostring(src))
                    Method.AddToString("foo", src)
                    assert.is_equal("foo", tostring(src))
                end)

                TestReturnSelf("AddToString", "foo", src)
            end)

            describe("when a table is passed", function()
                local t = {}

                it("should add metatable __tostring()", function()
                    assert.is_not_equal("foo", tostring(t))
                    Method.AddToString("foo", t)
                    assert.is_equal("foo", tostring(t))
                end)

                TestReturnSelf("AddToString", "foo", t)
            end)
        end)
    end)

    describe("remove", function()
        describe("Remove()", function()
            describe("when a single method is passed as a string", function()
                it("should remove methods from a class", function()
                    assert.is_not_nil(src.ReturnMultiple)
                    assert.is_not_nil(src.ReturnPassedValue)
                    assert.is_not_nil(src.ReturnSelf)

                    Method.Remove("ReturnMultiple", src)
                    Method.Remove("ReturnPassedValue", src)
                    Method.Remove("ReturnSelf", src)

                    assert.is_nil(src.ReturnMultiple)
                    assert.is_nil(src.ReturnPassedValue)
                    assert.is_nil(src.ReturnSelf)
                end)
            end)

            describe("when multiple methods are passed as a table", function()
                it("should remove methods from a class", function()
                    assert.is_not_nil(src.ReturnMultiple)
                    assert.is_not_nil(src.ReturnPassedValue)
                    assert.is_not_nil(src.ReturnSelf)

                    Method.Remove({ "ReturnMultiple", "ReturnPassedValue", "ReturnSelf" }, src)

                    assert.is_nil(src.ReturnMultiple)
                    assert.is_nil(src.ReturnPassedValue)
                    assert.is_nil(src.ReturnSelf)
                end)
            end)

            TestReturnSelf("Remove", {}, src)
        end)
    end)
end)
