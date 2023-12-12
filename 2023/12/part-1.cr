#!/usr/bin/env crystal

enum Cell
  Unmarked
  Marked
  Unknown

  def self.from_char(char : Char) : self
    case char
    when '.' then Unmarked
    when '#' then Marked
    when '?' then Unknown
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .unmarked? then '.'
    in .marked?   then '#'
    in .unknown?  then '?'
    end
  end
end

class Puzzle
  def initialize(@cells : Array(Cell), @hints : Array(Int32))
  end

  def self.parse(line : String) : self
    cells, hints = line.split
    cells = cells.chars.map { |char| Cell.from_char(char) }
    hints = hints.split(',').map &.to_i
    new(cells, hints)
  end

  def each_combination(&)
    unknown_count = @cells.count(Cell::Unknown)
    combinations = 2 ** unknown_count
    combinations.times do |i|
      j = 0
      cells = @cells.map do |cell|
        next cell unless cell.unknown?
        bit = i.bit(j)
        j += 1
        bit.zero? ? Cell::Unmarked : Cell::Marked
      end
      yield cells
    end
  end

  def each_valid_combination(&)
    each_combination do |cells|
      marked = cells.chunk(&.itself).select(&.first.marked?).map(&.last.size).to_a
      yield cells if marked == @hints
    end
  end

  def valid_combinations
    count = 0
    each_valid_combination { count += 1 }
    count
  end

  def to_s(io : IO) : Nil
    @cells.each do |cell|
      io << cell.to_char
    end
    io << ' '
    @hints.join(io, ',')
  end
end

sum = STDIN.each_line.sum do |line|
  puzzle = Puzzle.parse(line)
  puzzle.valid_combinations
end
puts sum
