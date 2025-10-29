--[[pod_format="raw",created="2025-09-30 14:22:08",modified="2025-10-29 11:58:31",revision=18]]
-- before release do:
--   cp -f /desktop/projects/locustron/demo_src /ram/cart/src
--   cp -f /desktop/projects/locustron/lib /ram/cart/lib
-- and comment the next 3 lines before release
local projects_dir = "/desktop/projects/"
local project_name = "locustron"
local full_path = projects_dir..project_name

CARTPATH = ""

if not fetch("src/main.lua") then
	cd(full_path)
	CARTPATH = "locustron_demo.p64/"
end

include("demo_src/main.lua")


