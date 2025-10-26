--- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- Locustron: Picotron Userdata-Optimized Spatial Hash
-- Uses Picotron userdata for efficient bounding box storage

local locustron = function(size)
   size = size or 32
   local rows = {}

   -- Object ID System for userdata indexing
   local next_obj_id = 1
   local obj_to_id = {}
   local id_to_obj = {}
   local active_obj_count = 0

   local function get_obj_id(obj)
      local id = obj_to_id[obj]
      if not id then
         id = next_obj_id
         next_obj_id = next_obj_id + 1
         obj_to_id[obj] = id
         id_to_obj[id] = obj
         active_obj_count = active_obj_count + 1
      end
      return id
   end

   local function get_existing_obj_id(obj)
      return obj_to_id[obj]
   end

   -- Userdata Bounding Box Storage
   local MAX_OBJECTS = 10000
   local bbox_count = 0
   local bbox_data = userdata("f32", MAX_OBJECTS * 4)
   local bbox_map = {} -- obj_id -> bbox_index mapping

   -- Userdata Cell Storage System
   local MAX_CELLS = 5000 -- Maximum grid cells that can exist
   local MAX_CELL_CAPACITY = 100 -- Maximum objects per cell
   local cell_pool_size = 0
   local cell_pool = {}
   local cell_data = userdata("i32", MAX_CELLS * MAX_CELL_CAPACITY)
   local cell_counts = userdata("i32", MAX_CELLS) -- Track object count per cell
   local cell_map = {} -- Maps cell userdata to its index

   -- Query Result Storage - Use regular tables since we need to store object references
   local query_pool_size = 0
   local query_pool = {}
   
   -- Initialize query result pool with regular tables
   for i = 1, 20 do -- Pre-allocate some query result tables
      query_pool[i] = {}
   end
   query_pool_size = 20

   local function frompool_query()
      if query_pool_size > 0 then
         local result = query_pool[query_pool_size]
         query_pool_size = query_pool_size - 1
         return result
      end
      
      -- Allocate new query result table
      return {}
   end

   local function return_to_pool_query(result_table)
      if result_table then
         -- Clear the table for reuse
         for k in pairs(result_table) do
            result_table[k] = nil
         end
         query_pool_size = query_pool_size + 1
         query_pool[query_pool_size] = result_table
      end
   end

   local function frompool_cell()
      if cell_pool_size > 0 then
         local cell_idx = cell_pool[cell_pool_size]
         cell_pool_size = cell_pool_size - 1
         cell_counts[cell_idx] = 0 -- Reset count
         return cell_idx
      end
      
      -- Need to allocate new cell
      for i = 0, MAX_CELLS - 1 do
         if cell_counts[i] == -1 then -- -1 means unused
            cell_counts[i] = 0
            return i
         end
      end
      error("Maximum cell capacity reached")
   end

   local function return_to_pool_cell(cell_idx)
      if cell_idx then
         cell_counts[cell_idx] = -1 -- Mark as unused
         cell_pool_size = cell_pool_size + 1
         cell_pool[cell_pool_size] = cell_idx
      end
   end

   -- Cell manipulation functions
   local function cell_add_obj(cell_idx, obj_id)
      local count = cell_counts[cell_idx]
      if count >= MAX_CELL_CAPACITY then
         error("Cell capacity exceeded")
      end
      
      local base = cell_idx * MAX_CELL_CAPACITY
      cell_data[base + count] = obj_id
      cell_counts[cell_idx] = count + 1
   end

   local function cell_remove_obj(cell_idx, obj_id)
      local count = cell_counts[cell_idx]
      local base = cell_idx * MAX_CELL_CAPACITY
      
      -- Find and remove object
      for i = 0, count - 1 do
         if cell_data[base + i] == obj_id then
            -- Move last element to this position
            cell_data[base + i] = cell_data[base + count - 1]
            cell_counts[cell_idx] = count - 1
            return true
         end
      end
      return false
   end

   local function cell_is_empty(cell_idx)
      return cell_counts[cell_idx] == 0
   end

   local function cell_iterate(cell_idx, callback)
      local count = cell_counts[cell_idx]
      local base = cell_idx * MAX_CELL_CAPACITY
      for i = 0, count - 1 do
         callback(cell_data[base + i])
      end
   end

   -- Initialize cell counts to -1 (unused)
   for i = 0, MAX_CELLS - 1 do
      cell_counts[i] = -1
   end

   local function box2grid(x, y, w, h)
      local l = math.floor(x / size) + 1
      local t = math.floor(y / size) + 1
      local r = math.floor((x + w) / size) + 1
      local b = math.floor((y + h) / size) + 1
      return l, t, r, b
   end

   -- Optimized bounding box management with userdata
   local function store_bbox(obj, x, y, w, h)
      local obj_id = get_obj_id(obj)
      local index = bbox_map[obj_id]
      if not index then
         index = bbox_count
         bbox_count = bbox_count + 1
         bbox_map[obj_id] = index
      end

      local base = index * 4
      bbox_data[base] = x
      bbox_data[base + 1] = y
      bbox_data[base + 2] = w
      bbox_data[base + 3] = h
   end

   local function get_bbox(obj)
      local obj_id = get_existing_obj_id(obj)
      if not obj_id then return nil end
      local index = bbox_map[obj_id]
      if not index then return nil end
      local base = index * 4
      return bbox_data[base], bbox_data[base + 1],
         bbox_data[base + 2], bbox_data[base + 3]
   end

   local function remove_bbox(obj)
      local obj_id = get_existing_obj_id(obj)
      if not obj_id then return end

      bbox_map[obj_id] = nil
      obj_to_id[obj] = nil
      id_to_obj[obj_id] = nil
      active_obj_count = active_obj_count - 1
   end

   -- Specialized functions maintain same logic but use optimized storage
   local function add_to_cells(obj, l, t, r, b)
      local obj_id = get_obj_id(obj)
      local row, cell_idx
      for cy = t, b do
         if not rows[cy] then
            rows[cy] = {}
         end
         row = rows[cy]
         for cx = l, r do
            if not row[cx] then
               row[cx] = frompool_cell()
            end
            cell_add_obj(row[cx], obj_id)
         end
      end
   end

   local function del_from_cells(obj, l, t, r, b)
      local obj_id = get_existing_obj_id(obj)
      if not obj_id then return end

      local row, cell_idx
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell_idx = row[cx]
               if cell_idx then
                  cell_remove_obj(cell_idx, obj_id)
               end
            end
         end
      end
   end

   local function free_empty_cells(l, t, r, b)
      local row, cell_idx
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell_idx = row[cx]
               if cell_idx and cell_is_empty(cell_idx) then
                  row[cx] = nil
                  return_to_pool_cell(cell_idx)
               end
            end
            if not next(row) then
               rows[cy] = nil
            end
         end
      end
   end

   local function query_cells(result_table, l, t, r, b, filter)
      local row, cell_idx
      
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell_idx = row[cx]
               if cell_idx then
                  cell_iterate(cell_idx, function(obj_id)
                     local obj = id_to_obj[obj_id]
                     if obj and not result_table[obj] then
                        if not filter or filter(obj) then
                           result_table[obj] = true
                        end
                     end
                  end)
               end
            end
         end
      end
      
      return result_table
   end

   return {
      _bbox_data = bbox_data,
      _obj_count = function() return active_obj_count end,
      _box2grid = box2grid,
      _cell_pool_size = function() return cell_pool_size end,
      _query_pool_size = function() return query_pool_size end,
      _rows = rows,
      _size = size,

      add = function(obj, x, y, w, h)
         store_bbox(obj, x, y, w, h)
         add_to_cells(obj, box2grid(x, y, w, h))
         return obj
      end,

      del = function(obj)
         local x, y, w, h = get_bbox(obj)
         if not x then error("unknown object") end

         local l, t, r, b = box2grid(x, y, w, h)
         del_from_cells(obj, l, t, r, b)
         free_empty_cells(l, t, r, b)
         remove_bbox(obj)
         return obj
      end,

      update = function(obj, x, y, w, h)
         local old_x, old_y, old_w, old_h = get_bbox(obj)
         if not old_x then error("unknown object") end

         local l0, t0, r0, b0 = box2grid(old_x, old_y, old_w, old_h)
         local l1, t1, r1, b1 = box2grid(x, y, w, h)

         if l0 ~= l1 or t0 ~= t1 or r0 ~= r1 or b0 ~= b1 then
            del_from_cells(obj, l0, t0, r0, b0)
            add_to_cells(obj, l1, t1, r1, b1)
            free_empty_cells(l0, t0, r0, b0)
         end

         store_bbox(obj, x, y, w, h)
         return obj
      end,

      query = function(x, y, w, h, filter)
         local result = frompool_query()
         local l, t, r, b = box2grid(x, y, w, h)
         query_cells(result, l, t, r, b, filter)
         
         -- Set up metatable to automatically return table to pool when garbage collected
         local result_mt = {
            __gc = function()
               return_to_pool_query(result)
            end
         }
         
         setmetatable(result, result_mt)
         return result
      end,

      -- Debug information
      get_bbox = get_bbox,
      get_obj_id = get_existing_obj_id
   }
end

return locustron
