-- An implementation of QuickSort which does not allocate new tables.
-- by @ablebody https://www.lexaloffle.com/bbs/?uid=93379
-- and modified by @kimiyoribaka https://www.lexaloffle.com/bbs/?uid=45608
-- Mutates the provided table.
local function sort(arr, comp)
   local insertion_sort, quick_sort
   if comp then
      insertion_sort = function(min, max)
         for i = min + 1, max do
            for j = i, min + 1, -1 do
               local item, other = arr[j], arr[j - 1]
               if comp(other, item) then break end
               arr[j], arr[j - 1] = other, item
            end
         end
      end

      quick_sort = function(min, max)
         if min >= max then
            return
         end

         local pivot
         local pivot_i = math.floor((max + min) / 2)
         pivot = arr[pivot_i]

         local first = arr[min]
         local last = arr[max]

         if comp(pivot, first) then
            arr[min], arr[pivot_i] = arr[pivot_i], arr[min]
            first, pivot = pivot, first
         end
         if comp(last, pivot) then
            arr[pivot_i], arr[max] = arr[max], arr[pivot_i]
            pivot = last
         end
         if comp(pivot, first) then
            arr[min], arr[pivot_i] = arr[pivot_i], arr[min]
            pivot = first
         end

         if max - min < 3 then return end

         local low, high = min + 1, max - 1
         while true do
            while low < high and comp(arr[low], pivot) do
               low = low + 1
            end
            while low < high and comp(pivot, arr[high]) do
               high = high - 1
            end
            if low >= high then break end

            arr[low], arr[high] = arr[high], arr[low]
            low = low + 1
            high = high - 1
         end

         local algo = high - min < 8 and insertion_sort or quick_sort
         algo(min, high)
         algo = max - low < 8 and insertion_sort or quick_sort
         algo(low, max)
      end
   else
      insertion_sort = function(min, max)
         for i = min + 1, max do
            for j = i, min + 1, -1 do
               local item, other = arr[j], arr[j - 1]
               if other < item then break end
               arr[j], arr[j - 1] = other, item
            end
         end
      end

      quick_sort = function(min, max)
         if min >= max then
            return
         end

         local pivot
         local pivot_i = math.floor((max + min) / 2)
         pivot = arr[pivot_i]

         local first = arr[min]
         local last = arr[max]

         if first >= pivot then
            arr[min], arr[pivot_i] = arr[pivot_i], arr[min]
            first, pivot = pivot, first
         end
         if pivot >= last then
            arr[pivot_i], arr[max] = arr[max], arr[pivot_i]
            pivot = last
         end
         if first >= pivot then
            arr[min], arr[pivot_i] = arr[pivot_i], arr[min]
            pivot = first
         end

         if max - min < 3 then return end

         local low, high = min + 1, max - 1
         while true do
            while low < high and arr[low] < pivot do
               low = low + 1
            end
            while low < high and arr[high] >= pivot do
               high = high - 1
            end
            if low >= high then break end

            arr[low], arr[high] = arr[high], arr[low]
            low = low + 1
            high = high - 1
         end

         local algo = high - min < 8 and insertion_sort or quick_sort
         algo(min, high)
         algo = max - low < 8 and insertion_sort or quick_sort
         algo(low, max)
      end
   end
   local algo = #arr <= 8 and insertion_sort or quick_sort
   algo(1, #arr)
end

return sort