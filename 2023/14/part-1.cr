#!/usr/bin/env crystal

enum Cell : UInt8
  Empty
  Round
  Cube

  def self.from_char(char : Char) : self
    case char
    when '.' then Empty
    when 'O' then Round
    when '#' then Cube
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .empty? then '.'
    in .round? then 'O'
    in .cube?  then '#'
    end
  end
end

class Grid
  def initialize(@grid : Array(Array(Cell)))
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map { |char| Cell.from_char(char) }
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

  def []=(x, y, cell : Cell)
    @grid[y][x] = cell
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell.to_char
      end
      io.puts
    end
  end

  def load
    load = 0
    @grid.each_with_index do |row, y|
      row.each do |cell|
        load += height - y if cell.round?
      end
    end
    load
  end

  def tilt_up : self
    height.times do |y|
      width.times do |x|
        move_up(x, y) if self[x, y].round?
      end
    end
    self
  end

  def move_up(x, y) : Nil
    return if y <= 0
    cell = self[x, y]
    y.downto(1) do |y2|
      break unless self[x, y2 - 1].empty?
      self[x, y2 - 1] = cell
      self[x, y2] = :empty
    end
  end
end

grid = Grid.from_io(STDIN)
grid.tilt_up
STDERR.puts grid
puts grid.load
