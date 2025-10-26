--- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- Locustron 2D: Picotron 2D Userdata-Optimized Spatial Hash
-- Uses 2D userdata for direct indexing instead of manual base calculations

local locustron_2d = function(size)
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

   -- 2D Userdata Bounding Box Storage
   local MAX_OBJECTS = 10000
   local bbox_count = 0
   local bbox_data_2d = userdata("f64", MAX_OBJECTS, 4) -- 2D: [obj_id][coord] where coord = x,y,w,h
   local bbox_map = {} -- obj_id -> bbox_index mapping

   -- 2D Userdata Cell Storage System
   local MAX_CELLS = 5000 -- Maximum grid cells that can exist
   local MAX_CELL_CAPACITY = 100 -- Maximum objects per cell
   local cell_pool_size = 0
   local cell_pool = {}
   local cell_data_2d = userdata("i32", MAX_CELLS, MAX_CELL_CAPACITY) -- 2D: [cell_idx][obj_position]
   local cell_counts = userdata("i32", MAX_CELLS, 1) -- 2D for consistency: [cell_idx][0]
   local cell_map = {} -- Maps cell userdata to its index

   -- Query Result Storage - Use regular tables since we need to store object references
   local query_pool_size = 0
   local query_pool = {}
   
   -- Initialize query result pool with regular tables
   for i = 1, 20 do -- Pre-allocate some query result tables
      query_pool[query_pool_size + 1] = {}
      query_pool_size = query_pool_size + 1
   end

   local function get_from_pool_query()
      if query_pool_size > 0 then
         local result = query_pool[query_pool_size]
         query_pool_size = query_pool_size - 1
         -- Clear any existing data
         for k in pairs(result) do
            result[k] = nil
         end
         return result
      else
         return {} -- Create new if pool is empty
      end
   end

   local function return_to_pool_query(result_table)
      if query_pool_size < 50 then -- Limit pool size to prevent memory bloat
         query_pool_size = query_pool_size + 1
         query_pool[query_pool_size] = result_table
      end
   end

   local function get_from_pool_cell()
      if cell_pool_size > 0 then
         local cell_idx = cell_pool[cell_pool_size]
         cell_pool_size = cell_pool_size - 1
         -- Initialize cell count to 0
         cell_counts:set(cell_idx, 0, 0)
         return cell_idx
      end
      return nil
   end

   local function return_to_pool_cell(cell_idx)
      cell_pool_size = cell_pool_size + 1
      cell_pool[cell_pool_size] = cell_idx
   end

   local function new_cell()
      local cell_idx = get_from_pool_cell()
      if not cell_idx then
         local total_cells = 0
         for _ in pairs(cell_map) do
            total_cells = total_cells + 1
         end
         cell_idx = total_cells
         cell_map[cell_idx] = true
      end
      return cell_idx
   end

   -- 2D Userdata Cell Functions
   local function cell_add_obj(cell_idx, obj_id)
      local count = cell_counts:get(cell_idx, 0, 1)
      if count < MAX_CELL_CAPACITY then
         cell_data_2d:set(cell_idx, count, obj_id) -- 2D: direct indexing
         cell_counts:set(cell_idx, 0, count + 1)
      end
   end

   local function cell_remove_obj(cell_idx, obj_id)
      local count = cell_counts:get(cell_idx, 0, 1)
      for i = 0, count - 1 do
         if cell_data_2d:get(cell_idx, i, 1) == obj_id then -- 2D: direct indexing
            -- Move last object to fill the gap
            cell_data_2d:set(cell_idx, i, cell_data_2d:get(cell_idx, count - 1, 1)) -- 2D: direct indexing
            cell_counts:set(cell_idx, 0, count - 1)
            return
         end
      end
   end

   local function cell_is_empty(cell_idx)
      return cell_counts:get(cell_idx, 0, 1) == 0 -- 2D: direct indexing
   end

   local function cell_iterate(cell_idx, callback)
      local count = cell_counts:get(cell_idx, 0, 1) -- 2D: direct indexing
      for i = 0, count - 1 do
         callback(cell_data_2d:get(cell_idx, i, 1)) -- 2D: direct indexing
      end
   end

   -- 2D Userdata Bounding Box Functions
   local function store_bbox(obj_id, x, y, w, h)
      local bbox_idx = bbox_map[obj_id]
      if not bbox_idx then
         bbox_idx = bbox_count
         bbox_count = bbox_count + 1
         bbox_map[obj_id] = bbox_idx
      end
      
      -- Store using 2D indexing: [obj_id][coordinate]
      bbox_data_2d:set(bbox_idx, 0, x) -- x coordinate
      bbox_data_2d:set(bbox_idx, 1, y) -- y coordinate
      bbox_data_2d:set(bbox_idx, 2, w) -- width
      bbox_data_2d:set(bbox_idx, 3, h) -- height
   end

   local function get_bbox(obj_id)
      local bbox_idx = bbox_map[obj_id]
      if bbox_idx then
         -- Retrieve using 2D indexing: [obj_id][coordinate]
         return bbox_data_2d:get(bbox_idx, 0, 1), bbox_data_2d:get(bbox_idx, 1, 1),
                bbox_data_2d:get(bbox_idx, 2, 1), bbox_data_2d:get(bbox_idx, 3, 1)
      end
      return nil
   end

   local function free_bbox(obj_id)
      local bbox_idx = bbox_map[obj_id]
      if bbox_idx then
         bbox_map[obj_id] = nil
         -- Note: We don't compact the bbox array to avoid object ID invalidation
      end
   end

   local function get_cell(gx, gy)
      local row = rows[gy]
      if row then
         return row[gx]
      end
      return nil
   end

   local function set_cell(gx, gy, cell_idx)
      local row = rows[gy]
      if not row then
         row = {}
         rows[gy] = row
      end
      row[gx] = cell_idx
   end

   local function clear_cell(gx, gy)
      local row = rows[gy]
      if row then
         row[gx] = nil
         -- Clean up empty rows
         local has_cells = false
         for _ in pairs(row) do
            has_cells = true
            break
         end
         if not has_cells then
            rows[gy] = nil
         end
      end
   end

   local function add_to_cells(obj, obj_id, gx0, gy0, gx1, gy1)
      for gy = gy0, gy1 do
         for gx = gx0, gx1 do
            local cell_idx = get_cell(gx, gy)
            if not cell_idx then
               cell_idx = new_cell()
               set_cell(gx, gy, cell_idx)
            end
            cell_add_obj(cell_idx, obj_id)
         end
      end
   end

   local function remove_from_cells(obj, obj_id, gx0, gy0, gx1, gy1)
      for gy = gy0, gy1 do
         for gx = gx0, gx1 do
            local cell_idx = get_cell(gx, gy)
            if cell_idx then
               cell_remove_obj(cell_idx, obj_id)
               if cell_is_empty(cell_idx) then
                  return_to_pool_cell(cell_idx)
                  clear_cell(gx, gy)
               end
            end
         end
      end
   end

   -- Public API - identical to original locustron
   local function add(obj, x, y, w, h)
      if get_existing_obj_id(obj) then
         error("object already in spatial hash")
      end
      
      local obj_id = get_obj_id(obj)
      store_bbox(obj_id, x, y, w, h)
      
      local gx0, gy0 = x \ size, y \ size
      local gx1, gy1 = (x + w - 1) \ size, (y + h - 1) \ size
      
      add_to_cells(obj, obj_id, gx0, gy0, gx1, gy1)
   end

   local function del(obj)
      local obj_id = get_existing_obj_id(obj)
      if not obj_id then
         error("unknown object")
      end
      
      local x, y, w, h = get_bbox(obj_id)
      if not x then
         error("unknown object")
      end
      
      local gx0, gy0 = x \ size, y \ size
      local gx1, gy1 = (x + w - 1) \ size, (y + h - 1) \ size
      
      remove_from_cells(obj, obj_id, gx0, gy0, gx1, gy1)
      
      free_bbox(obj_id)
      obj_to_id[obj] = nil
      id_to_obj[obj_id] = nil
      active_obj_count = active_obj_count - 1
   end

   local function update(obj, x, y, w, h)
      local obj_id = get_existing_obj_id(obj)
      if not obj_id then
         error("unknown object")
      end
      
      local old_x, old_y, old_w, old_h = get_bbox(obj_id)
      if not old_x then
         error("unknown object")
      end
      
      local old_gx0, old_gy0 = old_x \ size, old_y \ size
      local old_gx1, old_gy1 = (old_x + old_w - 1) \ size, (old_y + old_h - 1) \ size
      
      local new_gx0, new_gy0 = x \ size, y \ size
      local new_gx1, new_gy1 = (x + w - 1) \ size, (y + h - 1) \ size
      
      -- Only update cells if grid position changed
      if old_gx0 ~= new_gx0 or old_gy0 ~= new_gy0 or old_gx1 ~= new_gx1 or old_gy1 ~= new_gy1 then
         remove_from_cells(obj, obj_id, old_gx0, old_gy0, old_gx1, old_gy1)
         add_to_cells(obj, obj_id, new_gx0, new_gy0, new_gx1, new_gy1)
      end
      
      store_bbox(obj_id, x, y, w, h)
   end

   local function query(x, y, w, h, filter_fn)
      local result = get_from_pool_query()
      
      local gx0, gy0 = x \ size, y \ size
      local gx1, gy1 = (x + w - 1) \ size, (y + h - 1) \ size
      
      for gy = gy0, gy1 do
         for gx = gx0, gx1 do
            local cell_idx = get_cell(gx, gy)
            if cell_idx then
               cell_iterate(cell_idx, function(obj_id)
                  local obj = id_to_obj[obj_id]
                  if obj and (not filter_fn or filter_fn(obj)) then
                     result[obj] = true -- Deduplicate automatically
                  end
               end)
            end
         end
      end
      
      return result
   end

   local function get_bbox_public(obj)
      local obj_id = get_existing_obj_id(obj)
      if obj_id then
         return get_bbox(obj_id)
      end
      return nil
   end

   local function get_obj_id_public(obj)
      return get_existing_obj_id(obj)
   end

   -- Return public API
   return {
      add = add,
      del = del,
      update = update,
      query = query,
      get_bbox = get_bbox_public,
      get_obj_id = get_obj_id_public,
      _size = size,
      _pool = function() return query_pool_size end,
      _cell_pool_size = function() return cell_pool_size end,
      _obj_count = function() return active_obj_count end,
      _bbox_count = function() return bbox_count end,
      _2d_version = true -- Marker to identify this as the 2D version
   }
end

return locustron_2d