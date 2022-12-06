#!/usr/bin/env crystal

STDIN.each_line do |line|
  buffer = Array(Char).new(14) { |i| line[i] }
  used = buffer.to_set
  index = 14
  until used.size == 14
    buffer.shift
    buffer.push(line[index])
    index += 1
    used = buffer.to_set
  end
  puts index
end
