#!/usr/bin/env crystal

require "bit_array"

private def lower_neighbor?(x, y, w, h, map)
  v = map[y][x]
  case {x, y}
  when {0, 0} # Top-left
    map[0][1] <= v || map[1][0] <= v
  when {0, h - 1} # Bottom-left
    map[h - 2][0] <= v || map[h - 1][1] <= v
  when {w - 1, 0} # Top-right
    map[0][w - 2] <= v || map[1][w - 1] <= v
  when {w - 1, h - 1} # Bottom-right
    map[h - 1][w - 2] <= v || map[h - 2][w - 1] <= v
  when {_, 0} # Top
    map[0][x - 1] <= v || map[0][x + 1] <= v || map[1][x] <= v
  when {0, _} # Left
    map[y - 1][0] <= v || map[y + 1][0] <= v || map[y][1] <= v
  when {w - 1, _} # Right
    map[y - 1][w - 1] <= v || map[y + 1][w - 1] <= v || map[y][w - 2] <= v
  when {_, h - 1} # Bottom
    map[h - 1][x - 1] <= v || map[h - 1][x + 1] <= v || map[h - 2][x] <= v
  else
    map[y - 1][x] <= v || map[y + 1][x] <= v || map[y][x - 1] <= v || map[y][x + 1] <= v
  end
end

map = Array(Array(Int32)).new

STDIN.each_line(chomp: true) do |line|
  map << line.chars.map(&.to_i)
end

w = map.first.size
h = map.size
remaining = BitArray.new(w * h, true)

change = true
while change
  change = false
  remaining.each_with_index do |flag, index|
    next unless flag

    y, x = index.divmod(w)
    if lower_neighbor?(x, y, w, h, map)
      remaining[index] = false
      change = true
    end
  end
end

# remaining.each_with_index do |flag, index|
#   y, x = index.divmod(w)
#   v = map[y][x]
#   puts if x.zero?
#   if flag
#     print("*#{v}")
#   else
#     print(" #{v}")
#   end
# end
# puts

values = [] of Int32
remaining.each_with_index do |flag, index|
  next unless flag

  y, x = index.divmod(w)
  values << map[y][x]
end

puts values.sum + values.size
