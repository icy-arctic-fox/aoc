#!/usr/bin/env crystal

size = ARGV.fetch(0, 25).to_i
values = STDIN.each_line.map(&.to_i64).to_a
subset = values.first(size)

found = values.skip(size).each do |value|
  if subset.each_combination(2, reuse: true).any? { |(a, b)| a + b == value }
    subset.shift
    subset.push(value)
  else
    break value
  end
end
raise "Invalid value not found" unless found

first = 0
second = 0
sum = values.first

until sum == found
  if sum > found
    sum -= values[first]
    first += 1
  else
    second += 1
    sum += values[second]
  end
end
puts values[first..second].minmax.sum
