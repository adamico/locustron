---@diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- Picotron Userdata-Optimized Spatial Hash
-- Uses Picotron userdata for efficient bounding box storage

local locus_optimized = function(size)
   size = size or 32
   local rows, pool = {}, {}
   
   -- Object ID System for userdata indexing
   local next_obj_id = 1
   local obj_to_id = {}
   local id_to_obj = {}
   
   local function get_obj_id(obj)
      local id = obj_to_id[obj]
      if not id then
         id = next_obj_id
         next_obj_id = next_obj_id + 1
         obj_to_id[obj] = id
         id_to_obj[id] = obj
      end
      return id
   end
   
   -- Userdata Bounding Box Storage
   local MAX_OBJECTS = 10000
   local bbox_count = 0
   local bbox_data = userdata("f32", MAX_OBJECTS * 4)
   local bbox_map = {} -- obj_id -> bbox_index mapping
   
   local function frompool()
      local tbl = next(pool)
      if tbl then
         pool[tbl] = nil
         return tbl
      end
      return {}
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
      local obj_id = get_obj_id(obj)
      local index = bbox_map[obj_id]
      if not index then return nil end
      local base = index * 4
      return bbox_data[base], bbox_data[base + 1], 
             bbox_data[base + 2], bbox_data[base + 3]
   end
   
   local function remove_bbox(obj)
      local obj_id = obj_to_id[obj]
      if not obj_id then return end
      
      bbox_map[obj_id] = nil
      obj_to_id[obj] = nil
      id_to_obj[obj_id] = nil
   end
   
   -- Specialized functions maintain same logic but use optimized storage
   local function add_to_cells(obj, l, t, r, b)
      local obj_id = get_obj_id(obj)
      local row, cell
      for cy = t, b do
         if not rows[cy] then
            rows[cy] = frompool()
         end
         row = rows[cy]
         for cx = l, r do
            if not row[cx] then
               row[cx] = frompool()
            end
            row[cx][obj_id] = true -- Use object ID instead of object reference
         end
      end
   end
   
   local function del_from_cells(obj, l, t, r, b)
      local obj_id = obj_to_id[obj]
      if not obj_id then return end
      
      local row, cell
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell = row[cx]
               if cell then
                  cell[obj_id] = nil
               end
            end
         end
      end
   end
   
   local function free_empty_cells(l, t, r, b)
      local row, cell
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell = row[cx]
               if cell and not next(cell) then
                  row[cx], pool[cell] = nil, true
               end
            end
            if not next(row) then
               rows[cy], pool[row] = nil, true
            end
         end
      end
   end
   
   local function query_cells(result, l, t, r, b, filter)
      local row, cell
      for cy = t, b do
         row = rows[cy]
         if row then
            for cx = l, r do
               cell = row[cx]
               if cell then
                  for obj_id in pairs(cell) do
                     local obj = id_to_obj[obj_id]
                     if obj and not result[obj] then
                        if not filter or filter(obj) then
                           result[obj] = true
                        end
                     end
                  end
               end
            end
         end
      end
   end
   
   return {
      _bbox_data = bbox_data,
      _obj_count = function() return bbox_count end,
      _box2grid = box2grid,
      _pool = pool,
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
         local res = frompool()
         local l, t, r, b = box2grid(x, y, w, h)
         query_cells(res, l, t, r, b, filter)
         return res
      end,
      
      -- Debug information
      get_bbox = get_bbox,
      get_obj_id = get_obj_id
   }
end

return locus_optimized