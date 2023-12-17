#!/usr/bin/env crystal

alias Coords = {Int32, Int32}
alias Direction = {Int8, Int8}
alias Key = {Int32, Int32, Int8, Int8, Int32}

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
  STRAIGHT_MIN   =  4
  STRAIGHT_LIMIT = 10

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

  def key : Key
    {*position, *direction, straight_count}
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

    x_off, y_off = direction
    if straight_count == 0
      x_off *= STRAIGHT_MIN
      y_off *= STRAIGHT_MIN
    end

    x = self.x + x_off
    y = self.y + y_off
    grid.in_bounds?(x, y)
  end

  def move_forward(grid : Grid) : self
    raise "Attempt to move forward more than #{STRAIGHT_LIMIT} times" if straight_count >= STRAIGHT_LIMIT

    x_off, y_off = direction
    dist = 1
    loss = 0
    if straight_count == 0
      dist = STRAIGHT_MIN
      STRAIGHT_MIN.times do |i|
        x2 = x + x_off * (i + 1)
        y2 = y + y_off * (i + 1)
        loss += grid[x2, y2]
      end
      x_off *= STRAIGHT_MIN
      y_off *= STRAIGHT_MIN
    else
      loss += grid[x + x_off, y + y_off]
    end
    copy_with(
      position: {x + x_off, y + y_off},
      straight_count: straight_count + dist,
      loss: self.loss + loss,
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

class PriorityQueue(T)
  @items = [] of {T, Int32}
  @set = Set(T).new

  def size
    @items.size
  end

  def includes?(value : T)
    @set.includes?(value)
  end

  def empty?
    @items.empty?
  end

  def push(value : T, priority : Int32) : Nil
    @items << {value, priority}
    @set << value
    ci = @items.size - 1

    while ci > 0
      pi = (ci - 1) // 2
      break if @items[ci][1] <= @items[pi][1]

      tmp = @items[ci]
      @items[ci] = @items[pi]
      @items[pi] = tmp
      ci = pi
    end
  end

  def pop : T
    li = @items.size - 1
    value, priority = @items[0]
    @items[0] = @items[li]
    @items.pop
    @set.delete(value)

    li -= 1
    pi = 0

    loop do
      ci = pi * 2 + 1
      break if ci > li
      rc = ci + 1
      ci = rc if rc <= li && @items[rc][1] < @items[ci][1]
      break if @items[pi][1] >= @items[ci][1]
      tmp = @items[pi]
      @items[pi] = @items[ci]
      @items[ci] = tmp
      pi = ci
    end

    value
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
    open_set = PriorityQueue(Crucible).new
    open_set.push(first, 0)
    came_from = {} of Key => Key

    g_score = Hash(Key, Int32).new(Int32::MAX)
    g_score[first.key] = 0

    f_score = Hash(Key, Int32).new(Int32::MAX)
    f_score[first.key] = heuristic(first, goal)

    found = {nil, [] of Key}
    until open_set.empty?
      current = open_set.pop
      if current.position == goal
        prev = found[0]
        if !prev || current.loss < prev.loss
          found = {current, reconstruct_path(came_from, current.key)}
          STDERR.puts "Search space: #{open_set.size}, current minimum: #{current.loss}"
        end
        next
      end

      each_neighbor(current) do |neighbor|
        tentative_g_score = neighbor.loss
        if tentative_g_score < g_score[neighbor.key]
          came_from[neighbor.key] = current.key
          g_score[neighbor.key] = tentative_g_score
          f_score[neighbor.key] = tentative_g_score + heuristic(neighbor, goal)
          open_set.push(neighbor, tentative_g_score) unless open_set.includes?(neighbor)
        end
      end
    end

    found
  end

  private def heuristic(crucible : Crucible, goal : Coords) : Int32
    cells = (goal[0] - crucible.x).abs + (goal[1] - crucible.y).abs
    cells += cells // 3
    cells * 5
  end
end

grid = Grid.from_io(STDIN)
solver = Solver.new(grid)
crucible, path = solver.a_star({0, 0}, {grid.width - 1, grid.height - 1})
raise "Failed to find path!" unless crucible
grid.to_s(STDERR, path.map { |e| {e[0], e[1]} })
puts crucible.loss
