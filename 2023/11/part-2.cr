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
  @expanded_rows = Set(Int32).new
  @expanded_cols = Set(Int32).new

  EMPTY_SCALE = 1_000_000

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

  def expand_row(y) : Nil
    @expanded_rows << y
  end

  def expand_column(x) : Nil
    @expanded_cols << x
  end

  def expand : self
    height.times do |y|
      expand_row(y) if width.times.all? { |x| self[x, y].empty? }
    end
    width.times do |x|
      expand_column(x) if height.times.all? { |y| self[x, y].empty? }
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

  def distance(a, b)
    ax, ay = a
    bx, by = b
    ax, bx = bx, ax if bx < ax
    ay, by = by, ay if by < ay
    x_dist = (ax...bx).sum(0_i64) do |x|
      @expanded_cols.includes?(x) ? EMPTY_SCALE : 1
    end
    y_dist = (ay...by).sum(0_i64) do |y|
      @expanded_rows.includes?(y) ? EMPTY_SCALE : 1
    end
    x_dist + y_dist
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
  grid.distance(a, b)
end
puts sum
