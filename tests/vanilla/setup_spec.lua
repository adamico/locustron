--- @diagnostic disable: undefined-global undefined-field
-- Test setup and Lua path configuration

-- Add current directory to Lua path for module loading
package.path = package.path .. ";./?.lua;./?/init.lua"
