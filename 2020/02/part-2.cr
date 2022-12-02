#!/usr/bin/env crystal

count = STDIN.each_line.count do |line|
  raise "Invalid line" unless m = line.match(/(\d+)-(\d+)\s+(.)\s*:\s*(.*)/)
  a, b, char, password = m.captures.map &.not_nil!
  a = a.to_i - 1
  b = b.to_i - 1
  char = char[0]
  (password[a] == char) ^ (password[b] == char)
end
puts count
