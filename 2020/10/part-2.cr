#!/usr/bin/env crystal

def count_paths(i, adapters, cache = {} of Int32 => Int64) : Int64
  return 0_i64 if i >= adapters.size
  return 1_i64 if i == adapters.size - 1

  cache.fetch(i) do
    j = {i + 4, adapters.size}.min
    sum = ((i + 1)...j).sum(0_i64) do |k|
      adapters[k] - adapters[i] <= 3 ? count_paths(k, adapters, cache) : 0
    end
    cache[i] = sum
  end
end

adapters = STDIN.each_line.map(&.to_i).to_a
adapters += [0, adapters.max + 3]
adapters.sort!
puts count_paths(0, adapters)
