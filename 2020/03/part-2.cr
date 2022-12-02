#!/usr/bin/env crystal

X_DIFF = [1, 3, 5, 7, 1]
Y_DIFF = [1, 1, 1, 1, 2]

x_pos = X_DIFF.map { 0 }
y_off = Y_DIFF.map { 0 }
count = X_DIFF.map { 0_u64 }

STDIN.each_line do |line|
  count.each_index do |i|
    y = y_off[i]
    y_off[i] = (y + 1) % Y_DIFF[i]
    next unless y == 0

    x = x_pos[i]
    tree = line[x] == '#'
    count[i] += 1 if tree
    x_pos[i] = (x + X_DIFF[i]) % line.size
  end
end
puts count.product
