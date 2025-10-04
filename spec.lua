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

---Tests if all of predicates are valid
---@param ... fun(value: any): boolean
---@return fun(value: any): boolean
function M.all_of(...)
    local predicates = { ... }

    for _, pred in ipairs(predicates) do
        if type(pred) ~= "function" then
            error "Spec must be a function (e.g. spec.keys for tables)"
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
            error "Spec must be a function (e.g. spec.keys for tables)"
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

            if val == nil or not (type(sub_spec) == "function" and sub_spec(val)) then
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
        error "Spec must be a function (e.g. spec.keys for tables)"
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
---@param spec any
---@param value any
function M.assert(spec, value)
    assert(M.valid(spec, value))
end

return M
