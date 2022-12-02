#!/usr/bin/env crystal

require "bit_array"

seats = BitArray.new(128 * 8)

STDIN.each_line do |line|
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

  id = (row - 1) * 8 + (col - 1)
  seats[id] = true
end

iter = seats.each_with_index.skip_while { |(b, i)| !b }
iter.each_cons(3, reuse: true) do |set|
  s1, s2, s3 = set.map &.not_nil!
  break puts s2[1] if s1[0] && !s2[0] && s3[0]
end
