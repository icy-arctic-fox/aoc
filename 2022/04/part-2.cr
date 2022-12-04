#!/usr/bin/env crystal

def parse_range(string)
  b, e = string.split('-', 2)
  Range.new(b.to_i, e.to_i)
end

count = STDIN.each_line.count do |line|
  first, second = line.split(',', 2)
  first = parse_range(first)
  second = parse_range(second)
  first.includes?(second.begin) || first.includes?(second.end) ||
    second.includes?(first.begin) || second.includes?(first.end)
end
puts count
