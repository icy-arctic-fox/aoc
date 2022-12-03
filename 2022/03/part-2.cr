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
  BitArray.new(52).tap do |rucksack|
    line.each_char_with_index do |c, i|
      item = char_item(c)
      rucksack[item] = true
    end
  end
end

sum = STDIN.each_line.each_slice(3, reuse: true).sum do |group|
  rucksacks = group.map { |elf| inventory(elf) }
  52.times.index! do |i|
    rucksacks.all? &.[i]
  end + 1
end
puts sum
