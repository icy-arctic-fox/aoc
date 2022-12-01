#!/usr/bin/env crystal

positions = STDIN.gets(chomp: true).try(&.split(',').map(&.to_i))
raise "Missing positions" unless positions

min = positions.min
max = positions.max

def gauss(x)
  (x * (x + 1)) // 2
end

puts (min..max).min_of do |target|
  positions.sum { |position| gauss((position - target).abs) }
end
