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
printh("  1. Make changes to: src/picotron/locustron.lua")
printh("  2. Test changes with: include('main.lua')")
printh("  3. Run unit tests: drag tests/picotron/test_locustron_unit.lua to unitron")
printh("  4. Run benchmarks: include('benchmarks/picotron/run_all_benchmarks.lua')")
printh("  \27[33m⚠️  Continue only after development and testing is complete\27[0m")
printh("\n")

-- Step 1: Sync src/picotron to both lib/locustron and exports
printh("\27[33m1. Syncing library to lib/locustron and exports directories...\27[0m")

-- Copy locustron.lua to lib/locustron (for local development)
local success, error_msg = pcall(function()
   printh("  📄 Copying src/picotron/locustron.lua → lib/locustron/locustron.lua")
   cp("src/picotron/locustron.lua", "lib/locustron/locustron.lua")
end)

if success then
   printh("\27[32m  ✓ locustron.lua synced to lib/locustron/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync locustron.lua to lib/locustron/: "..tostring(error_msg).."\27[0m")
   return
end

-- Copy locustron.lua to exports
local success, error_msg = pcall(function()
   printh("  📄 Copying src/picotron/locustron.lua → exports/locustron.lua")
   cp("src/picotron/locustron.lua", "exports/locustron.lua")
end)

if success then
   printh("\27[32m  ✓ locustron.lua synced to exports/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync locustron.lua to exports/: "..tostring(error_msg).."\27[0m")
   return
end

-- Copy require.lua to lib/locustron (for local development)
local success, error_msg = pcall(function()
   printh("  📄 Copying src/picotron/require.lua → lib/locustron/require.lua")
   cp("src/picotron/require.lua", "lib/locustron/require.lua")
end)

if success then
   printh("\27[32m  ✓ require.lua synced to lib/locustron/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync require.lua to lib/locustron/: "..tostring(error_msg).."\27[0m")
   return
end

-- Copy require.lua to exports
local success, error_msg = pcall(function()
   printh("  📄 Copying src/picotron/require.lua → exports/require.lua")
   cp("src/picotron/require.lua", "exports/require.lua")
end)

if success then
   printh("\27[32m  ✓ require.lua synced to exports/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync require.lua to exports/: "..tostring(error_msg).."\27[0m")
   return
end

-- Step 2: Verify exports directory has required files
printh("\n\27[33m2. Verifying exports directory...\27[0m")
local required_files = {"locustron.lua", "require.lua"}
local exports_ok = true

for _, file in pairs(required_files) do
   local path = "exports/"..file
   local success, content = pcall(function()
      return fetch(path)
   end)

   if success and content then
      printh("  ✓ "..path.." - Ready for distribution")
   else
      printh("  ✗ "..path.." - Missing or unreadable")
      exports_ok = false
   end
end

if exports_ok then
   printh("\27[32m  ✓ All required files present in exports/\27[0m")
else
   printh("\27[31m  ✗ Missing required files in exports/\27[0m")
   return
end

-- Step 3: Verify lib/locustron sync
printh("\n\27[33m3. Verifying lib/locustron sync...\27[0m")
printh("  ✓ src/picotron/ has been synced to lib/locustron/")
printh("  ✓ lib/locustron/ directory ready for local yotta-style development")
printh("  ✓ exports/ directory ready for BBS distribution")

-- Step 4: Pre-export checklist
printh("\n\27[33m4. Pre-export checklist:\27[0m")
printh("  ✓ Demo runs correctly (main.lua)")
printh("  ✓ Tests pass (tests/picotron/test_locustron_unit.lua)")
printh("  ✓ Benchmarks complete (benchmarks/picotron/run_all_benchmarks.lua)")
printh("  ✓ lib/locustron/ contains latest library version (for yotta simulation)")
printh("  ✓ exports/ contains latest library version (for BBS distribution)")

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
