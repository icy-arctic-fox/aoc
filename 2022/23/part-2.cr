#!/usr/bin/env crystal

require "bit_array"

alias Point = {Int32, Int32}

module Flat2D
  abstract def unsafe_fetch(index : Int)
  abstract def unsafe_put(index : Int, value)
  abstract def default
  abstract def resize(x_range, y_range)

  def width
    x_range.size
  end

  def height
    y_range.size
  end

  def size
    width * height
  end

  def min_x
    x_range.begin
  end

  def max_x
    x = x_range.end
    x -= 1 if x_range.excludes_end?
    x
  end

  def min_y
    y_range.begin
  end

  def max_y
    y = y_range.end
    y -= 1 if y_range.excludes_end?
    y
  end

  def each_x
    x_range.each { |x| yield x }
  end

  def each_y
    y_range.each { |y| yield y }
  end

  def each_coordinates
    each_y do |y|
      each_x do |x|
        yield x, y
      end
    end
  end

  def each_cell_with_coordinates
    x = min_x
    y = min_y
    size.times do |index|
      value = unsafe_fetch(index)
      yield value, x, y
      x += 1
      if x > max_x
        y += 1
        x = min_x
      end
    end
  end

  def in_bounds?(x, y)
    x.in?(x_range) && y.in?(y_range)
  end

  def [](x, y)
    return default unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    unsafe_fetch(index)
  end

  def []=(x, y, value)
    unless in_bounds?(x, y)
      x_range = ({min_x, x}.min)..({max_x, x}.max)
      y_range = ({min_y, y}.min)..({max_y, y}.max)
      resize(x_range, y_range)
    end

    index = coords_to_index(x, y)
    unsafe_put(index, value)
  end

  private def coords_to_index(x, y)
    (y - min_y) * width + (x - min_x)
  end

  private def index_to_coords(index)
    y, x = index.divmod(width)
    x += x_range.begin
    y += y_range.begin
    {x, y}
  end

  def to_s(io : IO) : Nil
    size.times do |index|
      io.puts if index.divisible_by?(width) && index > 0
      value = unsafe_fetch(index)
      io << (value ? '#' : '.')
    end
  end
end

class Grid
  include Flat2D

  getter x_range : Range(Int32, Int32)
  getter y_range : Range(Int32, Int32)

  def initialize(@x_range, @y_range, grid)
    size = @x_range.size * @y_range.size
    @grid = BitArray.new(size) { |i| grid[i] }
  end

  def self.parse(io) : self
    width = 0
    height = 0
    grid = [] of Bool
    io.each_line do |line|
      width = line.size
      height += 1
      line.each_char do |c|
        grid << (c == '#')
      end
    end
    new(0...width, 0...height, grid)
  end

  def default
    false
  end

  def each_elf
    each_cell_with_coordinates do |b, x, y|
      yield x, y if b
    end
  end

  def min_elf_x
    min = Int32::MAX
    each_elf do |x, _|
      min = x if x < min
    end
    min
  end

  def min_elf_y
    min = Int32::MAX
    each_elf do |_, y|
      min = y if y < min
    end
    min
  end

  def max_elf_x
    max = Int32::MIN
    each_elf do |x, _|
      max = x if x > max
    end
    max
  end

  def max_elf_y
    max = Int32::MIN
    each_elf do |_, y|
      max = y if y > max
    end
    max
  end

  def unsafe_fetch(index : Int)
    @grid.unsafe_fetch(index)
  end

  def unsafe_put(index : Int, value)
    @grid.unsafe_put(index, value)
  end

  def resize(x_range, y_range) : Nil
    width = x_range.size
    height = y_range.size
    size = width * height
    return if size == self.size

    grid = BitArray.new(size) do |i|
      y, x = i.divmod(width)
      x += x_range.begin
      y += y_range.begin
      self[x, y]
    end

    @x_range = x_range
    @y_range = y_range
    @grid = grid
  end

  def shrink
    resize(min_elf_x..max_elf_x, min_elf_y..max_elf_y)
  end

  def count(value = false)
    @grid.count(value)
  end
end

class Simulation
  abstract struct State
    abstract def can_move?(x, y, grid)
    abstract def move(x, y, proposed)
    abstract def next_state
  end

  struct NorthState < State
    def can_move?(x, y, grid)
      !grid[x, y - 1] && !grid[x - 1, y - 1] && !grid[x + 1, y - 1]
    end

    def move(x, y, proposed)
      proposed[{x, y - 1}] << {x, y}
    end

    def next_state
      SouthState.new
    end
  end

  struct SouthState < State
    def can_move?(x, y, grid)
      !grid[x, y + 1] && !grid[x - 1, y + 1] && !grid[x + 1, y + 1]
    end

    def move(x, y, proposed)
      proposed[{x, y + 1}] << {x, y}
    end

    def next_state
      WestState.new
    end
  end

  struct WestState < State
    def can_move?(x, y, grid)
      !grid[x - 1, y] && !grid[x - 1, y - 1] && !grid[x - 1, y + 1]
    end

    def move(x, y, proposed)
      proposed[{x - 1, y}] << {x, y}
    end

    def next_state
      EastState.new
    end
  end

  struct EastState < State
    def can_move?(x, y, grid)
      !grid[x + 1, y] && !grid[x + 1, y - 1] && !grid[x + 1, y + 1]
    end

    def move(x, y, proposed)
      proposed[{x + 1, y}] << {x, y}
    end

    def next_state
      NorthState.new
    end
  end

  @state : State = NorthState.new

  def initialize(@grid : Grid)
  end

  def update
    proposed = propose_directions
    return false if proposed.empty?

    move_suitable(proposed)
    @state = @state.next_state
    true
  end

  private def propose_directions
    proposed = Hash(Point, Array(Point)).new do |hash, key|
      hash[key] = [] of Point
    end

    @grid.each_elf do |x, y|
      next if satisfied?(x, y)

      find_direction(x, y, proposed)
    end

    proposed
  end

  private def find_direction(x, y, proposed)
    state = @state
    loop do
      if state.can_move?(x, y, @grid)
        state.move(x, y, proposed)
        break
      else
        state = state.next_state
        break if state == @state # Looped back around to initial state.
      end
    end
  end

  private def move_suitable(proposed)
    proposed.each do |dest, elves|
      next if elves.size > 1

      src = elves.first
      @grid[*src] = false
      @grid[*dest] = true
    end
  end

  private def satisfied?(x, y)
    (-1..1).each do |x_off|
      (-1..1).each do |y_off|
        next if x_off == 0 && y_off == 0

        return false if @grid[x + x_off, y + y_off]
      end
    end
    true
  end
end

DEBUG = ARGV.shift? == "-d"

grid = Grid.parse(STDIN)
sim = Simulation.new(grid)
if DEBUG
  puts "== Initial State =="
  puts grid
  puts
end

i = 1
loop do
  break unless sim.update

  if DEBUG
    puts "== End of Round #{i} =="
    puts grid
    puts
  end

  i += 1
end
puts i
