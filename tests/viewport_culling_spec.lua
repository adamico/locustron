--- Viewport Culling Integration Tests
-- Tests the viewport culling system integration with Locustron API

describe("Viewport Culling Integration", function()
  local Locustron
  local ViewportCulling

  before_each(function()
    Locustron = require("src.locustron")
    ViewportCulling = require("src.integration.viewport_culling")
  end)

  it("should create viewport culling instance", function()
    local spatial = Locustron.create()
    local culling = ViewportCulling.new(spatial)

    assert.is_not_nil(culling)
    assert.is_not_nil(culling.spatial)
    assert.is_not_nil(culling.viewport)
    assert.are.equal(32, culling.cull_margin)
  end)

  it("should create viewport culling with custom config", function()
    local spatial = Locustron.create()
    local config = {x = 100, y = 200, w = 800, h = 600, cull_margin = 64}
    local culling = ViewportCulling.new(spatial, config)

    assert.are.equal(100, culling.viewport.x)
    assert.are.equal(200, culling.viewport.y)
    assert.are.equal(800, culling.viewport.w)
    assert.are.equal(600, culling.viewport.h)
    assert.are.equal(64, culling.cull_margin)
  end)

  it("should get visible objects in viewport", function()
    local spatial = Locustron.create()

    -- Add objects at different positions
    local obj1 = {id = "visible"}
    local obj2 = {id = "offscreen"}
    local obj3 = {id = "edge"}

    spatial:add(obj1, 50, 50, 16, 16)    -- Inside viewport
    spatial:add(obj2, 500, 500, 16, 16)  -- Outside viewport
    spatial:add(obj3, 380, 280, 16, 16)  -- Near edge

    local culling = ViewportCulling.new(spatial, {x = 0, y = 0, w = 400, h = 300})
    local visible = culling:get_visible_objects()

    -- Should find objects within viewport bounds (with margin)
    assert.is_true(visible[obj1] ~= nil)
    assert.is_true(visible[obj3] ~= nil)
    -- obj2 should be culled (outside viewport)
  end)

  it("should update viewport position", function()
    local spatial = Locustron.create()
    local culling = ViewportCulling.new(spatial, {x = 0, y = 0, w = 400, h = 300})

    culling:update_viewport(100, 200, 800, 600)

    local x, y, w, h = culling:get_viewport()
    assert.are.equal(100, x)
    assert.are.equal(200, y)
    assert.are.equal(800, w)
    assert.are.equal(600, h)
  end)

  it("should track culling statistics", function()
    local spatial = Locustron.create()

    -- Add several objects
    for i = 1, 10 do
      local obj = {id = i}
      spatial:add(obj, i * 50, i * 30, 16, 16)
    end

    local culling = ViewportCulling.new(spatial, {x = 0, y = 0, w = 200, h = 150})
    local visible = culling:get_visible_objects()

    local stats = culling:get_stats()
    assert.are.equal(10, stats.total_objects)
    assert.is_number(stats.visible_objects)
    assert.is_number(stats.culled_objects)
    assert.are.equal(stats.total_objects, stats.visible_objects + stats.culled_objects)
    assert.is_number(stats.cull_ratio)
    assert.are.equal(1, stats.query_count)
  end)

  it("should check object visibility", function()
    local spatial = Locustron.create()
    local obj = {id = "test"}
    spatial:add(obj, 50, 50, 16, 16)

    local culling = ViewportCulling.new(spatial, {x = 0, y = 0, w = 400, h = 300})

    assert.is_true(culling:is_potentially_visible(obj))
  end)

  it("should create instance with factory method", function()
    local spatial = Locustron.create()
    local culling = ViewportCulling.create(spatial)

    assert.is_not_nil(culling)
    assert.are.equal(64, culling.cull_margin)  -- Default from factory
    assert.are.equal(400, culling.viewport.w)
    assert.are.equal(300, culling.viewport.h)
  end)
end)