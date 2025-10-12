-- This file is part of spec.lua
--
-- Repository: https://github.com/atomicptr/spec.lua
--
-- License:
--
-- Copyright 2025 Christopher Kaster <me@atomicptr.de>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
-- documentation files (the “Software”), to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
-- and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions
-- of the Software.
--
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
-- TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
-- CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local M = {}

---Enable/Disable spec.lua assertions
M.assertions_enabled = true

---Internal functions to be overwritten when desired
---@type table<string, function>
M.fn = {
    ---Assert function
    ---@type fun(assertion: boolean, message: string)
    assert = function(assertion, message)
        assert(assertion, string.format("%s\n%s", message, debug.traceback()))
    end,

    ---Print error function
    ---@type fun(reason: string)
    error = function(reason)
        error(string.format("%s\n%s", reason, debug.traceback()))
    end,

    ---Converts table to simple string representation
    ---@param t table
    ---@param indent integer|nil
    ---@return string
    table_to_string = function(t, indent)
        indent = indent or 0
        local str = string.rep("  ", indent) .. "{\n"
        for k, v in pairs(t) do
            local key_str = type(k) == "string" and '"' .. k .. '"' or "[" .. tostring(k) .. "]"
            if type(v) == "table" then
                str = str .. string.rep("  ", indent + 1) .. key_str .. " = " .. M.fn.table_to_string(v, indent + 1)
            else
                str = str .. string.rep("  ", indent + 1) .. key_str .. " = " .. tostring(v) .. ",\n"
            end
        end
        str = str .. string.rep("  ", indent) .. "}"
        return str
    end,

    ---Pretty printer function
    ---@type fun(object: any): string
    pretty_print = function(object)
        if type(object) == "function" then
            local info = debug.getinfo(object, "nSl")
            return string.format("fn %s(...) defined at %s:%d", info.name or "anonymous", info.source, info.linedefined)
        elseif type(object) == "table" then
            return M.fn.table_to_string(object)
        end

        return tostring(object)
    end,
}

-- predicates

---Tests if value is a string
---@param value any
---@return boolean
function M.string(value)
    return type(value) == "string"
end

---Tests if value is a number
---@param value any
---@return boolean
function M.number(value)
    return type(value) == "number"
end

---Tests if value is a boolean
---@param value any
---@return boolean
function M.boolean(value)
    return type(value) == "boolean"
end

---Tests if value is a table
---@param value any
---@return boolean
function M.table(value)
    return type(value) == "table"
end

---Tests if value is nil
---@param value any
---@return boolean
function M.null(value)
    return value == nil
end

---Tests if value exists
---@param value any
---@return boolean
function M.exists(value)
    return value ~= nil
end

---Tests if value is supplied that it matches the spec
---@param spec fun(value: any): boolean
---@return fun(value: any): boolean
function M.optional(spec)
    if type(spec) ~= "function" then
        M.fn.error(
            string.format("spec.lua: Spec '%s' must be a function (e.g. spec.keys for tables)", M.fn.pretty_print(spec))
        )
    end

    return function(value)
        -- if no value is specified return true!
        if value == nil then
            return true
        end
        return spec(value)
    end
end

---Tests if the value is a list of `spec`
---@param spec fun(value: any): boolean
---@return fun(value: any): boolean
function M.list(spec)
    if type(spec) ~= "function" then
        M.fn.error(
            string.format("spec.lua: Spec '%s' must be a function (e.g. spec.keys for tables)", M.fn.pretty_print(spec))
        )
    end

    return function(value)
        if type(value) ~= "table" then
            return false
        end

        for _, item in ipairs(value) do
            if not spec(item) then
                return false
            end
        end

        return true
    end
end

---Tests if all of predicates are valid
---@param ... fun(value: any): boolean
---@return fun(value: any): boolean
function M.all_of(...)
    local predicates = { ... }

    for _, pred in ipairs(predicates) do
        if type(pred) ~= "function" then
            M.fn.error(
                string.format(
                    "spec.lua: Spec '%s' must be a function (e.g. spec.keys for tables)",
                    M.fn.pretty_print(pred)
                )
            )
            return function()
                return false
            end
        end
    end

    return function(value)
        for _, pred in ipairs(predicates) do
            if not pred(value) then
                return false
            end
        end

        return true
    end
end

---Tests if any of predicates is valid
---@param ... fun(value: any): boolean
---@return fun(value: any): boolean
function M.any_of(...)
    local predicates = { ... }

    for _, pred in ipairs(predicates) do
        if type(pred) ~= "function" then
            M.fn.error(
                string.format(
                    "spec.lua: Spec '%s' must be a function (e.g. spec.keys for tables)",
                    M.fn.pretty_print(pred)
                )
            )
            return function()
                return false
            end
        end
    end

    return function(value)
        for _, pred in ipairs(predicates) do
            if pred(value) then
                return true
            end
        end

        return false
    end
end

---Test if table matches a shape
---@param spec_map table<string, fun(value: any): boolean>
---@return fun(value: any): boolean
function M.keys(spec_map)
    return function(value)
        if not M.table(value) then
            return false
        end

        for key, sub_spec in pairs(spec_map) do
            local val = value[key]

            if type(sub_spec) ~= "function" then
                M.fn.error(
                    string.format(
                        "spec.lua: Spec '%s' for key '%s' must be a function (e.g. spec.keys for tables)",
                        M.fn.pretty_print(sub_spec),
                        M.fn.pretty_print(key)
                    )
                )
                return false
            end

            if not sub_spec(val) then
                return false
            end
        end

        return true
    end
end

---Check if a value matches with the given spec
---@param spec fun(value: any): boolean
---@param value any
---@return boolean
function M.valid(spec, value)
    if type(spec) ~= "function" then
        M.fn.error(
            string.format("spec.lua: Spec '%s' must be a function (e.g. spec.keys for tables)", M.fn.pretty_print(spec))
        )
        return false
    end

    return spec(value)
end

---Returns value if it matches the spec, nil otherwise
---@generic T
---@param spec fun(value: any): boolean
---@param value T
---@return T|nil
function M.conform(spec, value)
    if M.valid(spec, value) then
        return value
    end

    return nil
end

---Asserts that a spec is valid
---@generic T
---@param spec fun(value: any): boolean
---@param value T
---@return T
function M.assert(spec, value)
    if M.assertions_enabled then
        M.fn.assert(
            M.valid(spec, value),
            string.format(
                "spec.lua: Assertion failed because '%s' doesn't conform to spec '%s'",
                M.fn.pretty_print(value),
                M.fn.pretty_print(spec)
            )
        )
    end
    return value
end

return M
