horizontal = 0
depth = 0

STDIN.each_line do |line|
  direction, amount = line.strip.split.map(&.strip)
  amount = amount.to_i
  case direction
  when "forward" then horizontal += amount
  when "down"    then depth += amount
  when "up"      then depth -= amount
  end
end

puts horizontal * depth
