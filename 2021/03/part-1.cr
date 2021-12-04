zeroes = StaticArray(Int32, 16).new(0)
ones = StaticArray(Int32, 16).new(0)
length = 0

STDIN.each_line(chomp: true) do |line|
  length = line.size - 1
  line.each_char.each_with_index do |char, index|
    case char
    when '0' then zeroes[index] += 1
    when '1' then ones[index] += 1
    end
  end
end

gamma = 0
epsilon = 0

zeroes.zip(ones).each_with_index do |(zero, one), index|
  if one > zero
    gamma |= 1 << (length - index)
  elsif zero > one
    epsilon |= 1 << (length - index)
  end
end

puts gamma * epsilon
