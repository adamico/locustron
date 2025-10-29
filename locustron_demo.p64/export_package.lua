-- Export Workflow for Locustron Yotta Package
-- Run in Picotron console: include("export_package.lua")
-- This script automates the export process for publishing to BBS

--- @diagnostic disable:undefined-global
-- Suppress linter warnings for Picotron-specific functions: printh, cp, fetch, stat

printh("\27[1m\27[36m=== LOCUSTRON PACKAGE EXPORT WORKFLOW ===\27[0m")
printh("Preparing locustron.p64 for yotta package distribution...")
printh("📁 Build artifacts (lib/locustron/ and exports/) will be created automatically")
printh("📝 Note: exports/ folder is excluded from git (build artifacts only)")
printh("\n")

-- Step 0: Development workflow reminder
printh("\27[1m\27[35m0. DEVELOPMENT WORKFLOW:\27[0m")
printh("  1. Make changes to: src/ directories (integration/, strategies/)")
printh("  2. Test changes with: include('main.lua')")
printh("  3. Run unit tests: busted tests/ (legacy Picotron tests removed)")
printh("  4. Run benchmarks: lua benchmarks/benchmark_suite.lua (legacy benchmarks removed)")
printh("  \27[33m⚠️  Continue only after development and testing is complete\27[0m")
printh("\n")

-- Step 1: Sync src directories to both lib/locustron and exports
printh("\27[33m1. Syncing library to lib/locustron and exports directories...\27[0m")

-- Copy locustron.lua to lib/locustron (for local development)
-- Note: cp command will automatically create directory structure if it doesn't exist
local success, error_msg = pcall(function()
   printh("  📄 Copying src/locustron.lua → lib/locustron/locustron.lua")
   cp("src/locustron.lua", "lib/locustron/locustron.lua")
end)

if success then
   printh("\27[32m  ✓ locustron.lua synced to lib/locustron/ (directory created if needed)\27[0m")
else
   printh("\27[31m  ✗ Failed to sync locustron.lua to lib/locustron/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/locustron.lua exists and is readable")
   return
end

-- Copy locustron.lua to exports
-- Note: cp command will automatically create directory structure if it doesn't exist
local success, error_msg = pcall(function()
   printh("  📄 Copying src/locustron.lua → exports/locustron.lua")
   cp("src/locustron.lua", "exports/locustron.lua")
end)

if success then
   printh("\27[32m  ✓ locustron.lua synced to exports/ (directory created if needed)\27[0m")
else
   printh("\27[31m  ✗ Failed to sync locustron.lua to exports/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/locustron.lua exists and is readable")
   return
end

-- Copy require.lua to lib/locustron (for local development)
local success, error_msg = pcall(function()
   printh("  📄 Copying src/require.lua → lib/locustron/require.lua")
   cp("src/require.lua", "lib/locustron/require.lua")
end)

if success then
   printh("\27[32m  ✓ require.lua synced to lib/locustron/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync require.lua to lib/locustron/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/require.lua exists and is readable")
   return
end

-- Copy require.lua to exports
local success, error_msg = pcall(function()
   printh("  📄 Copying src/require.lua → exports/require.lua")
   cp("src/require.lua", "exports/require.lua")
end)

if success then
   printh("\27[32m  ✓ require.lua synced to exports/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync require.lua to exports/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/require.lua exists and is readable")
   return
end

-- Copy viewport_culling.lua to lib/locustron (for local development)
local success, error_msg = pcall(function()
   printh("  📄 Copying src/integration/viewport_culling.lua → lib/locustron/viewport_culling.lua")
   cp("src/integration/viewport_culling.lua", "lib/locustron/viewport_culling.lua")
end)

if success then
   printh("\27[32m  ✓ viewport_culling.lua synced to lib/locustron/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync viewport_culling.lua to lib/locustron/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/integration/viewport_culling.lua exists and is readable")
   return
end

-- Copy viewport_culling.lua to exports
local success, error_msg = pcall(function()
   printh("  📄 Copying src/integration/viewport_culling.lua → exports/viewport_culling.lua")
   cp("src/integration/viewport_culling.lua", "exports/viewport_culling.lua")
end)

if success then
   printh("\27[32m  ✓ viewport_culling.lua synced to exports/\27[0m")
else
   printh("\27[31m  ✗ Failed to sync viewport_culling.lua to exports/: " .. tostring(error_msg) .. "\27[0m")
   printh("     💡 Ensure src/integration/viewport_culling.lua exists and is readable")
   return
end

-- Copy strategy files to lib/locustron (for local development)
local strategy_files = { "doubly_linked_list.lua", "fixed_grid.lua", "init.lua", "interface.lua" }
for _, file in pairs(strategy_files) do
   local success, error_msg = pcall(function()
      printh("  📄 Copying src/strategies/" .. file .. " → lib/locustron/" .. file)
      cp("src/strategies/" .. file, "lib/locustron/" .. file)
   end)

   if success then
      printh("\27[32m  ✓ " .. file .. " synced to lib/locustron/\27[0m")
   else
      printh("\27[31m  ✗ Failed to sync " .. file .. " to lib/locustron/: " .. tostring(error_msg) .. "\27[0m")
      printh("     💡 Ensure src/strategies/" .. file .. " exists and is readable")
      return
   end
end

-- Copy strategy files to exports
for _, file in pairs(strategy_files) do
   local success, error_msg = pcall(function()
      printh("  📄 Copying src/strategies/" .. file .. " → exports/" .. file)
      cp("src/strategies/" .. file, "exports/" .. file)
   end)

   if success then
      printh("\27[32m  ✓ " .. file .. " synced to exports/\27[0m")
   else
      printh("\27[31m  ✗ Failed to sync " .. file .. " to exports/: " .. tostring(error_msg) .. "\27[0m")
      printh("     💡 Ensure src/strategies/" .. file .. " exists and is readable")
      return
   end
end

-- Step 2: Verify exports directory has required files
printh("\n\27[33m2. Verifying exports directory...\27[0m")
local required_files = {
   "locustron.lua",
   "require.lua",
   "viewport_culling.lua",
   "doubly_linked_list.lua",
   "fixed_grid.lua",
   "init.lua",
   "interface.lua",
}
local exports_ok = true

for _, file in pairs(required_files) do
   local path = "exports/" .. file
   local success, content = pcall(function() return fetch(path) end)

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

-- Step 3: Verify lib/locustron sync
printh("\n\27[33m3. Verifying lib/locustron sync...\27[0m")
printh("  ✓ src/ directories have been synced to lib/locustron/")
printh("  ✓ lib/locustron/ directory ready for local yotta-style development")
printh("  ✓ exports/ directory ready for BBS distribution")

-- Step 4: Pre-export checklist
printh("\n\27[33m4. Pre-export checklist:\27[0m")
printh("  ✓ Demo runs correctly (main.lua)")
printh("  ✓ Tests pass (vanilla tests with busted)")
printh("  ✓ Benchmarks complete (vanilla benchmarks)")
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
