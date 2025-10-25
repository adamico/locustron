-- Alternative query_cells implementation without goto statements
-- This version uses early returns and continues in a more structured way

local function query_cells_alternative(result, l, t, r, b, filter)
  -- Fail fast: check if any rows exist in range
  local has_rows = false
  for cy = t, b do
    if rows[cy] then
      has_rows = true
      break
    end
  end
  
  if not has_rows then
    return -- Early return if no data to process
  end

  local row, cell
  for cy = t, b do
    row = rows[cy]
    if row then -- Only process existing rows
      for cx = l, r do
        cell = row[cx]
        if cell and next(cell) then -- Only process non-empty cells
          if filter then
            -- Filtered query path
            for obj in pairs(cell) do
              if not result[obj] then -- Skip already processed objects
                if filter(obj) then -- Apply filter
                  result[obj] = true
                end
              end
            end
          else
            -- Unfiltered query path (optimized)
            for obj in pairs(cell) do
              if not result[obj] then
                result[obj] = true
              end
            end
          end
        end
      end
    end
  end
end