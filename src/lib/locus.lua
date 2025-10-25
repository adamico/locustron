---@diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
local locus = function(size)
  size=size or 32
  local rows,boxes,pool={},{},{}

  local function frompool()
    local tbl=next(pool)
    if tbl then
      pool[tbl]=nil
      return tbl
    end
    return {}
  end

  local function box2grid(x,y,w,h)
    return (x//size)+1, --l
      (y//size)+1,      --t
      ((x+w)//size)+1,  --r
      ((y+h)//size)+1   --b
  end

  -- Specialized functions for better performance
  local function add_to_cells(obj, l, t, r, b)
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
        row[cx][obj] = true
      end
    end
  end

  local function del_from_cells(obj, l, t, r, b)
    local row, cell
    for cy = t, b do
      row = rows[cy]
      if row then
        for cx = l, r do
          cell = row[cx]
          if cell then
            cell[obj] = nil
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
            for obj in pairs(cell) do
              if not result[obj] then
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
    _boxes=boxes,_box2grid=box2grid,_pool=pool,_rows=rows,_size=size,

    add=function(obj,x,y,w,h)
      local box=frompool()
      box[1],box[2],box[3],box[4]=x,y,w,h
      boxes[obj]=box
      add_to_cells(obj,box2grid(x,y,w,h))
      return obj
    end,

    del=function(obj)
      local box=assert(boxes[obj],"unknown object")
      local l,t,r,b=box2grid(box[1],box[2],box[3],box[4])
      del_from_cells(obj,l,t,r,b)
      free_empty_cells(l,t,r,b)
      box[1],box[2],box[3],box[4]=nil,nil,nil,nil
      boxes[obj],pool[box]=nil,true
      return obj
    end,

    update=function(obj,x,y,w,h)
      local box=assert(boxes[obj],"unknown object")
      local l0,t0,r0,b0=box2grid(box[1],box[2],box[3],box[4])
      local l1,t1,r1,b1=box2grid(x,y,w,h)
      if l0~=l1 or t0~=t1 or r0~=r1 or b0~=b1 then
        del_from_cells(obj,l0,t0,r0,b0)
        add_to_cells(obj,l1,t1,r1,b1)
        free_empty_cells(l0,t0,r0,b0)
      end
      box[1],box[2],box[3],box[4]=x,y,w,h
    end,

    query=function(x,y,w,h,filter)
      local res=frompool()
      local l,t,r,b=box2grid(x,y,w,h)
      query_cells(res,l,t,r,b,filter)
      return res
    end,
  }
end

return locus