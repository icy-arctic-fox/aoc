#!/usr/bin/env crystal

def parse(line) : {String, Array({Int32, String})}
  outer, inner = line.split("contain", 2)
  raise "Failed to match" unless m = outer.match(/(.+) bag/)

  outer = m[1].strip
  inner = inner.scan(/(\d+) (.+?) bag/).map do |m|
    {m[1].to_i, m[2].strip}
  end
  {outer, inner}
end

def calculate(rules, bag) : Int32
  contents = rules[bag]
  1 + contents.sum { |(count, inner)| count * calculate(rules, inner) }
end

rules = STDIN.each_line.map { |line| parse(line) }.to_h
puts calculate(rules, "shiny gold") - 1
