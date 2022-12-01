calories = [0]

STDIN.each_line do |line|
  if line.empty?
    calories << 0
  else
    calories[-1] += line.to_i
  end
end

puts calories.sort!.last(3).sum
