#!/usr/bin/env crystal

max = STDIN.each_line.max_of do |line|
  row = 128
  col = 8

  half = row // 2
  7.times do |i|
    row -= half if line[i] == 'F'
    half //= 2
  end

  half = col // 2
  3.times do |i|
    col -= half if line[i + 7] == 'L'
    half //= 2
  end

  (row - 1) * 8 + (col - 1)
end
puts max
