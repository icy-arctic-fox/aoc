#!/usr/bin/env crystal

@[Flags]
enum Cell
  Empty =  0
  Wall  =  1
  Left  =  2
  Right =  4
  Up    =  8
  Down  = 16

  def self.from_char(c : Char) : self
    case c
    when '.' then Empty
    when '#' then Wall
    when '<' then Left
    when '>' then Right
    when '^' then Up
    when 'v' then Down
    else          raise "Unrecognized character '#{c}'"
    end
  end

  def char : Char
    case self
    when Empty then '.'
    when Wall  then '#'
    else
      count = value.popcount
      if count > 1
        '0' + count
      else
        direction_char
      end
    end
  end

  def direction_char : Char
    case self
    when Left  then '<'
    when Right then '>'
    when Up    then '^'
    when Down  then 'V'
    else            '?'
    end
  end

  def blizzard?
    case self
    when .left?, .right?, .up?, .down? then true
    else                                    false
    end
  end

  def to_s(io : IO) : Nil
    io << char
  end
end

module Flat2D
  abstract def width
  abstract def height
  abstract def unsafe_fetch(index : Int)
  abstract def unsafe_put(index : Int, value)

  def size
    width * height
  end

  def []?(x, y)
    return unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    unsafe_fetch(index)
  end

  def [](x, y)
    self[x, y]? || raise IndexError.new
  end

  def []=(x, y, value)
    raise IndexError.new unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    unsafe_put(index, value)
  end

  private def coords_to_index(x, y)
    y * width + x
  end

  private def index_to_coords(index)
    y, x = index.divmod(width)
    {x, y}
  end
end

class Grid
  include Flat2D

  getter width, height

  def initialize(@width : Int32, @height : Int32, @grid : Array(Cell))
    raise "Size mismatch" if @width * @height != @grid.size
  end

  def self.parse(io) : self
    width = 0
    height = 0
    grid = [] of Cell
    io.each_line do |line|
      height += 1
      width = line.size
      line.each_char do |c|
        grid << Cell.from_char(c)
      end
    end
    new(width, height, grid)
  end

  def index!(cell)
    @grid.index!(cell)
  end

  def rindex!(cell)
    @grid.rindex(cell) || raise NilAssertionError.new
  end

  def in_bounds?(x, y)
    x.in?(0...width) && y.in?(0...height)
  end

  def each_with_coordinates
    x = 0
    y = 0
    @grid.each do |cell|
      yield cell, x, y
      x += 1
      if x >= width
        x = 0
        y += 1
      end
    end
  end

  def each_blizzard_with_coordinates
    each_with_coordinates do |cell, x, y|
      yield cell, x, y if cell.blizzard?
    end
  end

  def dup_grid_walls
    grid = @grid.map { |cell| cell.wall? ? Cell::Wall : Cell::Empty }
    self.class.new(@width, @height, grid)
  end

  def unsafe_fetch(index : Int)
    @grid.unsafe_fetch(index)
  end

  def unsafe_put(index : Int, value)
    @grid.unsafe_put(index, value)
  end

  def to_s(io : IO) : Nil
    @grid.each_with_index do |cell, index|
      io.puts if index.divisible_by?(width) && index > 0
      io << cell
    end
  end

  def to_s(io : IO, x, y) : Nil
    @grid.each_with_index do |cell, index|
      io.puts if index.divisible_by?(width) && index > 0
      cy, cx = index.divmod(width)
      if x == cx && y == cy
        io << 'E'
      else
        io << cell
      end
    end
  end
end

alias Point = {Int32, Int32}

class Simulation
  getter start : Point
  getter finish : Point
  getter position : Point

  def initialize(@grid : Grid)
    @start = find_start(@grid)
    @finish = find_finish(@grid)
    @position = @start
  end

  private def find_start(grid)
    index = grid.index!(Cell::Empty)
    y, x = index.divmod(grid.width)
    {x, y}
  end

  private def find_finish(grid)
    index = grid.rindex!(Cell::Empty)
    y, x = index.divmod(grid.width)
    {x, y}
  end

  def update : Nil
    grid = @grid.dup_grid_walls
    @grid.each_blizzard_with_coordinates do |cell, x, y|
      advance_blizzard(cell, x, y, grid)
    end

    each_possible_option(grid) do |x, y|
      @position = {x, y}
      puts "Move to #{@position}" if DEBUG > 0
      break
    end
    @grid = grid
  end

  private def advance_blizzard(cell, x, y, grid)
    move_left(grid, x, y) if cell.left?
    move_right(grid, x, y) if cell.right?
    move_up(grid, x, y) if cell.up?
    move_down(grid, x, y) if cell.down?
  end

  private def move_left(grid, x, y)
    puts "Move (#{x}, #{y}) left" if DEBUG > 1
    x = look_left(grid, x, y)
    grid[x, y] |= Cell::Left
  end

  private def move_right(grid, x, y)
    puts "Move (#{x}, #{y}) right" if DEBUG > 1
    x = look_right(grid, x, y)
    grid[x, y] |= Cell::Right
  end

  private def move_up(grid, x, y)
    puts "Move (#{x}, #{y}) up" if DEBUG > 1
    y = look_up(grid, x, y)
    grid[x, y] |= Cell::Up
  end

  private def move_down(grid, x, y)
    puts "Move (#{x}, #{y}) down" if DEBUG > 1
    y = look_down(grid, x, y)
    grid[x, y] |= Cell::Down
  end

  private def look_left(grid, x, y)
    loop do
      x -= 1
      x %= grid.width
      break unless grid[x, y].wall?
    end
    x
  end

  private def look_right(grid, x, y)
    loop do
      x += 1
      x %= grid.width
      break unless grid[x, y].wall?
    end
    x
  end

  private def look_up(grid, x, y)
    loop do
      y -= 1
      y %= grid.height
      break unless grid[x, y].wall?
    end
    y
  end

  private def look_down(grid, x, y)
    loop do
      y += 1
      y %= grid.height
      break unless grid[x, y].wall?
    end
    y
  end

  private def each_option
    x, y = @position
    yield x, y
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1
  end

  private def each_possible_option(grid)
    each_option do |x, y|
      next unless grid.in_bounds?(x, y)

      cell = grid[x, y]
      yield x, y if cell == Cell::Empty # Not sure why .empty? doesn't work.
    end
  end

  private def possible_options(grid)
    options = [] of Point
    each_possible_option do |x, y|
      options << {x, y}
    end
    options
  end

  def to_s(io : IO) : Nil
    @grid.to_s(io, *@position)
  end
end

DEBUG = case ARGV.shift?
        when "-d" then 1
        when "-D" then 2
        else           0
        end

grid = Grid.parse(STDIN)
sim = Simulation.new(grid)
if DEBUG > 0
  puts "Initial state:"
  puts sim
  puts
end

20.times do |i|
  sim.update
  if DEBUG > 0
    puts "Minute #{i + 1}:"
    puts sim
    puts
  end
end
