#!/usr/bin/env crystal

require "bit_array"

def char_item(c : Char)
  case c
  when .ascii_lowercase? then c.ord - 'a'.ord
  when .ascii_uppercase? then c.ord - 'A'.ord + 26
  else                        raise "Invalid character '#{c}'"
  end
end

def inventory(line)
  size = line.size // 2
  compartment = BitArray.new(52)
  line.each_char_with_index do |c, i|
    item = char_item(c)
    if i < size
      compartment[item] = true
    else
      return item + 1 if compartment[item]
    end
  end
  0
end

sum = STDIN.each_line.sum do |line|
  inventory(line)
end
puts sum
