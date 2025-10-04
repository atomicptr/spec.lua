# spec.lua

spec.lua is a lightweight library for defining and validating data structures in Lua, inspired by Clojures `spec` system.

It allows you to declaratively specify the shape and constraints of your data (e.g. tables, strings, numbers) and validate
against those specs at runtime. This helps catch errors early, document your data contracts and make your code more robust.

## Installation

The recommended way to install `spec.lua` is to put the file inside your project as a vendored library

## Example

```lua
local spec = require "spec"

-- spec.lua provides built-in predicates for common types
local is_string = spec.valid(spec.string, "Hello, World") -- true

assert(spec.valid(spec.number, 1337))

if spec.valid(spec.boolean, true) then
    -- ...
end

-- create specs for table shapes
local user_spec = spec.keys {
    name = spec.string,
    age = spec.number,
}

spec.valid(user_spec, { name = "Alice", age = 30}) -- valid
spec.valid(user_spec, { name = "Bob" }) -- invalid, missing key
spec.valid(user_spec, { name = "Charlie", age = "thirty" }) -- invalid, not a number

-- or you can write your own predicates
---@param my_type MyType
---@return boolean
function my_predicate(my_type)
    return my_type:condition_is_valid()
end

spec.valid(my_predicate, instance_of_type) -- true if condition is valid

-- compose multiple predicates
local bool_or_user = spec.any_of(spec.boolean, user_spec)

spec.valid(bool_or_user, true) -- true
spec.valid(bool_or_user, { name = "Alice", age = 30 }) -- true
spec.valid(bool_or_user, { name = "Bob" }) -- false

local has_name = spec.keys {
    name = spec.string,
}

local has_age = spec.keys {
    age = spec.number,
}

-- same as the previous user_spec
local is_user = spec.all_of(has_name, has_age)

spec.valid(is_user, { name = "Alice", age = 30 })

-- some useful helper functions...

-- conform returns the value if it conforms to the spec
local alice = { name = "Alice", age = 30 }
local bob = { name = "Bob" } -- invalid because it has no age...

local user = spec.conform(user_spec, alice) -- returns alice if valid
if user then
    print(user.name) -- Alice
end

spec.conform(user_spec, bob) -- returns nil

-- assert that the spec is valid otherwise throw an error
spec.assert(spec.string, "Hello, World")
```

## License

MIT
