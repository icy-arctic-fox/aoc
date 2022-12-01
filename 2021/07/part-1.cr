#!/usr/bin/env crystal

positions = STDIN.gets(chomp: true).try(&.split(',').map(&.to_i))
raise "Missing positions" unless positions

min = positions.min
max = positions.max

puts (min..max).min_of do |target|
  positions.sum { |position| (position - target).abs }
end
