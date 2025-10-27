-- Custom Assert Functions for Locustron Testing
-- Include this in test files that need locustron-specific assertions

-- Custom assert for testing unknown object errors
function assert_unknown_object_error(operation_func, message)
   test_helper() -- mark this function as test helper for better error reporting
   local error_caught = false
   local old_error = _G.error
   
   _G.error = function(msg)
      if string.find(msg, "unknown object") then
         error_caught = true
         -- Use a custom error type that we can catch specifically
         error("__EXPECTED_UNKNOWN_OBJECT_ERROR__")
      end
      old_error(msg)
   end
   
   local success, err = pcall(operation_func)
   _G.error = old_error
   
   if success then
      test_fail(message or "Expected 'unknown object' error but operation succeeded")
   elseif not error_caught and not string.find(err, "__EXPECTED_UNKNOWN_OBJECT_ERROR__") then
      -- Re-throw unexpected errors
      error(err)
   end
   -- If we get here, the expected error was caught successfully
end

-- Custom assert for testing object count
function assert_obj_count(loc, expected_count, message)
   test_helper()
   
   local actual_count = loc._obj_count()
   if actual_count == nil then
      test_fail(message or "Object count function returned nil")
   elseif actual_count ~= expected_count then
      local error_msg = message or ("Expected " .. tostring(expected_count) .. " objects, got " .. tostring(actual_count))
      test_fail(error_msg)
   end
end

-- Custom assert for testing bbox values
function assert_bbox(loc, obj, expected_x, expected_y, expected_w, expected_h, message)
   test_helper()
   
   local x, y, w, h = loc.get_bbox(obj)
   if x == nil or y == nil or w == nil or h == nil then
      test_fail(message or "Expected bbox values but got nil - object may not exist")
   elseif x ~= expected_x or y ~= expected_y or w ~= expected_w or h ~= expected_h then
      local expected_str = tostring(expected_x) .. "," .. tostring(expected_y) .. "," .. tostring(expected_w) .. "," .. tostring(expected_h)
      local actual_str = tostring(x) .. "," .. tostring(y) .. "," .. tostring(w) .. "," .. tostring(h)
      local error_msg = message or ("Expected bbox (" .. expected_str .. "), got (" .. actual_str .. ")")
      test_fail(error_msg)
   end
end

-- Custom assert for testing query results contain specific object
function assert_query_contains(results, obj, message)
   test_helper()
   
   if results == nil then
      test_fail(message or "Query results are nil")
      return
   end
   
   if not results[obj] then
      local obj_name = (obj and obj.id) and obj.id or "unknown"
      test_fail(message or ("Expected query results to contain object " .. obj_name))
   end
end

-- Custom assert for testing query result count
function assert_query_count(results, expected_count, message)
   test_helper()
   
   if results == nil then
      test_fail(message or "Query results are nil")
      return
   end
   
   local actual_count = 0
   for _ in pairs(results) do
      actual_count = actual_count + 1
   end
   
   if actual_count ~= expected_count then
      local error_msg = message or ("Expected " .. tostring(expected_count) .. " objects in query results, got " .. tostring(actual_count))
      test_fail(error_msg)
   end
end

-- Custom assert for testing any error (not just unknown object)
function assert_error(operation_func, expected_error_text, message)
   test_helper()
   local error_caught = false
   local old_error = _G.error
   
   _G.error = function(msg)
      if not expected_error_text or string.find(msg, expected_error_text) then
         error_caught = true
         -- Use a custom error type that we can catch specifically
         error("__EXPECTED_ERROR__" .. (expected_error_text or ""))
      end
      old_error(msg)
   end
   
   local success, err = pcall(operation_func)
   _G.error = old_error
   
   if success then
      test_fail(message or ("Expected error '" .. (expected_error_text or "any") .. "' but operation succeeded"))
   elseif not error_caught and not string.find(err, "__EXPECTED_ERROR__") then
      -- Re-throw unexpected errors
      error(err)
   end
   -- If we get here, the expected error was caught successfully
end

-- Custom assert for testing type
function assert_type(expected_type, value, message)
   test_helper()
   local actual_type = type(value)
   if actual_type ~= expected_type then
      test_fail(message or ("Expected type '" .. expected_type .. "' but got '" .. actual_type .. "'"))
   end
end

-- Custom assert for testing not equal
function assert_ne(value1, value2, message)
   test_helper()
   if value1 == value2 then
      test_fail(message or ("Expected values to be different but both were: " .. tostring(value1)))
   end
end