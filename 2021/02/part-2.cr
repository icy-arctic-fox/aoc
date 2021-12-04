horizontal = 0
depth = 0
aim = 0

STDIN.each_line do |line|
  direction, amount = line.strip.split.map(&.strip)
  amount = amount.to_i
  case direction
  when "forward"
    horizontal += amount
    depth += aim * amount
  when "down" then aim += amount
  when "up"   then aim -= amount
  end
end

puts horizontal * depth
