#!/usr/bin/env crystal

require "bit_array"

SHAPES_TEXT = <<-END_SHAPES
####

.#.
###
.#.

..#
..#
###

#
#
#
#

##
##
END_SHAPES

module Flat2D
  def coords_to_index(x, y)
    return unless x.in?(0...width) && y.in?(0...height)

    y * width + x
  end

  def index_to_coords(index)
    y, x = index.divmod(width)
    {x, y}
  end

  def []?(x, y)
    return unless index = coords_to_index(x, y)

    unsafe_fetch(index)
  end

  def [](x, y)
    raise IndexError.new unless index = coords_to_index(x, y)

    unsafe_fetch(index)
  end

  def []=(x, y, value)
    raise IndexError.new unless index = coords_to_index(x, y)

    unsafe_put(index, value)
  end

  def in_bounds?(x, y)
    x.in?(0...width) && y.in?(0...height)
  end

  def each_y
    height.times do |y_inv|
      yield height - y_inv - 1
    end
  end

  def each_x
    width.times do |x|
      yield x
    end
  end

  def each_coords
    each_y do |y|
      each_x do |x|
        yield x, y
      end
    end
  end

  abstract def unsafe_fetch(index : Int)
  abstract def unsafe_put(index : Int, value)
end

struct Shape
  include Flat2D

  getter width : Int32
  getter height : Int32

  def initialize(@width, @height, @shape : BitArray)
    raise "Size mismatch" if @width * @height != @shape.size
  end

  def self.parse(lines) : self
    width = 0
    height = 0
    chars = [] of Char
    lines.reverse_each do |line|
      height += 1
      width = line.size
      chars.concat(line.chars)
    end
    shape = BitArray.new(width * height) { |i| chars[i] == '#' }
    new(width, height, shape)
  end

  def self.parse_multiple(text) : Array(self)
    lines = [] of String
    shapes = [] of Shape
    text.each_line do |line|
      if line.empty?
        shapes << parse(lines)
        lines.clear
      else
        lines << line
      end
    end
    shapes << parse(lines) unless lines.empty?
    shapes
  end

  def overlap?(grid, x x_off, y y_off)
    each_filled do |x, y|
      return true if grid[x + x_off, y + y_off]?
    end
    false
  end

  def apply(grid, x x_off, y y_off)
    each_filled do |x, y|
      grid[x + x_off, y + y_off] = true
    end
  end

  def each_filled
    @shape.each_with_index do |b, i|
      next unless b

      x, y = index_to_coords(i)
      yield x, y
    end
  end

  def unsafe_fetch(index : Int)
    @shape.unsafe_fetch(index)
  end

  def unsafe_put(index : Int, value)
    @shape.unsafe_put(index, value)
  end

  def to_s(io : IO, char = '#') : Nil
    height.times do |y_inv|
      io.puts if y_inv > 0
      y = height - y_inv - 1
      width.times do |x|
        io << (self[x, y] ? char : '.')
      end
    end
  end
end

class Grid
  include Flat2D

  getter width : Int32
  getter height : Int32

  def initialize(@width, @height = 0)
    @grid = BitArray.new(@width * @height)
  end

  def unsafe_fetch(index : Int)
    @grid.unsafe_fetch(index)
  end

  def unsafe_put(index : Int, value)
    @grid.unsafe_put(index, value)
  end

  def resize(width, height) : Nil
    raise ArgumentError.new if width < 0 || height < 0

    @grid = BitArray.new(width * height) do |index|
      x, y = index_to_coords(index)
      !!self[x, y]?
    end
    @width = width
    @height = height
  end

  def to_s(io : IO) : Nil
    @grid.each_with_index do |b, i|
      io.puts if i.divisible_by?(width) && i > 0
      io << (b ? '#' : '.')
    end
  end
end

class Simulation
  getter shape_count = 0

  @shape_x = 0
  @shape_y = 0
  @shape : Shape

  def initialize(@grid : Grid, @shapes : Iterator(Shape))
    @shape = spawn_shape
  end

  def self.new(shapes : Iterator(Shape), width = 7, height = 0)
    grid = Grid.new(width, height)
    new(grid, shapes)
  end

  def grid_height : Int
    @grid.height
  end

  def height : Int
    {@grid.height, @shape_y + @shape.height}.max
  end

  def width : Int
    @grid.width
  end

  def move_left : Bool
    x = @shape_x - 1
    return false if x < 0
    return false if @shape.overlap?(@grid, x, @shape_y)

    @shape_x = x
    true
  end

  def move_right : Bool
    x = @shape_x + 1
    return false if x + @shape.width > width
    return false if @shape.overlap?(@grid, x, @shape_y)

    @shape_x = x
    true
  end

  private def move_down : Bool
    y = @shape_y - 1
    return false if y < 0
    return false if @shape.overlap?(@grid, @shape_x, y)

    @shape_y = y
    true
  end

  def update : Bool
    return false if move_down

    solidify
    spawn_shape
    @shape_count += 1
    true
  end

  private def solidify : Nil
    @grid.resize(width, height) if width > @grid.width || height > @grid.height
    @shape.apply(@grid, @shape_x, @shape_y)
  end

  private def spawn_shape : Shape
    shape = @shapes.next
    raise "Ran out of shapes" if shape.is_a?(Iterator::Stop)

    @shape_x = 2
    @shape_y = @grid.height + 3
    @shape = shape
  end

  def to_s(io : IO) : Nil
    each_y do |y|
      io << '|'
      each_x do |x|
        char = if in_shape?(x, y) && @shape[*shape_coords(x, y)]
                 '@'
               elsif @grid[x, y]?
                 '#'
               else
                 '.'
               end
        io << char
      end
      io << '|'
      io.puts
    end
    io << '+'
    width.times { io << '-' }
    io << '+'
  end

  PREVIEW = 20

  def preview(io : IO = STDOUT) : Nil
    min_y = {0, @shape_y - PREVIEW}.max
    max_y = {height, @shape_y + @shape.height + PREVIEW}.min
    puts "DRAW #{max_y}..#{min_y}"
    max_y.step(to: min_y) do |y|
      io << '|'
      each_x do |x|
        char = if in_shape?(x, y) && @shape[*shape_coords(x, y)]
                 '@'
               elsif @grid[x, y]?
                 '#'
               else
                 '.'
               end
        io << char
      end
      io << '|'
      io.puts
    end

    return if min_y > 0
    io << '+'
    width.times { io << '-' }
    io << '+'
    io.puts
  end

  private def each_y
    height.times do |y_inv|
      yield height - y_inv - 1
    end
  end

  private def each_x
    width.times do |x|
      yield x
    end
  end

  private def in_shape?(x, y)
    x.in?(@shape_x...(@shape_x + @shape.width)) && y.in?(@shape_y...(@shape_y + @shape.height))
  end

  private def shape_coords(x, y)
    {x - @shape_x, y - @shape_y}
  end
end

SHAPES = Shape.parse_multiple(SHAPES_TEXT)
shapes = SHAPES.each.cycle
sim = Simulation.new(shapes)
moves = STDIN.each_char.cycle
DEBUG = case ARGV.shift?
        when "-d" then 1
        when "-D" then 2
        when "-s" then 3
        else           0
        end

puts sim if DEBUG > 0

loop do
  c = moves.next
  if DEBUG > 2
    puts "Next input: #{c}"
    sleep 0.05
  end

  moved = case c
          when '<' then sim.move_left
          when '>' then sim.move_right
          end

  sim.preview if DEBUG > 1
  puts "Collided: #{!moved}" if DEBUG > 1
  sim.update
  break if sim.shape_count >= 2022
  puts "Moved down" if DEBUG > 1
end

puts sim if DEBUG > 0
puts sim.grid_height
