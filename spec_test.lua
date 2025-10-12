local spec = require "spec"

describe("spec.lua", function()
    it("spec.string", function()
        assert.True(spec.string "Hello, World")
        assert.True(spec.string "")
        assert.False(spec.string(nil))
        assert.False(spec.string(1337))
    end)

    it("spec.number", function()
        assert.True(spec.number(1337))
        assert.True(spec.number(-1337))
        assert.True(spec.number(13.37))
        assert.False(spec.number(nil))
        assert.False(spec.number "Test")
    end)

    it("spec.boolean", function()
        assert.True(spec.boolean(true))
        assert.True(spec.boolean(false))
        assert.False(spec.boolean(nil))
        assert.False(spec.boolean "Test")
    end)

    it("spec.table", function()
        assert.True(spec.table {})
        assert.True(spec.table { 1, 2, 3 })
        assert.True(spec.table { a = 5, b = 6 })
        assert.False(spec.table(nil))
        assert.False(spec.table "Test")
    end)

    it("spec.null", function()
        assert.True(spec.null(nil))
        assert.False(spec.null { 1, 2, 3 })
        assert.False(spec.null "Test")
    end)

    it("spec.exists", function()
        assert.False(spec.exists(nil))
        assert.True(spec.exists { 1, 2, 3 })
        assert.True(spec.exists "Test")
    end)

    it("spec.optional", function()
        assert.True(spec.optional(spec.string) "Hello, World")
        assert.True(spec.optional(spec.string)(nil))
        assert.False(spec.optional(spec.string)(true))
    end)

    it("spec.all_of", function()
        assert.False(spec.valid(spec.all_of(spec.string, spec.number), nil))
        assert.True(spec.valid(spec.all_of(spec.table, spec.some), { 1, 2 }))
        assert.True(spec.valid(
            spec.all_of(spec.table, function(value)
                return #value >= 2
            end),
            { 1, 2, 3 }
        ))
    end)

    it("spec.any_of", function()
        assert.False(spec.valid(spec.any_of(spec.string, spec.number), nil))
        assert.True(spec.valid(spec.any_of(spec.table, spec.some), { 1, 2 }))
        assert.True(spec.valid(spec.any_of(spec.number, spec.string, spec.table), { 1, 2 }))
    end)

    it("spec.keys", function()
        local user_spec = spec.keys {
            name = spec.string,
            age = spec.number,
            active = spec.boolean,
        }

        assert.True(user_spec {
            name = "Alice",
            age = 30,
            active = true,
        })

        assert.True(user_spec {
            name = "Bob",
            age = -25,
            active = false,
        })

        assert.False(user_spec {
            name = "Charlie",
            age = 40,
        })

        assert.False(user_spec {
            name = 123,
            age = 35,
            active = true,
        })

        assert.False(user_spec {
            name = "David",
            age = "thirty",
            active = true,
        })

        assert.False(user_spec "not a table")
        assert.False(user_spec(nil))
        assert.False(user_spec {})
    end)

    it("spec.keys with extra fields", function()
        local flexible_spec = spec.keys {
            required = spec.string,
        }

        -- Extra fields should be allowed
        assert.True(flexible_spec {
            required = "must have",
            extra = 42,
            another = true,
        })
    end)

    it("spec.valid", function()
        assert.True(spec.valid(spec.string, "Hello"))
        assert.True(spec.valid(spec.number, 42))
        assert.True(spec.valid(spec.boolean, false))
        assert.True(spec.valid(spec.table, {}))

        assert.False(spec.valid(spec.string, 123))
        assert.False(spec.valid(spec.number, "not a number"))
        assert.False(spec.valid(spec.boolean, "truthy?"))
        assert.False(spec.valid(spec.table, "not a table"))

        assert.has_error(function()
            spec.valid("not a function", "value")
        end, "Spec must be a function (e.g. spec.keys for tables)")

        assert.has_error(function()
            spec.valid({}, "value")
        end, "Spec must be a function (e.g. spec.keys for tables)")
    end)

    it("spec.keys nested", function()
        local address_spec = spec.keys {
            street = spec.string,
            city = spec.string,
            zip = spec.number,
        }

        local user_spec = spec.keys {
            name = spec.string,
            age = spec.number,
            address = address_spec,
        }

        assert.True(user_spec {
            name = "Alice",
            age = 30,
            address = {
                street = "123 Main St",
                city = "Wonderland",
                zip = 12345,
            },
        })

        assert.False(user_spec {
            name = "Bob",
            age = 25,
            address = {
                street = "456 Oak Ave",
                city = 789, -- not string
            },
        })

        assert.False(user_spec {
            name = "Charlie",
            age = 35,
            address = "not a table",
        })

        assert.False(user_spec {
            name = "David",
            age = 40,
            -- missing address
        })
    end)

    it("spec.conform", function()
        assert.equal("Hello", spec.conform(spec.string, "Hello"))
        assert.equal(42, spec.conform(spec.number, 42))
        assert.equal(false, spec.conform(spec.boolean, false))
        assert.are.same({}, spec.conform(spec.table, {}))

        assert.is_nil(spec.conform(spec.string, 123))
        assert.is_nil(spec.conform(spec.number, "not a number"))
        assert.is_nil(spec.conform(spec.boolean, "truthy?"))
        assert.is_nil(spec.conform(spec.table, "not a table"))

        local user_spec = spec.keys {
            name = spec.string,
            age = spec.number,
        }
        assert.are.same(
            {
                name = "Alice",
                age = 30,
            },
            spec.conform(user_spec, {
                name = "Alice",
                age = 30,
            })
        )

        assert.is_nil(spec.conform(user_spec, {
            name = 123,
            age = 30,
        }))
    end)

    it("spec.conform with extra fields", function()
        local flexible_spec = spec.keys {
            required = spec.string,
        }
        local input = {
            required = "must have",
            extra = 42,
        }
        assert.are.same(input, spec.conform(flexible_spec, input))
    end)

    it("spec.assert", function()
        spec.assert(spec.number, 1337)

        assert.has_error(function()
            spec.assert(spec.string, 1337)
        end)

        local x = spec.assert(spec.number, 42)
        assert.equal(42, x)
    end)
end)
