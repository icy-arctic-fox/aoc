#!/usr/bin/env crystal

require "bit_array"

answers = BitArray.new(26)
sum = STDIN.each_line.sum do |line|
  if line.empty?
    answers.count(true).tap { answers.fill(false) }
  else
    line.each_char do |char|
      index = char.ord - 'a'.ord
      answers[index] = true
    end
    0
  end
end
sum += answers.count(true)
puts sum
