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
end

grid = Grid.parse(STDIN)
puts grid
