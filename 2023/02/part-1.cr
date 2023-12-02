#!/usr/bin/env crystal

POSSIBLE_RED   = 12
POSSIBLE_GREEN = 13
POSSIBLE_BLUE  = 14

record Blocks, red : Int32, green : Int32, blue : Int32 do
  def self.from_s(string) : self
    red = 0
    green = 0
    blue = 0
    color_strings = string.split(',')
    color_strings.each do |str|
      match = str.match(/(\d+)\s+(red|green|blue)/i)
      raise "Unrecognized block set string - #{str}" unless match

      amount = match[1].to_i
      case match[2].downcase
      when "red"   then red += amount
      when "green" then green += amount
      when "blue"  then blue += amount
      end
    end
    new(red, green, blue)
  end

  def possible?
    red <= POSSIBLE_RED && green <= POSSIBLE_GREEN && blue <= POSSIBLE_BLUE
  end
end

record Game, id : Int32, sets : Array(Blocks) do
  def self.from_s(string) : self
    match = string.match(/^Game\s+(\d+):/i)
    raise "Failed to match game string - #{string}" unless match

    id = match[1].to_i
    set_strings = string.delete_at(0, match[0].size).strip.split(';')
    sets = set_strings.map { |str| Blocks.from_s(str) }
    new(id, sets)
  end
end

games = STDIN.each_line.map { |line| Game.from_s(line) }
answer = games.sum do |game|
  if game.sets.all? &.possible?
    game.id
  else
    0
  end
end
puts answer
