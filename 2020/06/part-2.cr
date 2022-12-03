#!/usr/bin/env crystal

require "bit_array"

def count_group(group)
  26.times.count do |i|
    group.all? &.[i]
  end
end

group = [] of BitArray

sum = STDIN.each_line.sum do |line|
  if line.empty?
    count_group(group).tap { group.clear }
  else
    answers = BitArray.new(26)
    group << answers
    line.each_char do |char|
      index = char.ord - 'a'.ord
      answers[index] = true
    end
    0
  end
end
sum += count_group(group)
puts sum
