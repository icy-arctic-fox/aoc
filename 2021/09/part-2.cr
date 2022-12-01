#!/usr/bin/env crystal

require "bit_array"

private def neighbors(x, y, w, h)
  case {x, y}
  when {0, 0}         then [{1, 0}, {0, 1}]                             # Top-left
  when {0, h - 1}     then [{0, h - 2}, {1, h - 1}]                     # Bottom-left
  when {w - 1, 0}     then [{w - 2, 0}, {w - 1, 1}]                     # Top-right
  when {w - 1, h - 1} then [{w - 2, h - 1}, {w - 1, h - 2}]             # Bottom-right
  when {_, 0}         then [{x - 1, 0}, {x + 1, 0}, {x, 1}]             # Top
  when {0, _}         then [{0, y - 1}, {0, y + 1}, {1, y}]             # Left
  when {w - 1, _}     then [{w - 1, y - 1}, {w - 1, y + 1}, {w - 2, y}] # Right
  when {_, h - 1}     then [{x - 1, h - 1}, {x + 1, h - 1}, {x, h - 2}] # Bottom
  else                     [{x, y - 1}, {x, y + 1}, {x - 1, y}, {x + 1, y}]
  end
end

private def lower_neighbor?(x, y, w, h, map)
  v = map[y][x]
  neighbors(x, y, w, h).any? { |(x2, y2)| map[y2][x2] <= v }
end

private def sink(map)
  w = map.first.size
  h = map.size

  filter = BitArray.new(w * h, true)

  changed = true
  while changed
    changed = false
    filter.each_with_index do |flag, index|
      next unless flag

      y, x = index.divmod(w)
      if yield(x, y, w, h)
        filter[index] = false
        changed = true
      end
    end
  end

  filter
end

private def expand(seed, map)
  w = map.first.size
  h = map.size

  points = Set(Tuple(Int32, Int32)).new
  points.add(seed)

  changed = true
  while changed
    changed = false

    new_points = points.flat_map do |(x, y)|
      v = map[y][x]
      neighbors(x, y, w, h).select do |(x2, y2)|
        u = map[y2][x2]
        u < 9 && u > v
      end
    end.to_set

    merged = new_points | points
    changed = merged != points
    points = merged
  end

  points
end

map = Array(Array(Int32)).new

STDIN.each_line(chomp: true) do |line|
  map << line.chars.map(&.to_i)
end

low_points = sink(map) { |x, y, w, h| lower_neighbor?(x, y, w, h, map) }
w = map.first.size

points = low_points.each_with_index.compact_map do |flag, index|
  next unless flag

  y, x = index.divmod(w)
  {x, y}
end

basins = points.map { |point| expand(point, map) }
puts basins.map(&.size).to_a.sort!.last(3).product
