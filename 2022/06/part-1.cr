#!/usr/bin/env crystal

STDIN.each_line do |line|
  buffer = Array(Char).new(4) { |i| line[i] }
  used = buffer.to_set
  index = 4
  until used.size == 4
    buffer.shift
    buffer.push(line[index])
    index += 1
    used = buffer.to_set
  end
  puts index
end
