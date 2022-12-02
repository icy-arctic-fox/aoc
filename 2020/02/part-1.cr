#!/usr/bin/env crystal

count = STDIN.each_line.count do |line|
  raise "Invalid line" unless m = line.match(/(\d+)-(\d+)\s+(.)\s*:\s*(.*)/)
  min, max, char, password = m.captures.map &.not_nil!
  min = min.to_i
  max = max.to_i
  password.count(char).in?(min..max)
end
puts count
