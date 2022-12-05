#!/usr/bin/env crystal

stacks = [] of Array(Char)

STDIN.each_line do |line|
  break if line.empty?

  i = -1
  line.scan(/.(.)..?/) do |m|
    i += 1
    c = m[1][0]

    if i >= stacks.size
      stacks << [] of Char
    end
    next if c.whitespace?
    stacks[i] << c
  end
end

stacks = stacks.to_h do |stack|
  name = stack.pop
  {name, stack.reverse!}
end

STDIN.each_line do |line|
  m = line.match(/move (\d+) from (.) to (.)/)
  raise "Malformed instruction" unless m

  count = m[1].to_i
  src = m[2][0]
  dst = m[3][0]

  crates = stacks[src].pop(count)
  stacks[dst].concat(crates)
end

puts stacks.join { |_, v| v.last }
