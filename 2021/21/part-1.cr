#!/usr/bin/env crystal

SIDES =  100
BOARD =   10
SCORE = 1000

positions = STDIN.each_line(chomp: true).map do |line|
  m = line.match(/\d+$/)
  raise "Missing player position" unless m

  m[0].to_i
end.to_a

rolls = 0
die = 1
scores = Array.new(positions.size, 0)

loop do
  positions.each_with_index do |pos, player|
    move = 0
    3.times do
      move += die
      die += 1
      die = 1 if die > SIDES
      rolls += 1
    end

    pos = (pos + move - 1) % BOARD + 1
    positions[player] = pos
    scores[player] += pos

    break if scores[player] >= SCORE
  end
  break if scores.any?(&.>=(SCORE))
end

puts rolls * scores.min
