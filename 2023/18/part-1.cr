#!/usr/bin/env crystal

require "bit_array"

enum Direction
  Left
  Right
  Up
  Down

  def self.from_char(char : Char) : self
    case char
    when 'L' then Left
    when 'R' then Right
    when 'U' then Up
    when 'D' then Down
    else          raise "Unrecognized direction '#{char}'"
    end
  end

  def expand(x, y, amount)
    case self
    in .left?  then {x - amount, x, y, y}
    in .right? then {x, x + amount, y, y}
    in .up?    then {x, x, y - amount, y}
    in .down?  then {x, x, y, y + amount}
    end
  end

  def move(x, y, amount)
    case self
    in .left?  then {x - amount, y}
    in .right? then {x + amount, y}
    in .up?    then {x, y - amount}
    in .down?  then {x, y + amount}
    end
  end
end

record(Step, direction : Direction, amount : Int32, color : UInt32) do
  def self.parse(text : String) : self
    match = text.match(/^([LRUD]) (\d+) \(#([0-9a-f]{6})\)$/)
    raise "Invalid step string" unless match

    direction = Direction.from_char(match[1].chars[0])
    amount = match[2].to_i
    color = match[3].to_u32(16)
    new(direction, amount, color)
  end
end

class Grid
  getter width : Int32

  getter height : Int32

  getter anchor_x : Int32

  getter anchor_y : Int32

  def initialize(@width = 1, @height = 1, @anchor_x = 0, @anchor_y = 0, @cells = BitArray.new(1, true))
  end

  def min_x
    -anchor_x
  end

  def max_x
    width - anchor_x - 1
  end

  def min_y
    -anchor_y
  end

  def max_y
    height - anchor_y - 1
  end

  def size
    width * height
  end

  def count
    @cells.count(true)
  end

  def []?(x, y)
    return unless in_bounds?(x, y)
    index = coords_to_index(x, y)
    @cells[index]
  end

  def [](x, y)
    raise IndexError.new("(#{x}, #{y})") unless in_bounds?(x, y)
    index = coords_to_index(x, y)
    @cells[index]
  end

  def []=(x, y, value)
    unless in_bounds?(x, y)
      resize(
        Math.min(x, min_x),
        Math.max(x, max_x),
        Math.min(y, min_y),
        Math.max(y, max_y),
      )
    end

    index = coords_to_index(x, y)
    @cells[index] = value
  end

  private def coords_to_index(x, y)
    (y + anchor_y) * width + (x + anchor_x)
  end

  def resize(min_x, max_x, min_y, max_y) : Nil
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    x = min_x
    y = min_y
    @cells = BitArray.new(width * height) do
      value = self[x, y]? || false
      x += 1
      if x > max_x
        y += 1
        x = min_x
      end
      value
    end
    @width = width
    @height = height
    @anchor_x = -min_x
    @anchor_y = -min_y
  end

  def apply(step : Step, x, y)
    step_min_x, step_max_x, step_min_y, step_max_y = step.direction.expand(x, y, step.amount)
    grid_min_x = Math.min(step_min_x, min_x)
    grid_max_x = Math.max(step_max_x, max_x)
    grid_min_y = Math.min(step_min_y, min_y)
    grid_max_y = Math.max(step_max_y, max_y)

    if grid_min_x < min_x || grid_max_x > max_x ||
       grid_min_y < min_y || grid_max_y > max_y
      resize(grid_min_x, grid_max_x, grid_min_y, grid_max_y)
    end

    (step_min_x..step_max_x).each do |x|
      (step_min_y..step_max_y).each do |y|
        self[x, y] = true
      end
    end
  end

  def fill_interior
    x, y = find_interior || raise "Failed to find interior"
    fill(x, y)
  end

  def find_interior
    grid = dup
    (min_x..max_x).each do |x|
      (min_y..max_y).each do |y|
        next if grid[x, y]
        edge = grid.fill(x, y)
        return {x, y} unless edge
      end
    end
  end

  def fill(x, y)
    return edge?(x, y) if self[x, y]

    queue = [{x, y}]
    self[x, y] = true

    edge = false
    until queue.empty?
      cx, cy = queue.pop
      edge = true if edge?(cx, cy)
      each_valid_neighbor(cx, cy) do |nx, ny|
        next if self[nx, ny]
        self[nx, ny] = true
        queue << {nx, ny}
      end
    end

    edge
  end

  def edge?(x, y)
    x == min_x || x == max_x || y == min_y || y == max_y
  end

  def each_neighbor(x, y)
    (-1..1).each do |x_off|
      (-1..1).each do |y_off|
        next if x_off == 0 && y_off == 0
        yield x + x_off, y + y_off
      end
    end
  end

  def each_valid_neighbor(x, y)
    each_neighbor(x, y) do |nx, ny|
      yield nx, ny if in_bounds?(nx, ny)
    end
  end

  def in_bounds?(x, y)
    (min_x <= x <= max_x) && (min_y <= y <= max_y)
  end

  def dup
    Grid.new(@width, @height, @anchor_x, @anchor_y, @cells.dup)
  end

  def to_s(io : IO) : Nil
    x = 0
    y = 0
    @cells.each do |cell|
      io << (cell ? '#' : '.')
      x += 1
      if x >= width
        x = 0
        y += 1
        io.puts
      end
    end
  end
end

x = 0
y = 0
grid = Grid.new
STDIN.each_line do |line|
  step = Step.parse(line)
  grid.apply(step, x, y)
  x, y = step.direction.move(x, y, step.amount)
end
STDERR.puts grid
STDERR.puts grid.count
grid.fill_interior
STDERR.puts grid
puts grid.count
