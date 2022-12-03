#!/usr/bin/env crystal

def parse(line) : {String, Array(String)}
  outer, inner = line.split("contain", 2)
  raise "Failed to match" unless m = outer.match(/(.+) bag/)

  outer = m[1].strip
  inner = inner.scan(/\d+ (.+?) bag/).map &.[1].strip
  {outer, inner}
end

def transpose(hash)
  hash.reduce({} of String => Array(String)) do |c, (outer, inner)|
    inner.each do |item|
      set = c[item] ||= [] of String
      set << outer
    end
    c
  end
end

rules = STDIN.each_line.map { |line| parse(line) }.to_h
containers = transpose(rules)

pending = containers["shiny gold"].dup
set = Set(String).new
until pending.empty?
  bag = pending.pop
  set << bag
  bags = containers[bag]?
  pending.concat(bags) if bags
end
puts set.size
