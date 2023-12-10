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
  Wall

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
    when '#' then Wall
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
    in .wall?       then '#'
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

  def each_wall(&)
    raise "Can't generate wall from start!" if start?
    return if ground?

    yield 0, 0
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

  def size
    width * height
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
    return unless 0 <= x < width
    return unless 0 <= y < height
    @grid.dig?(y, x)
  end

  def [](x, y)
    self[x, y]? || raise IndexError.new
  end

  def each_neighbor_coords_unsafe(x, y, &)
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1
  end

  def each_neighbor(x, y, &)
    each_neighbor_coords_unsafe(x, y) do |nx, ny|
      cell = self[nx, ny]?
      yield cell, nx, ny if cell
    end
  end

  def infer_start
    x, y = start

    west = self[x - 1, y]?.try &.east?
    east = self[x + 1, y]?.try &.west?
    north = self[x, y - 1]?.try &.south?
    south = self[x, y + 1]?.try &.north?

    if west && east
      Cell::Horizontal
    elsif north && south
      Cell::Vertical
    elsif north && east
      Cell::NorthEast
    elsif north && west
      Cell::NorthWest
    elsif south && east
      Cell::SouthEast
    elsif south && west
      Cell::SouthWest
    else
      raise "Could not infer start cell shape"
    end
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

  def generate_walls(walls)
    grid = Array(Array(Cell)).new(height * 3) do |y|
      Array(Cell).new(width * 3, Cell::Ground)
    end
    walls.each do |(x, y)|
      cell = self[x, y]
      cell = infer_start if cell.start?
      cell.each_wall do |x_off, y_off|
        grid[y * 3 + y_off + 1][x * 3 + x_off + 1] = :wall
      end
    end
    self.class.new(grid)
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

def identify_loop_cells(grid, start)
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

  explored.keys.to_set
end

def fill(grid, border, start = {0, 0})
  grid = grid.generate_walls(border)
  queue = Deque({Int32, Int32}).new
  queue << start
  original_explored = Set({Int32, Int32}).new
  expanded_explored = Set({Int32, Int32}).new
  border.each do |(x, y)|
    original_explored << {x, y}
  end
  original_explored << start
  expanded_explored << start.map &.*(3)

  until queue.empty?
    coords = queue.shift
    grid.each_neighbor(*coords) do |cell, x, y|
      next if expanded_explored.includes?({x, y})

      original_explored << {x // 3, y // 3}
      expanded_explored << {x, y}
      queue << {x, y} unless cell.wall?
    end
  end

  grid.size // 9 - original_explored.size
end

grid = Grid.from_io(STDIN)
border = identify_loop_cells(grid, grid.start)
puts fill(grid, border)
