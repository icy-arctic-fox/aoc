#!/usr/bin/env crystal

enum Cell
  Ground
  Vertical
  Horizontal
  NorthEast
  NorthWest
  SouthWest
  SouthEast
  Start

  def self.from_char(char : Char) : self
    case char
    when '.' then Ground
    when '|' then Vertical
    when '-' then Horizontal
    when 'L' then NorthEast
    when 'J' then NorthWest
    when '7' then SouthWest
    when 'F' then SouthEast
    when 'S' then Start
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .ground?     then '.'
    in .vertical?   then '|'
    in .horizontal? then '-'
    in .north_east? then 'L'
    in .north_west? then 'J'
    in .south_west? then '7'
    in .south_east? then 'F'
    in .start?      then 'S'
    end
  end

  def north?
    vertical? || north_east? || north_west?
  end

  def south?
    vertical? || south_west? || south_east?
  end

  def east?
    horizontal? || north_east? || south_east?
  end

  def west?
    horizontal? || north_west? || south_west?
  end

  def each_connection(&)
    yield -1, 0 if west?
    yield +1, 0 if east?
    yield 0, -1 if north?
    yield 0, +1 if south?
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
    @grid.first.size
  end

  def height
    @grid.size
  end

  def start
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        return {x, y} if cell.start?
      end
    end
    raise "Start not found!"
  end

  def []?(x, y)
    @grid.dig?(y, x)
  end

  def [](x, y)
    self[x, y]? || raise IndexError.new
  end

  def each_connected_neighbor(x, y, &)
    cell = self[x, y]?
    return if !cell || cell.ground?

    if cell.start?
      cell = self[x - 1, y]?
      yield cell, x - 1, y if cell.try &.east?
      cell = self[x + 1, y]?
      yield cell, x + 1, y if cell.try &.west?
      cell = self[x, y - 1]?
      yield cell, x, y - 1 if cell.try &.south?
      cell = self[x, y + 1]?
      yield cell, x, y + 1 if cell.try &.north?
    else
      cell.each_connection do |x_off, y_off|
        nx = x + x_off
        ny = y + y_off
        n_cell = self[nx, ny]?
        yield n_cell, nx, ny if n_cell
      end
    end
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

def explore(grid, start)
  queue = Deque({Int32, Int32}).new
  queue << start
  explored = {} of {Int32, Int32} => Int32
  explored[start] = 0

  until queue.empty?
    coords = queue.shift
    dist = explored[coords]

    grid.each_connected_neighbor(*coords) do |cell, x, y|
      next if explored.has_key?({x, y})

      explored[{x, y}] = dist + 1
      queue << {x, y}
    end
  end

  explored.values.max
end

grid = Grid.from_io(STDIN)
puts explore(grid, grid.start)
