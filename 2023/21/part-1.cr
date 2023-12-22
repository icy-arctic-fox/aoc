#!/usr/bin/env crystal

enum Cell
  Empty
  Rock

  def self.from_char(char : Char) : self
    case char
    when '.' then Empty
    when '#' then Rock
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char
    case self
    in .empty? then '.'
    in .rock?  then '#'
    end
  end
end

class Grid
  getter start : {Int32, Int32}

  def initialize(@grid : Array(Array(Cell)), @start)
  end

  def self.from_io(io : IO) : self
    start = nil
    grid = io.each_line.map_with_index do |line, y|
      line.chars.map_with_index do |char, x|
        if char == 'S'
          start = {x, y}
          Cell::Empty
        else
          Cell.from_char(char)
        end
      end
    end.to_a
    new(grid, start || raise "Failed to find starting position")
  end

  def width
    @grid[0].size
  end

  def height
    @grid.size
  end

  def [](x, y)
    @grid[y][x]
  end

  def each_neighbor(x, y, &)
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1
  end

  def each_valid_neighbor(x, y, &)
    each_neighbor(x, y) do |nx, ny|
      yield nx, ny if (0 <= nx < width) && (0 <= ny < height)
    end
  end

  def each_empty_neighbor(x, y, &)
    each_valid_neighbor(x, y) do |nx, ny|
      yield nx, ny if self[nx, ny].empty?
    end
  end

  def to_s(io : IO, marks : Enumerable({Int32, Int32})) : Nil
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        char = if {x, y} == start
                 'S'
               elsif marks.includes?({x, y})
                 'O'
               else
                 cell.to_char
               end
        io << char
      end
      io.puts
    end
  end
end

grid = Grid.from_io(STDIN)

marks = Set({Int32, Int32}).new
marks << grid.start

STEPS = 64
STEPS.times do
  new_marks = Set({Int32, Int32}).new
  marks.each do |(x, y)|
    grid.each_empty_neighbor(x, y) do |nx, ny|
      new_marks << {nx, ny}
    end
  end
  marks = new_marks
end

grid.to_s(STDERR, marks)
puts marks.size
