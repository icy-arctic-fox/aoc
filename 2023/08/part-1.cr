#!/usr/bin/env crystal

enum Direction : UInt8
  Left
  Right

  def self.from_char(char : Char) : self
    case char
    when 'L', 'l' then Left
    when 'R', 'r' then Right
    else               raise "Unrecognized direction '#{char}'"
    end
  end
end

struct Node
  getter name : String
  getter left : String
  getter right : String

  def initialize(@name, @left, @right)
  end
end

directions_str = STDIN.gets.not_nil!
directions = directions_str.chars.map do |char|
  Direction.from_char(char)
end

nodes = {} of String => Node
STDIN.each_line do |line|
  next if line.blank?

  match = line.match(/(\w+)\s*=\s*\((\w+),\s*(\w+)\)/)
  raise "Unrecognized line: #{line}" unless match

  name, left, right = match[1..]
  nodes[name] = Node.new(name, left, right)
end

current = nodes["AAA"]
destination = nodes["ZZZ"]

steps = directions.cycle.each_with_index do |dir, i|
  break i if current == destination

  target = case dir
           in .left?  then current.left
           in .right? then current.right
           end

  current = nodes[target]
end
puts steps
