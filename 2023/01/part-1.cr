#!/usr/bin/env crystal

answer = STDIN.each_line.sum do |line|
  digits = line.chars.select &.ascii_number?
  tens = digits.first.to_i
  ones = digits.last.to_i
  tens * 10 + ones
end
puts answer
