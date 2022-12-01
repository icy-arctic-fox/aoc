#!/usr/bin/env crystal

def count_bits(lines, index)
  zeroes = 0
  ones = 0

  lines.each do |line|
    case line[index]
    when '0' then zeroes += 1
    when '1' then ones += 1
    end
  end

  {zeroes, ones}
end

def compute(lines)
  length = lines.first.size

  keep = lines.dup
  length.times do |index|
    break if keep.size == 1

    zeroes, ones = count_bits(keep, index)

    char = yield(ones >= zeroes)
    keep.select! { |line| line[index] == char }
  end
  keep.first.to_i(2)
end

lines = STDIN.each_line(chomp: true).to_a
generator = compute(lines) { |flag| flag ? '1' : '0' }
scrubber = compute(lines) { |flag| flag ? '0' : '1' }

puts generator * scrubber
