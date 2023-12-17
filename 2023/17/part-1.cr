#!/usr/bin/env crystal

alias Coords = {Int32, Int32}
alias Direction = {Int8, Int8}

class Grid
  def initialize(@grid : Array(Array(UInt8)))
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map &.to_u8
    end.to_a
    new(grid)
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell
      end
      io.puts
    end
  end

  def to_s(io : IO, path : Enumerable(Coords)) : Nil
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        io << ({x, y}.in?(path) ? '.' : cell)
      end
      io.puts
    end
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

  def in_bounds?(x, y)
    (0 <= x < width) && (0 <= y < height)
  end
end

record(Crucible,
  direction : Direction = EAST,
  position : Coords = {0, 0},
  straight_count : Int32 = 0,
  loss : Int32 = 0) do
  STRAIGHT_LIMIT = 3

  NORTH = {0_i8, -1_i8}
  SOUTH = {0_i8, +1_i8}
  EAST  = {+1_i8, 0_i8}
  WEST  = {-1_i8, 0_i8}

  def x
    @position[0]
  end

  def y
    @position[1]
  end

  def north?
    direction == NORTH
  end

  def turn_north : self
    copy_with(direction: NORTH, straight_count: 0)
  end

  def south?
    direction == SOUTH
  end

  def turn_south : self
    copy_with(direction: SOUTH, straight_count: 0)
  end

  def east?
    direction == EAST
  end

  def turn_east : self
    copy_with(direction: EAST, straight_count: 0)
  end

  def west?
    direction == WEST
  end

  def turn_west : self
    copy_with(direction: WEST, straight_count: 0)
  end

  def move_forward?(grid : Grid)
    return false if straight_count >= STRAIGHT_LIMIT

    x = self.x + direction[0]
    y = self.y + direction[1]
    grid.in_bounds?(x, y)
  end

  def move_forward(grid : Grid) : self
    raise "Attempt to move forward more than #{STRAIGHT_LIMIT} times" if straight_count >= STRAIGHT_LIMIT

    new_position = {
      position[0] + direction[0],
      position[1] + direction[1],
    }
    copy_with(
      position: new_position,
      straight_count: straight_count + 1,
      loss: loss + grid[*new_position]
    )
  end

  def turn?
    straight_count > 0
  end

  def turn_left : self
    case self
    when .east?  then turn_north
    when .north? then turn_west
    when .west?  then turn_south
    when .south? then turn_east
    else              raise "Invalid direction #{direction}"
    end
  end

  def turn_right : self
    case self
    when .east?  then turn_south
    when .south? then turn_west
    when .west?  then turn_north
    when .north? then turn_east
    else              raise "Invalid direction #{direction}"
    end
  end
end

class Solver
  def initialize(@grid : Grid)
  end

  private def reconstruct_path(came_from, current)
    total_path = [current]
    while source = came_from[current]?
      current = source
      total_path << current
    end
    total_path.reverse
  end

  private def each_neighbor(crucible : Crucible, & : Crucible -> _)
    yield crucible.move_forward(@grid) if crucible.move_forward?(@grid)
    # return unless crucible.turn?

    left = crucible.turn_left
    yield left.move_forward(@grid) if left.move_forward?(@grid)

    right = crucible.turn_right
    yield right.move_forward(@grid) if right.move_forward?(@grid)
  end

  def a_star(start : Coords, goal : Coords)
    first = Crucible.new(position: start)
    open_set = [first]
    came_from = {} of Coords => Coords

    g_score = Hash(Coords, Int32).new(Int32::MAX)
    g_score[first.position] = 0

    f_score = Hash(Coords, Int32).new(Int32::MAX)
    f_score[first.position] = heuristic(first, goal)

    found = [] of {Crucible, Array(Coords)}
    until open_set.empty?
      current = open_set.min_by { |c| f_score[c.position] }
      STDERR.puts "Looking at #{current.position}"
      open_set.delete(current)
      next found << {current, reconstruct_path(came_from, current.position)} if current.position == goal

      each_neighbor(current) do |neighbor|
        STDERR.puts "POSSIBILITY: #{neighbor}"
        tentative_g_score = neighbor.loss
        if tentative_g_score < g_score[neighbor.position]
          came_from[neighbor.position] = current.position
          g_score[neighbor.position] = tentative_g_score
          f_score[neighbor.position] = tentative_g_score + heuristic(neighbor, goal)
          open_set << neighbor unless open_set.includes?(neighbor)
        end
      end
    end

    found.min_by &.first.loss
  end

  private def heuristic(crucible : Crucible, goal : Coords) : Int32
    cells = (goal[0] - crucible.x).abs + (goal[1] - crucible.y).abs
    cells += cells // 3
    cells * 5
  end
end

grid = Grid.from_io(STDIN)
solver = Solver.new(grid)
STDERR.puts grid
crucible, path = solver.a_star({0, 0}, {grid.width - 1, grid.height - 1})
grid.to_s(STDERR, path)
puts crucible.loss
