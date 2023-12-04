#!/usr/bin/env crystal

class Card
  def initialize(@winning : Array(Int32), @ours : Array(Int32))
  end

  def self.parse(line : String) : self
    _, numbers = line.split(':', 2)
    winning, ours = numbers.split('|', 2)
    winning = winning.scan(/\d+/).map &.[0].to_i
    ours = ours.scan(/\d+/).map &.[0].to_i
    new(winning, ours)
  end

  def score
    matching = (@winning & @ours).size
    return 0 if matching.zero?
    1 << (matching - 1)
  end
end

sum = STDIN.each_line.sum do |line|
  Card.parse(line).score
end
puts sum
