#!/usr/bin/env crystal

X_DIFF = 3

x = 0

count = STDIN.each_line.count do |line|
  tree = line[x] == '#'
  x = (x + X_DIFF) % line.size
  tree
end
puts count
