#!/usr/bin/env crystal

def hash(string : String) : UInt8
  value = 0_u8
  string.each_char do |char|
    value &+= char.ord
    value &*= 17
  end
  value
end

sequence = STDIN.gets || ""
steps = sequence.split(",")
sum = steps.sum(0_u64) { |step| hash(step) }
puts sum
