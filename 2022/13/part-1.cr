#!/usr/bin/env crystal

require "json"
DEBUG = ARGV.shift? == "-d"

def parse_line(line)
  JSON.parse(line).as_a
end

def compare(left : Int, right : Int)
  puts "  - Compare #{left} vs #{right}" if DEBUG
  result = left <=> right
  puts "    - Left side is smaller" if DEBUG && result
  result
end

def compare(left : Int, right : JSON::Any)
  if right_int = right.as_i?
    compare(left, right_int)
  elsif right_array = right.as_a?
    compare_lists([left], right_array)
  else
    raise ArgumentError.new
  end
end

def compare(left : JSON::Any, right : Int)
  if left_int = left.as_i?
    compare(left_int, right)
  elsif left_array = left.as_a?
    compare_lists(left_array, [right])
  else
    raise ArgumentError.new
  end
end

def compare(left : JSON::Any, right : JSON::Any)
  left_int = left.as_i?
  left_array = left.as_a?
  right_int = right.as_i?
  right_array = right.as_a?

  if left_int && right_int
    compare(left_int, right_int)
  elsif left_array && right_array
    compare_lists(left_array, right_array)
  elsif left_int && right_array
    compare_lists([left_int], right_array)
  elsif left_array && right_int
    compare_lists(left_array, [right_int])
  else
    raise "Unexpected comparison between #{left} and #{right}"
  end
end

def compare_lists(left : Array, right : Array)
  left.zip?(right) do |l, r|
    unless r
      puts "Right side ran out of inputs, so inputs are not in the right order" if DEBUG
      return 1
    end
    result = compare(l, r)
    return result if result != 0
  end
  puts "Left side ran out of items, so inputs are in the right order" if DEBUG && left.size < right.size
  left.size <=> right.size
end

sum = STDIN.each_line.each_slice(3, reuse: true).with_index(1).sum do |(lines, index)|
  left = parse_line(lines[0])
  right = parse_line(lines[1])

  if DEBUG
    puts "== Pair #{index} =="
    puts "- Compare #{left} vs #{right}"
  end

  if compare_lists(left, right) <= 0
    puts "Left side is smaller for pair #{index}" if DEBUG
    index
  else
    puts "Right side is smaller for pair #{index}" if DEBUG
    0
  end
end
puts sum
