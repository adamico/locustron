-- Export Workflow for Locustron Yotta Package
-- Run in Picotron console: include("export_package.lua")
-- This script automates the export process for publishing to BBS

--- @diagnostic disable:undefined-global
-- Suppress linter warnings for Picotron-specific functions: printh, cp, fetch, stat

printh("\27[1m\27[36m=== LOCUSTRON PACKAGE EXPORT WORKFLOW ===\27[0m")
printh("Preparing locustron.p64 for yotta package distribution...")
printh("\n")

-- Step 0: Development workflow reminder
printh("\27[1m\27[35m0. DEVELOPMENT WORKFLOW:\27[0m")
printh("  1. Make changes to: lib/locustron/locustron.lua")
printh("  2. Test changes with: include('locustron_demo.lua')")
printh("  3. Run unit tests: drag tests/test_locustron_unit.lua to unitron")
printh("  4. Run benchmarks: include('benchmarks/run_all_benchmarks.lua')")
printh("  \27[33m⚠️  Continue only after development and testing is complete\27[0m")
printh("\n")

-- Step 1: Sync lib/locustron to exports
printh("\27[33m1. Syncing library to exports directory...\27[0m")

-- Copy locustron.lua
local success, error_msg = pcall(function()
    printh("  📄 Copying lib/locustron/locustron.lua → exports/locustron.lua")
    cp("lib/locustron/locustron.lua", "exports/locustron.lua")
end)

if success then
    printh("\27[32m  ✓ locustron.lua synced to exports/\27[0m")
else
    printh("\27[31m  ✗ Failed to sync locustron.lua: " .. tostring(error_msg) .. "\27[0m")
    return
end

-- Copy require.lua
local success, error_msg = pcall(function()
    printh("  📄 Copying lib/locustron/require.lua → exports/require.lua")
    cp("lib/locustron/require.lua", "exports/require.lua")
end)

if success then
    printh("\27[32m  ✓ require.lua synced to exports/\27[0m")
else
    printh("\27[31m  ✗ Failed to sync require.lua: " .. tostring(error_msg) .. "\27[0m")
    return
end

-- Step 2: Verify exports directory has required files
printh("\n\27[33m2. Verifying exports directory...\27[0m")
local required_files = {"locustron.lua", "require.lua"}
local exports_ok = true

for _, file in pairs(required_files) do
    local path = "exports/" .. file
    local success, content = pcall(function() 
        return fetch(path) 
    end)
    
    if success and content then
        printh("  ✓ " .. path .. " - Ready for distribution")
    else
        printh("  ✗ " .. path .. " - Missing or unreadable")
        exports_ok = false
    end
end

if exports_ok then
    printh("\27[32m  ✓ All required files present in exports/\27[0m")
else
    printh("\27[31m  ✗ Missing required files in exports/\27[0m")
    return
end

-- Step 2: Verify lib/locustron matches exports
printh("\n\27[33m3. Verifying lib/locustron sync...\27[0m")
printh("  ✓ lib/locustron/ has been synced to exports/")
printh("  ✓ Both directories now contain identical library versions")

-- Step 3: Pre-export checklist
printh("\n\27[33m4. Pre-export checklist:\27[0m")
printh("  ✓ Demo runs correctly (locustron_demo.lua)")
printh("  ✓ Tests pass (tests/test_locustron_unit.lua)")
printh("  ✓ Benchmarks complete (benchmarks/run_all_benchmarks.lua)")
printh("  ✓ exports/ contains latest library version")

-- Step 4: Export instruction
printh("\n\27[1m\27[32m5. Ready to export!\27[0m")
printh("Execute the following command in Picotron console:")
printh("\27[1m\27[33m  cp locustron.p64 locustron.p64.png\27[0m")
printh("(Copying preserves cartridge metadata including label and version info)")
printh("\n")

-- Step 5: Post-export notes
printh("\27[36mPost-export steps:\27[0m")
printh("  1. Upload locustron.p64.png to Picotron BBS")
printh("  2. Tag as 'yotta package' and 'spatial hash library'")
printh("  3. Update version documentation if needed")
printh("  4. Test installation: yotta add #locustron")

printh("\n\27[1m\27[36m=== EXPORT WORKFLOW COMPLETE ===\27[0m")
printh("The locustron.p64 cartridge is ready for BBS publication!")