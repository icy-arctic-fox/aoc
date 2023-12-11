#!/usr/bin/env crystal

enum Cell
  Empty
  Galaxy

  def self.from_char(char : Char) : self
    case char
    when '.' then Empty
    when '#' then Galaxy
    else          raise "Unknown cell character '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .empty?  then '.'
    in .galaxy? then '#'
    end
  end
end

class Grid
  def initialize(@grid : Array(Array(Cell)))
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map do |char|
        Cell.from_char(char)
      end
    end.to_a
    new(grid)
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

  def insert_row(y) : Nil
    row = Array.new(width, Cell::Empty)
    @grid.insert(y, row)
  end

  def insert_column(x) : Nil
    @grid.each do |row|
      row.insert(x, Cell::Empty)
    end
  end

  def expand : self
    empty_rows = height.times.select do |y|
      y if width.times.all? { |x| self[x, y].empty? }
    end.to_a
    empty_cols = width.times.select do |x|
      x if height.times.all? { |y| self[x, y].empty? }
    end.to_a
    empty_cols.reverse_each do |x|
      insert_column(x)
    end
    empty_rows.reverse_each do |y|
      insert_row(y)
    end
    self
  end

  def galaxies
    @grid.each_with_index.flat_map do |row, y|
      row.each_with_index.compact_map do |cell, x|
        {x, y} if cell.galaxy?
      end.to_a
    end.to_a
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell.to_char
      end
      io.puts
    end
  end
end

grid = Grid.from_io(STDIN)
grid.expand
sum = grid.galaxies.combinations(2).sum do |(a, b)|
  ax, ay = a
  bx, by = b
  (bx - ax).abs + (by - ay).abs
end
puts sum
