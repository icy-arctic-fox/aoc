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
    (@winning & @ours).size
  end
end

cards = STDIN.each_line.map do |line|
  Card.parse(line)
end.to_a
counts = Array.new(cards.size, 1)
cards.each_with_index do |card, i|
  score = card.score
  next if score.zero?
  (i + 1).step(to: i + score, by: 1) do |j|
    counts[j] += counts[i]
  end
end
sum = cards.zip(counts).sum do |card, count|
  card.score * count
end
puts sum + cards.size
