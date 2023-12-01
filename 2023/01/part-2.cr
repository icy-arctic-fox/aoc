#!/usr/bin/env crystal

DIGITS = %w[one two three four five six seven eight nine ten]

def each_digit(& : String, Int32 -> _)
  DIGITS.each_with_index(1) do |digit, i|
    yield digit, i
  end
  ('1'..'9').each_with_index(1) do |digit, i|
    yield digit.to_s, i
  end
end

def find_first(string)
  found = 0
  position = string.size
  each_digit do |digit, i|
    if (index = string.index(digit)) && index < position
      found = i
      position = index
    end
  end
  raise "NOT FOUND" if found.zero?
  found
end

def find_last(string)
  found = 0
  position = -1
  each_digit do |digit, i|
    if (index = string.rindex(digit)) && index > position
      found = i
      position = index
    end
  end
  raise "NOT FOUND" if found.zero?
  found
end

answer = STDIN.each_line.sum do |line|
  tens = find_first(line)
  ones = find_last(line)
  (tens * 10 + ones).tap { |v| STDERR.puts "#{v} - #{line}" }
end
puts answer
