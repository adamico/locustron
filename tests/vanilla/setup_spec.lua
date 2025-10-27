-- Simple test to verify Busted assertions work
describe("Busted test setup", function()
  it("should have basic assertions", function()
    assert.equals(1, 1)
    assert.truthy(true)
    assert.falsy(false)
    assert.falsy(nil)
  end)
  
  it("should handle nil assertions", function()
    local value = nil
    assert.falsy(value)
    
    local not_nil = "test"
    assert.truthy(not_nil)
  end)
end)