#!/usr/bin/env crystal

size = ARGV.fetch(0, 25).to_i
values = STDIN.each_line.map(&.to_i64).first(size).to_a
STDIN.each_line do |line|
  value = line.to_i64
  if values.each_combination(2, reuse: true).any? { |(a, b)| a + b == value }
    values.shift
    values.push(value)
  else
    puts line
    break
  end
end
