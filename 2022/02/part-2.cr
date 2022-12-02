#!/usr/bin/env crystal

enum Result
  Loss = 0
  Draw = 3
  Win  = 6

  def self.from_char(c : Char)
    case c
    when 'X' then Loss
    when 'Y' then Draw
    when 'Z' then Win
    else          raise "Invalid character '#{c}'"
    end
  end

  def char
    case self
    in .loss? then 'X'
    in .draw? then 'Y'
    in .win?  then 'Z'
    end
  end
end

enum Shape
  Rock     = 1
  Paper    = 2
  Scissors = 3

  def self.from_char(c : Char)
    case c
    when 'A' then Rock
    when 'B' then Paper
    when 'C' then Scissors
    else          raise "Invalid character '#{c}'"
    end
  end

  def char
    case self
    in .rock?     then 'A'
    in .paper?    then 'B'
    in .scissors? then 'C'
    end
  end

  def play(result : Result)
    return self if result.draw?

    case {self, result}
    when {Rock, Result::Win}      then Paper
    when {Rock, Result::Loss}     then Scissors
    when {Paper, Result::Win}     then Scissors
    when {Paper, Result::Loss}    then Rock
    when {Scissors, Result::Win}  then Rock
    when {Scissors, Result::Loss} then Paper
    else                               raise "Unknown combination #{self} with #{result}"
    end
  end
end

score = STDIN.each_line.sum do |line|
  opponent, result = line.split(2).map &.[0]
  opponent = Shape.from_char(opponent)
  result = Result.from_char(result)
  result.value + opponent.play(result).value
end
puts score
