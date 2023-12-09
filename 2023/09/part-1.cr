#!/usr/bin/env crystal

def extrapolate(nums : Array(Int)) : Int
  return 0 if nums.all? &.zero?

  diff = nums.each_cons_pair.map { |a, b| b - a }.to_a
  nums.last + extrapolate(diff)
end

sum = STDIN.each_line.sum do |line|
  nums = line.split.map &.to_i64
  extrapolate(nums)
end
puts sum
