#!/usr/bin/env crystal

enum Result
  Loss = 0
  Draw = 3
  Win  = 6
end

enum Shape
  Rock     = 1
  Paper    = 2
  Scissors = 3

  def self.from_opponent_char(c : Char)
    case c
    when 'A' then Rock
    when 'B' then Paper
    when 'C' then Scissors
    else          raise "Invalid opponent character '#{c}'"
    end
  end

  def self.from_player_char(c : Char)
    case c
    when 'X' then Rock
    when 'Y' then Paper
    when 'Z' then Scissors
    else          raise "Invalid player character '#{c}'"
    end
  end

  def opponent
    case self
    in .rock?     then 'A'
    in .paper?    then 'B'
    in .scissors? then 'C'
    end
  end

  def player
    case self
    in .rock?     then 'X'
    in .paper?    then 'Y'
    in .scissors? then 'Z'
    end
  end

  def score(other : self)
    return Result::Draw if self == other

    case {self, other}
    when {Rock, Paper}     then Result::Win
    when {Paper, Rock}     then Result::Loss
    when {Rock, Scissors}  then Result::Loss
    when {Scissors, Rock}  then Result::Win
    when {Paper, Scissors} then Result::Win
    when {Scissors, Paper} then Result::Loss
    else                        raise "Unknown combination #{self} v #{other}"
    end
  end
end

score = STDIN.each_line.sum do |line|
  opponent, player = line.split(2).map &.[0]
  opponent = Shape.from_opponent_char(opponent)
  player = Shape.from_player_char(player)
  player.value + opponent.score(player).value
end
puts score
