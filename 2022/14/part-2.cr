#!/usr/bin/env crystal

DEBUG = ARGV.shift? == "-d"
SPAWN = Point.new(500, 0)

record Point, x : Int32, y : Int32 do
  def self.parse(string) : self
    x, y = string.split(/\s*,\s*/, 2).map &.to_i
    new(x, y)
  end

  def below
    self.class.new(x, y + 1)
  end

  def below_left
    self.class.new(x - 1, y + 1)
  end

  def below_right
    self.class.new(x + 1, y + 1)
  end

  def to(other : self)
    x.step(to: other.x) do |i|
      y.step(to: other.y) do |j|
        yield i, j
      end
    end
  end

  def to_s(io : IO) : Nil
    io << x << ',' << y
  end
end

struct Wall
  include Enumerable(Point)

  def initialize(@points : Array(Point))
  end

  def self.parse(line) : self
    points = line.split(/\s*->\s*/).map { |string| Point.parse(string) }
    new(points)
  end

  def min_x
    @points.min_of &.x
  end

  def min_y
    @points.min_of &.y
  end

  def max_x
    @points.max_of &.x
  end

  def max_y
    @points.max_of &.y
  end

  def each
    @points.each { |point| yield point }
  end

  def each_segment(& : Point, Point -> _)
    each_cons_pair { |a, b| yield a, b }
  end

  def draw(cave)
    each_segment do |a, b|
      a.to(b) do |x, y|
        cave[x, y] = :wall
      end
    end
  end

  def to_s(io : IO) : Nil
    @points.join(io, " -> ")
  end
end

enum Cell
  Air
  Wall
  Sand

  def to_char
    case self
    in Air  then '.'
    in Wall then '#'
    in Sand then 'o'
    end
  end

  def to_s(io : IO) : Nil
    io << to_char
  end
end

class Cave
  def initialize(@x_range : Range(Int32, Int32), @y_range : Range(Int32, Int32))
    @grid = Array(Cell).new(width * height, :air)
  end

  def self.from_walls(walls : Enumerable(Wall))
    min_x = walls.min_of &.min_x
    min_y = walls.min_of &.min_y
    max_x = walls.max_of &.max_x
    max_y = walls.max_of &.max_y
    min_y = SPAWN.y if min_y > SPAWN.y
    max_x = SPAWN.x if max_x < SPAWN.x
    max_y += 2

    Cave.new(min_x..max_x, min_y..max_y).tap do |cave|
      walls.each &.draw(cave)
    end
  end

  def width
    @x_range.size
  end

  def height
    @y_range.size
  end

  def floor
    height - 1
  end

  def in_bounds?(point)
    in_bounds?(point.x, point.y)
  end

  def in_bounds?(x, y)
    x.in?(@x_range) && y.in?(@y_range)
  end

  def []?(point)
    self[point.x, point.y]?
  end

  def []?(x, y)
    return Cell::Wall if y >= floor
    return unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    @grid[index]
  end

  def [](point)
    self[point.x, point.y]
  end

  def [](x, y)
    self[x, y]? || Cell::Air
  end

  def []=(point, cell : Cell)
    self[point.x, point.y] = cell
  end

  def []=(x, y, cell : Cell)
    expand_to_fit(x, y) unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    @grid[index] = cell
  end

  private def expand_to_fit(x, y)
    min_x = {x, @x_range.begin}.min
    min_y = {y, @y_range.begin}.min
    max_x = {x, @x_range.end}.max
    max_y = {y, @y_range.end}.max

    x_range = min_x..max_x
    y_range = min_y..max_y
    size = x_range.size * y_range.size
    puts "Resize #{@x_range} x #{@y_range} to #{x_range} x #{y_range}" if DEBUG
    @grid = Array(Cell).new(size) do |index|
      y, x = index.divmod(x_range.size)
      x += min_x
      y += min_y
      self[x, y]
    end
    @x_range = x_range
    @y_range = y_range
  end

  def to_s(io : IO) : Nil
    @grid.each_with_index do |cell, index|
      io.puts if index.divisible_by?(width) && index > 0
      io << cell
    end
  end

  private def coords_to_index(x, y)
    (y - @y_range.begin) * width + (x - @x_range.begin)
  end
end

class Simulation
  getter sand = 0

  def initialize(@cave : Cave)
  end

  def spawn_sand
    sand = SPAWN
    loop do
      new_sand_position = update(sand)
      break if new_sand_position == sand

      sand = new_sand_position
    end
    @cave[sand] = :sand
    @sand += 1
    sand != SPAWN
  end

  private def update(sand)
    if @cave[sand.below].air?
      sand.below
    elsif @cave[sand.below_left].air?
      sand.below_left
    elsif @cave[sand.below_right].air?
      sand.below_right
    else
      sand
    end
  end
end

paths = STDIN.each_line.map { |line| Wall.parse(line) }.to_a
cave = Cave.from_walls(paths)
sim = Simulation.new(cave)
while sim.spawn_sand
  if DEBUG
    puts cave
    puts
  end
end
puts sim.sand
