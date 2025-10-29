SceneManager = Class('SceneManager'):include(Stateful)

SceneManager.static.Scenes = {
   SurvivorLike = {name = "SurvivorLike", module = require("demo.scenes.survivor_like"), next = "SpaceBattle"},
   SpaceBattle = {name = "SpaceBattle", module = require("demo.scenes.space_battle"), next = "Platformer"},
   Platformer = {name = "Platformer", module = require("demo.scenes.platformer"), next = "DynamicEcosystem"},
   DynamicEcosystem = {name = "DynamicEcosystem", module = require("demo.scenes.dynamic_ecosystem"), next = "SurvivorLike"},
}

function SceneManager:initialize(config)
   self.config = config or {}

   self.description = "Base scenario class"
   self.optimal_strategy = "fixed_grid"
   self.max_objects = config and config.max_objects or 100
   self.objects = {}
   self.pending_removal = {}

   self.perf_profiler = nil
end

function SceneManager:update()
end

function SceneManager:draw()
end

return SceneManager