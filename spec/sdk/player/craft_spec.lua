require "busted.runner"()

describe("#sdk SDK.Player.Craft", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Craft

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        -- globals
        _G.AllRecipes = nil
        _G.IsRecipeValid = nil
        _G.ThePlayer = nil
        _G.TheWorld = nil

        -- sdk
        LoadSDK()
    end)

    before_each(function()
        -- globals
        _G.AllRecipes = {
            foo = {
                builder_tag = "builder_tag",
            },
            bar = {
                placer = "placer",
            },
        }

        _G.IsRecipeValid = spy.new(function(recipe)
            return _G.AllRecipes[recipe] and true or false
        end)

        _G.ThePlayer = mock({
            GUID = 1,
            components = {
                builder = {
                    recipes = { "foo" },
                    AddRecipe = Empty,
                    GiveAllRecipes = Empty,
                },
            },
            player_classified = {
                isfreebuildmode = {
                    value = ReturnValueFn(false),
                },
            },
            replica = mock({
                builder = {
                    classified = {
                        recipes = {
                            foo = {
                                value = ReturnValueFn(true),
                            },
                            bar = {
                                value = ReturnValueFn(false),
                            },
                        },
                    },
                    RemoveRecipe = Empty,
                },
            }),
            userid = "KU_foobar",
            GetDisplayName = ReturnValueFn("Player"),
            HasTag = function(_, tag)
                return tag == "player"
            end,
            PushEvent = Empty,
        })

        _G.TheWorld = {}

        -- initialization
        SDK = require "yoursubdirectory/sdk/sdk/sdk"
        SDK.SetPath("yoursubdirectory/sdk")
        SDK.LoadModule("Utils")
        SDK.LoadModule("Debug")
        SDK.LoadModule("Remote")
        SDK.LoadModule("Player")
        Craft = require "yoursubdirectory/sdk/sdk/player/craft"

        SetTestModule(Craft)

        -- spies
        if SDK.IsLoaded("Debug") then
            SDK.Debug.Error = spy.on(SDK.Debug, "Error")
            SDK.Debug.String = spy.on(SDK.Debug, "String")
        end
    end)

    local function AssertDebugString(fn, ...)
        _G.AssertDebugString(fn, "[player]", "[craft]", ...)
    end

    local function TestDebugError(fn, ...)
        local args = { ... }
        it("should debug error string", function()
            AssertDebugError(fn, unpack(args))
        end)
    end

    local function TestDebugErrorNoComponent(fn, fn_name, entity, name)
        it("should debug error string", function()
            AssertDebugError(
                fn,
                string.format("SDK.Player.Craft.%s():", fn_name),
                name:gsub("^%l", string.upper),
                "component is not available",
                "(" .. entity:GetDisplayName() .. ")"
            )
        end)
    end

    local function TestDebugErrorNoReplica(fn, fn_name, entity, name)
        it("should debug error string", function()
            AssertDebugError(
                fn,
                string.format("SDK.Player.Craft.%s():", fn_name),
                name:gsub("^%l", string.upper),
                "replica is not available",
                "(" .. entity:GetDisplayName() .. ")"
            )
        end)
    end

    local function TestDebugString(fn, ...)
        local args = { ... }
        it("should debug string", function()
            AssertDebugString(fn, unpack(args))
        end)
    end

    local function TestNoDebugError(fn)
        it("shouldn't debug error string", function()
            AssertDebugErrorCalls(fn, 0)
        end)
    end

    describe("free crafting", function()
        describe("HasFreeCrafting()", function()
            Craft = require "yoursubdirectory/sdk/sdk/player/craft"

            TestArgPlayer("HasFreeCrafting", {
                empty = {},
                invalid = { "foo" },
                valid = { _G.ThePlayer },
            })

            describe("when a valid player is passed", function()
                local function TestIsFreeBuildModeWasCalled(fn)
                    it("should call [player].player_classified.isfreebuildmode:value()", function()
                        assert.spy(_G.ThePlayer.player_classified.isfreebuildmode.value)
                            .was_not_called()
                        fn()
                        assert.spy(_G.ThePlayer.player_classified.isfreebuildmode.value)
                            .was_called(1)
                        assert.spy(_G.ThePlayer.player_classified.isfreebuildmode.value)
                            .was_called_with(
                                match.is_ref(_G.ThePlayer.player_classified.isfreebuildmode)
                            )
                    end)
                end

                describe("and a free crafting is enabled", function()
                    before_each(function()
                        _G.ThePlayer.player_classified.isfreebuildmode.value = spy.new(
                            ReturnValueFn(true)
                        )
                    end)

                    TestIsFreeBuildModeWasCalled(function()
                        Craft.HasFreeCrafting()
                    end)

                    it("should return true", function()
                        assert.is_true(Craft.HasFreeCrafting())
                    end)
                end)

                describe("and a free crafting is disabled", function()
                    _G.ThePlayer.player_classified.isfreebuildmode.value = spy.new(
                        ReturnValueFn(false)
                    )

                    TestIsFreeBuildModeWasCalled(function()
                        Craft.HasFreeCrafting()
                    end)

                    it("should return false", function()
                        assert.is_false(Craft.HasFreeCrafting())
                    end)
                end)
            end)
        end)

        describe("ToggleFreeCrafting()", function()
            local _fn

            setup(function()
                _fn = SDK.Remote.Player.ToggleFreeCrafting
            end)

            teardown(function()
                SDK.Remote.Player.ToggleFreeCrafting = _fn
            end)

            before_each(function()
                SDK.Remote.Player.ToggleFreeCrafting = spy.new(Empty)
            end)

            TestArgPlayer("ToggleFreeCrafting", {
                empty = {},
                invalid = { "foo" },
                valid = { _G.ThePlayer },
            })

            describe("when valid arguments are passed", function()
                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    describe("and a builder component is not available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder = nil
                        end)

                        TestDebugErrorNoComponent(function()
                            Craft.ToggleFreeCrafting(_G.ThePlayer)
                        end, "ToggleFreeCrafting", _G.ThePlayer, "builder")

                        it("should return false", function()
                            assert.is_false(Craft.ToggleFreeCrafting(_G.ThePlayer))
                        end)
                    end)

                    describe("and a builder component is available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder = mock({
                                GiveAllRecipes = Empty,
                            })
                        end)

                        TestNoDebugError(function()
                            Craft.ToggleFreeCrafting(_G.ThePlayer)
                        end)

                        TestDebugString(function()
                            Craft.ToggleFreeCrafting(_G.ThePlayer)
                        end, "Toggle free crafting:", "Player")

                        it("should call [player].components.builder:GiveAllRecipes()", function()
                            assert.spy(_G.ThePlayer.components.builder.GiveAllRecipes)
                                .was_not_called()
                            Craft.ToggleFreeCrafting(_G.ThePlayer)
                            assert.spy(_G.ThePlayer.components.builder.GiveAllRecipes).was_called(1)
                            assert.spy(_G.ThePlayer.components.builder.GiveAllRecipes)
                                .was_called_with(
                                    match.is_ref(_G.ThePlayer.components.builder)
                                )
                        end)

                        it("should call [player]:PushEvent()", function()
                            assert.spy(_G.ThePlayer.PushEvent).was_not_called()
                            Craft.ToggleFreeCrafting(_G.ThePlayer)
                            assert.spy(_G.ThePlayer.PushEvent).was_called(1)
                            assert.spy(_G.ThePlayer.PushEvent).was_called_with(
                                match.is_ref(_G.ThePlayer),
                                "techlevelchange"
                            )
                        end)

                        it("should return true", function()
                            assert.is_true(Craft.ToggleFreeCrafting(_G.ThePlayer))
                        end)
                    end)
                end)

                describe("and is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    it("should call SDK.Remote.Player.ToggleFreeCrafting()", function()
                        assert.spy(SDK.Remote.Player.ToggleFreeCrafting).was_not_called()
                        Craft.ToggleFreeCrafting(_G.ThePlayer)
                        assert.spy(SDK.Remote.Player.ToggleFreeCrafting).was_called(1)
                        assert.spy(SDK.Remote.Player.ToggleFreeCrafting).was_called_with(
                            _G.ThePlayer
                        )
                    end)

                    it("should return SDK.Remote.Player.ToggleFreeCrafting() value", function()
                        SDK.Remote.Player.ToggleFreeCrafting = ReturnValueFn(true)
                        assert.is_true(Craft.ToggleFreeCrafting(_G.ThePlayer))
                        SDK.Remote.Player.ToggleFreeCrafting = ReturnValueFn(false)
                        assert.is_false(Craft.ToggleFreeCrafting(_G.ThePlayer))
                    end)
                end)
            end)
        end)
    end)

    describe("recipe", function()
        describe("IsLearnedRecipe()", function()
            TestArgRecipe("IsLearnedRecipe", {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "foobar", _G.ThePlayer },
                valid = { "foo", _G.ThePlayer },
            })

            TestArgPlayer("IsLearnedRecipe", {
                empty = { "foo" },
                invalid = { "foo", "foo" },
                valid = { "foo", _G.ThePlayer },
            })

            describe("when an invalid recipe is passed", function()
                it("should return nil", function()
                    assert.is_nil(Craft.IsLearnedRecipe("foobar", _G.ThePlayer))
                end)
            end)

            describe("when an invalid player is passed", function()
                it("should return nil", function()
                    assert.is_nil(Craft.IsLearnedRecipe("foo", "foo"))
                end)
            end)

            describe("when valid arguments are passed", function()
                describe("when a recipe is learned", function()
                    it("should return true", function()
                        assert.is_true(Craft.IsLearnedRecipe("foo", _G.ThePlayer))
                    end)
                end)

                describe("when a recipe is not learned", function()
                    it("should return false", function()
                        assert.is_false(Craft.IsLearnedRecipe("bar", _G.ThePlayer))
                    end)
                end)
            end)
        end)

        describe("LockRecipe()", function()
            local _fn

            setup(function()
                _fn = SDK.Remote.Player.LockRecipe
            end)

            teardown(function()
                SDK.Remote.Player.LockRecipe = _fn
            end)

            before_each(function()
                SDK.Remote.Player.LockRecipe = spy.new(Empty)
            end)

            TestArgRecipe("LockRecipe", {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "foobar", _G.ThePlayer },
                valid = { "foo", _G.ThePlayer },
            })

            TestArgPlayer("LockRecipe", {
                empty = { "foo" },
                invalid = { "foo", "foo" },
                valid = { "foo", _G.ThePlayer },
            })

            describe("when valid arguments are passed", function()
                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    describe("and a builder component is not available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder = nil
                        end)

                        TestDebugErrorNoComponent(function()
                            Craft.LockRecipe("foo", _G.ThePlayer)
                        end, "LockRecipe", _G.ThePlayer, "builder")

                        it("should return false", function()
                            assert.is_false(Craft.LockRecipe("foo", _G.ThePlayer))
                        end)
                    end)

                    describe("and a builder component is available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder.recipes = { "foo" }
                        end)

                        TestNoDebugError(function()
                            Craft.LockRecipe("foo", _G.ThePlayer)
                        end)

                        describe("and a builder replica is not available", function()
                            before_each(function()
                                _G.ThePlayer.replica.builder = nil
                            end)

                            TestDebugErrorNoReplica(function()
                                Craft.LockRecipe("foo", _G.ThePlayer)
                            end, "LockRecipe", _G.ThePlayer, "builder")

                            it("should return false", function()
                                assert.is_false(Craft.LockRecipe("foo", _G.ThePlayer))
                            end)
                        end)

                        describe("and a builder replica is available", function()
                            before_each(function()
                                _G.ThePlayer.replica.builder = mock({
                                    classified = {
                                        recipes = {
                                            foo = {
                                                value = ReturnValueFn(true),
                                            },
                                            bar = {
                                                value = ReturnValueFn(false),
                                            },
                                        },
                                    },
                                    RemoveRecipe = Empty,
                                })
                            end)

                            describe("and a builder component recipes are not available", function()
                                before_each(function()
                                    _G.ThePlayer.components.builder.recipes = nil
                                end)

                                TestDebugError(
                                    function()
                                        Craft.LockRecipe("foo", _G.ThePlayer)
                                    end,
                                    "SDK.Player.Craft.LockRecipe():",
                                    "Builder component recipes not found"
                                )

                                it(
                                    "shouldn't call [player].replica.builder:RemoveRecipe()",
                                    function()
                                        assert.spy(_G.ThePlayer.replica.builder.RemoveRecipe)
                                              .was_not_called()
                                        Craft.LockRecipe("foo", _G.ThePlayer)
                                        assert.spy(_G.ThePlayer.replica.builder.RemoveRecipe)
                                              .was_not_called()
                                    end
                                )

                                it("should return false", function()
                                    assert.is_false(Craft.LockRecipe("foo", _G.ThePlayer))
                                end)
                            end)

                            describe("and a builder component recipes are available", function()
                                before_each(function()
                                    _G.ThePlayer.components.builder.recipes = { "foo" }
                                end)

                                TestNoDebugError(function()
                                    Craft.LockRecipe("foo", _G.ThePlayer)
                                end)

                                TestDebugString(function()
                                    Craft.LockRecipe("foo", _G.ThePlayer)
                                end, "Lock recipe:", "foo", "(Player)")

                                it("should remove a builder component recipe", function()
                                    assert.is_equal(1, #_G.ThePlayer.components.builder.recipes)
                                    Craft.LockRecipe("foo", _G.ThePlayer)
                                    assert.is_equal(0, #_G.ThePlayer.components.builder.recipes)
                                end)

                                it("should call [player].replica.builder:RemoveRecipe()", function()
                                    assert.spy(_G.ThePlayer.replica.builder.RemoveRecipe)
                                        .was_not_called()
                                    Craft.LockRecipe("foo", _G.ThePlayer)
                                    assert.spy(_G.ThePlayer.replica.builder.RemoveRecipe)
                                        .was_called(1)
                                    assert.spy(_G.ThePlayer.replica.builder.RemoveRecipe)
                                        .was_called_with(
                                            match.is_ref(_G.ThePlayer.replica.builder),
                                            "foo"
                                        )
                                end)

                                it("should return true", function()
                                    assert.is_true(Craft.LockRecipe("foo", _G.ThePlayer))
                                end)
                            end)
                        end)
                    end)
                end)

                describe("and is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    it("should call SDK.Remote.Player.LockRecipe()", function()
                        assert.spy(SDK.Remote.Player.LockRecipe).was_not_called()
                        Craft.LockRecipe("foo", _G.ThePlayer)
                        assert.spy(SDK.Remote.Player.LockRecipe).was_called(1)
                        assert.spy(SDK.Remote.Player.LockRecipe).was_called_with(
                            "foo",
                            _G.ThePlayer
                        )
                    end)

                    it("should return SDK.Remote.Player.LockRecipe() value", function()
                        SDK.Remote.Player.LockRecipe = ReturnValueFn(true)
                        assert.is_true(Craft.LockRecipe("foo", _G.ThePlayer))
                        SDK.Remote.Player.LockRecipe = ReturnValueFn(false)
                        assert.is_false(Craft.LockRecipe("foo", _G.ThePlayer))
                    end)
                end)
            end)
        end)

        describe("UnlockRecipe()", function()
            local _fn

            setup(function()
                _fn = SDK.Remote.Player.UnlockRecipe
            end)

            teardown(function()
                SDK.Remote.Player.UnlockRecipe = _fn
            end)

            before_each(function()
                SDK.Remote.Player.UnlockRecipe = spy.new(Empty)
            end)

            TestArgRecipe("UnlockRecipe", {
                empty = {
                    args = { nil, _G.ThePlayer },
                    calls = 1,
                },
                invalid = { "foobar", _G.ThePlayer },
                valid = { "foo", _G.ThePlayer },
            })

            TestArgPlayer("UnlockRecipe", {
                empty = { "foo" },
                invalid = { "foo", "foo" },
                valid = { "foo", _G.ThePlayer },
            })

            describe("when valid arguments are passed", function()
                describe("and is master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = true
                    end)

                    describe("and a builder component is not available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder = nil
                        end)

                        TestDebugErrorNoComponent(function()
                            Craft.UnlockRecipe("foo", _G.ThePlayer)
                        end, "UnlockRecipe", _G.ThePlayer, "builder")

                        it("should return false", function()
                            assert.is_false(Craft.UnlockRecipe("foo", _G.ThePlayer))
                        end)
                    end)

                    describe("and a builder component is available", function()
                        before_each(function()
                            _G.ThePlayer.components.builder = mock({
                                AddRecipe = Empty,
                            })
                        end)

                        TestNoDebugError(function()
                            Craft.UnlockRecipe("foo", _G.ThePlayer)
                        end)

                        TestDebugString(function()
                            Craft.UnlockRecipe("foo", _G.ThePlayer)
                        end, "Unlock recipe:", "foo", "(Player)")

                        it("should call [player].components.builder:AddRecipe()", function()
                            assert.spy(_G.ThePlayer.components.builder.AddRecipe).was_not_called()
                            Craft.UnlockRecipe("foo", _G.ThePlayer)
                            assert.spy(_G.ThePlayer.components.builder.AddRecipe).was_called(1)
                            assert.spy(_G.ThePlayer.components.builder.AddRecipe).was_called_with(
                                match.is_ref(_G.ThePlayer.components.builder),
                                "foo"
                            )
                        end)

                        it("should call [player]:PushEvent()", function()
                            assert.spy(_G.ThePlayer.PushEvent).was_not_called()
                            Craft.UnlockRecipe("foo", _G.ThePlayer)
                            assert.spy(_G.ThePlayer.PushEvent).was_called(1)
                            assert.spy(_G.ThePlayer.PushEvent).was_called_with(
                                match.is_ref(_G.ThePlayer),
                                "unlockrecipe",
                                { recipe = "foo" }
                            )
                        end)

                        it("should return true", function()
                            assert.is_true(Craft.UnlockRecipe("foo", _G.ThePlayer))
                        end)
                    end)
                end)

                describe("and is non-master simulation", function()
                    before_each(function()
                        _G.TheWorld.ismastersim = false
                    end)

                    it("should call SDK.Remote.Player.UnlockRecipe()", function()
                        assert.spy(SDK.Remote.Player.UnlockRecipe).was_not_called()
                        Craft.UnlockRecipe("foo", _G.ThePlayer)
                        assert.spy(SDK.Remote.Player.UnlockRecipe).was_called(1)
                        assert.spy(SDK.Remote.Player.UnlockRecipe).was_called_with(
                            "foo",
                            _G.ThePlayer
                        )
                    end)

                    it("should return SDK.Remote.Player.UnlockRecipe() value", function()
                        SDK.Remote.Player.UnlockRecipe = ReturnValueFn(true)
                        assert.is_true(Craft.UnlockRecipe("foo", _G.ThePlayer))
                        SDK.Remote.Player.UnlockRecipe = ReturnValueFn(false)
                        assert.is_false(Craft.UnlockRecipe("foo", _G.ThePlayer))
                    end)
                end)
            end)
        end)
    end)

    describe("recipes", function()
        describe("FilterRecipesBy()", function()
            TestArgRecipes("FilterRecipesBy", {
                empty = { Empty },
                invalid = { Empty, "foo" },
                valid = { Empty, _G.AllRecipes },
            })

            it("should return filtered recipes", function()
                assert.is_equal(2, TableCount(Craft.FilterRecipesBy(ReturnValueFn(true))))
                assert.is_same({}, Craft.FilterRecipesBy(ReturnValueFn(false)))

                assert.is_same({
                    foo = {
                        builder_tag = "builder_tag",
                    },
                }, Craft.FilterRecipesBy(function(name)
                    return name == "foo"
                end))

                assert.is_same({
                    bar = {
                        placer = "placer",
                    },
                }, Craft.FilterRecipesBy(function(name)
                    return name == "bar"
                end))
            end)
        end)

        describe("FilterRecipesByLearned()", function()
            local _fn

            setup(function()
                _fn = Craft.IsLearnedRecipe
            end)

            teardown(function()
                Craft.IsLearnedRecipe = _fn
            end)

            before_each(function()
                Craft.IsLearnedRecipe = function(name)
                    return name == "foo"
                end
            end)

            TestArgPlayer("FilterRecipesByLearned", {
                empty = { _G.AllRecipes },
                invalid = { _G.AllRecipes, "foo" },
                valid = { _G.AllRecipes, _G.ThePlayer },
            })

            TestArgRecipes("FilterRecipesByLearned", {
                empty = { nil, _G.ThePlayer },
                invalid = { "foo", _G.ThePlayer },
                valid = { _G.AllRecipes, _G.ThePlayer },
            })

            it("should return filtered recipes", function()
                assert.is_same({
                    foo = {
                        builder_tag = "builder_tag",
                    },
                }, Craft.FilterRecipesByLearned())
            end)
        end)

        describe("FilterRecipesByNotLearned()", function()
            local _fn

            setup(function()
                _fn = Craft.IsLearnedRecipe
            end)

            teardown(function()
                Craft.IsLearnedRecipe = _fn
            end)

            before_each(function()
                Craft.IsLearnedRecipe = function(name)
                    return name == "foo"
                end
            end)

            TestArgPlayer("FilterRecipesByNotLearned", {
                empty = { _G.AllRecipes },
                invalid = { _G.AllRecipes, "foo" },
                valid = { _G.AllRecipes, _G.ThePlayer },
            })

            TestArgRecipes("FilterRecipesByNotLearned", {
                empty = { nil, _G.ThePlayer },
                invalid = { "foo", _G.ThePlayer },
                valid = { _G.AllRecipes, _G.ThePlayer },
            })

            it("should return filtered recipes", function()
                assert.is_same({
                    bar = {
                        placer = "placer",
                    },
                }, Craft.FilterRecipesByNotLearned())
            end)
        end)

        describe("FilterRecipesWith()", function()
            TestArgRecipes("FilterRecipesWith", {
                empty = { "builder_tag" },
                invalid = { "builder_tag", "foo" },
                valid = { "builder_tag", _G.AllRecipes },
            })

            it("should return filtered recipes", function()
                assert.is_same({
                    foo = {
                        builder_tag = "builder_tag",
                    },
                }, Craft.FilterRecipesWith("builder_tag"))
                assert.is_same({
                    bar = {
                        placer = "placer",
                    },
                }, Craft.FilterRecipesWith("placer"))
                assert.is_same({}, Craft.FilterRecipesWith("foo"))
            end)
        end)

        describe("FilterRecipesWithout()", function()
            TestArgRecipes("FilterRecipesWithout", {
                empty = { "builder_tag" },
                invalid = { "builder_tag", "foo" },
                valid = { "builder_tag", _G.AllRecipes },
            })

            it("should return filtered recipes", function()
                assert.is_same({
                    bar = {
                        placer = "placer",
                    },
                }, Craft.FilterRecipesWithout("builder_tag"))
                assert.is_same({
                    foo = {
                        builder_tag = "builder_tag",
                    },
                }, Craft.FilterRecipesWithout("placer"))
                assert.is_equal(2, TableCount(Craft.FilterRecipesWithout("foo")))
            end)
        end)

        describe("GetLearnedRecipes()", function()
            TestArgPlayer("GetLearnedRecipes", {
                empty = {},
                invalid = { "foo" },
                valid = { _G.ThePlayer },
            })

            describe("when is master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = true
                end)

                describe("and a builder component is not available", function()
                    before_each(function()
                        _G.ThePlayer.components.builder = nil
                    end)

                    TestDebugErrorNoComponent(function()
                        Craft.GetLearnedRecipes()
                    end, "GetLearnedRecipes", _G.ThePlayer, "builder")

                    it("should return nil", function()
                        assert.is_nil(Craft.GetLearnedRecipes())
                    end)
                end)

                describe("and a builder component is available", function()
                    before_each(function()
                        _G.ThePlayer.components.builder.recipes = { "foo" }
                    end)

                    TestNoDebugError(function()
                        Craft.GetLearnedRecipes()
                    end)

                    it("should return learned recipes", function()
                        assert.is_same({ "foo" }, Craft.GetLearnedRecipes())
                    end)
                end)
            end)

            describe("when is non-master simulation", function()
                before_each(function()
                    _G.TheWorld.ismastersim = false
                end)

                describe("and a builder replica is not available", function()
                    before_each(function()
                        _G.ThePlayer.replica.builder = nil
                    end)

                    TestDebugErrorNoReplica(function()
                        Craft.GetLearnedRecipes()
                    end, "GetLearnedRecipes", _G.ThePlayer, "builder")

                    it("should return nil", function()
                        assert.is_nil(Craft.GetLearnedRecipes())
                    end)
                end)

                describe("and a builder replica is available", function()
                    before_each(function()
                        _G.ThePlayer.replica.builder = {}
                    end)

                    describe("and recipes are not available", function()
                        before_each(function()
                            _G.ThePlayer.replica.builder.classified = {
                                recipes = nil,
                            }
                        end)

                        TestNoDebugError(function()
                            Craft.GetLearnedRecipes()
                        end)

                        it("should return nil", function()
                            assert.is_nil(Craft.GetLearnedRecipes())
                        end)
                    end)

                    describe("and recipes are available", function()
                        before_each(function()
                            _G.ThePlayer.replica.builder.classified = {
                                recipes = {
                                    foo = {
                                        value = ReturnValueFn(true),
                                    },
                                    bar = {
                                        value = ReturnValueFn(false),
                                    },
                                },
                            }
                        end)

                        TestNoDebugError(function()
                            Craft.GetLearnedRecipes()
                        end)

                        it("should return learned recipes", function()
                            assert.is_same({ "foo" }, Craft.GetLearnedRecipes())
                        end)
                    end)
                end)
            end)
        end)

        describe("LockAllCharacterRecipes()", function()
            local _fn

            setup(function()
                _fn = Craft.LockRecipe
            end)

            teardown(function()
                Craft.LockRecipe = _fn
            end)

            before_each(function()
                Craft.LockRecipe = spy.new(Empty)
            end)

            TestArgPlayer("LockAllCharacterRecipes", {
                empty = {},
                invalid = { "foo" },
                valid = { _G.ThePlayer },
            })

            describe("when a valid player is passed", function()
                describe("and there are some character recipes", function()
                    before_each(function()
                        _G.AllRecipes = {
                            foo = {
                                builder_tag = "builder_tag",
                            },
                            bar = {
                                placer = "placer",
                            },
                        }
                    end)

                    TestNoDebugError(function()
                        Craft.LockAllCharacterRecipes(_G.ThePlayer)
                    end)

                    TestDebugString(function()
                        Craft.LockAllCharacterRecipes(_G.ThePlayer)
                    end, "Locking and restoring all character recipes...")

                    it(
                        "should call Craft.LockRecipe() respecting Craft.character_recipes",
                        function()
                            Craft.character_recipes[_G.ThePlayer.userid] = { "bar" }
                            assert.spy(Craft.LockRecipe).was_not_called()
                            Craft.LockAllCharacterRecipes(_G.ThePlayer)
                            assert.spy(Craft.LockRecipe).was_called(1)
                            assert.spy(Craft.LockRecipe).was_called_with(
                                "foo",
                                _G.ThePlayer
                            )
                        end
                    )

                    it("should reset Craft.character_recipes", function()
                        Craft.character_recipes[_G.ThePlayer.userid] = { "foo", "bar" }
                        Craft.LockAllCharacterRecipes(_G.ThePlayer)
                        assert.is_same({}, Craft.character_recipes[_G.ThePlayer.userid])
                    end)

                    it("should return true", function()
                        assert.is_true(Craft.LockAllCharacterRecipes(_G.ThePlayer))
                    end)
                end)

                describe("and there are no character recipes", function()
                    before_each(function()
                        _G.AllRecipes = {
                            bar = {
                                placer = "placer",
                            },
                        }
                    end)

                    TestDebugError(
                        function()
                            Craft.LockAllCharacterRecipes(_G.ThePlayer)
                        end,
                        "SDK.Player.Craft.LockAllCharacterRecipes():",
                        "Character recipes not found"
                    )
                end)
            end)
        end)

        describe("UnlockAllCharacterRecipes()", function()
            local _fn

            setup(function()
                _fn = Craft.UnlockRecipe
            end)

            teardown(function()
                Craft.UnlockRecipe = _fn
            end)

            before_each(function()
                Craft.UnlockRecipe = spy.new(Empty)
            end)

            TestArgPlayer("UnlockAllCharacterRecipes", {
                empty = {},
                invalid = { "foo" },
                valid = {
                    args = { _G.ThePlayer },
                    calls = 1,
                },
            })

            describe("when a valid player is passed", function()
                describe("and there are stored character recipes", function()
                    before_each(function()
                        Craft.character_recipes[_G.ThePlayer.userid] = { "bar" }
                    end)

                    TestDebugError(
                        function()
                            Craft.UnlockAllCharacterRecipes(_G.ThePlayer)
                        end,
                        "SDK.Player.Craft.UnlockAllCharacterRecipes():",
                        "Already",
                        "1",
                        "recipe is stored"
                    )

                    it("should return false", function()
                        assert.is_false(Craft.UnlockAllCharacterRecipes(_G.ThePlayer))
                    end)
                end)

                describe("and there are no stored character recipes", function()
                    local _FilterRecipesByLearned

                    setup(function()
                        _FilterRecipesByLearned = Craft.FilterRecipesByLearned
                    end)

                    teardown(function()
                        Craft.FilterRecipesByLearned = _FilterRecipesByLearned
                    end)

                    before_each(function()
                        Craft.character_recipes[_G.ThePlayer.userid] = {}
                    end)

                    describe("and there are no learned recipes", function()
                        before_each(function()
                            Craft.FilterRecipesByLearned = spy.new(ReturnValueFn({}))
                        end)

                        TestDebugString(function()
                            Craft.UnlockAllCharacterRecipes(_G.ThePlayer)
                        end, "Unlocking all character recipes...")
                    end)

                    describe("and there are learned recipes", function()
                        before_each(function()
                            Craft.FilterRecipesByLearned = spy.new(ReturnValueFn({ "foo" }))
                        end)

                        it("should debug strings", function()
                            if SDK.IsLoaded("Debug") then
                                assert.spy(SDK.Debug.String).was_not_called()
                                Craft.UnlockAllCharacterRecipes(_G.ThePlayer)
                                assert.spy(SDK.Debug.String).was_called(2)
                                assert.spy(SDK.Debug.String).was_called_with(
                                    "[player]",
                                    "[craft]",
                                    "Storing",
                                    "1",
                                    "previously learned character recipes..."
                                )
                                assert.spy(SDK.Debug.String).was_called_with(
                                    "[player]",
                                    "[craft]",
                                    "Unlocking all character recipes..."
                                )
                            end
                        end)

                        it("should call SDK.Remote.Player.UnlockRecipe()", function()
                            assert.spy(Craft.UnlockRecipe).was_not_called()
                            Craft.UnlockAllCharacterRecipes(_G.ThePlayer)
                            assert.spy(Craft.UnlockRecipe).was_called(1)
                            assert.spy(Craft.UnlockRecipe).was_called_with(
                                "foo",
                                _G.ThePlayer
                            )
                        end)

                        it("should return true", function()
                            assert.is_true(Craft.UnlockAllCharacterRecipes(_G.ThePlayer))
                        end)
                    end)
                end)
            end)
        end)
    end)
end)
