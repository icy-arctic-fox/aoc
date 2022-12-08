#!/usr/bin/env crystal

class Grid
  include Enumerable(Int8)

  @grid : Array(Int8)

  getter width : Int32, height : Int32

  def initialize(@width, @height, @grid)
  end

  def self.load(io) : self
    height = 0
    width = 0
    grid = [] of Int8
    io.each_line do |line|
      width = line.size
      cells = line.chars.map &.to_i8
      grid.concat(cells)
      height += 1
    end
    new(width, height, grid)
  end

  def each
    each_coords do |x, y|
      yield self[x, y]
    end
  end

  def each_coords
    height.times do |y|
      width.times do |x|
        yield x, y
      end
    end
  end

  def to_s(io : IO) : Nil
    i = 0
    height.times do
      width.times do
        io << @grid[i]
        i += 1
      end
      io.puts
    end
  end

  def [](x, y)
    raise IndexError.new("Coordinates out of bounds") unless x.in?(0...width) && y.in?(0...height)

    index = coords_to_index(x, y)
    @grid[index]
  end

  def visible
    count = 0
    each_coords do |x, y|
      count += 1 if visible?(x, y)
    end
    count
  end

  def visible?(x, y)
    return true if x == 0 || x == width - 1
    return true if y == 0 || y == height - 1

    cell = self[x, y]
    visible_from_left?(x, y, cell) ||
      visible_from_right?(x, y, cell) ||
      visible_from_top?(x, y, cell) ||
      visible_from_bottom?(x, y, cell)
  end

  private def visible_from_left?(x, y, cell)
    (0...x).all? { |i| self[i, y] < cell }
  end

  private def visible_from_right?(x, y, cell)
    ((x + 1)...width).all? { |i| self[i, y] < cell }
  end

  private def visible_from_top?(x, y, cell)
    (0...y).all? { |i| self[x, i] < cell }
  end

  private def visible_from_bottom?(x, y, cell)
    ((y + 1)...height).all? { |i| self[x, i] < cell }
  end

  private def coords_to_index(x, y)
    y * width + x
  end

  private def index_to_coords(index)
    index.divmod(width)
  end
end

grid = Grid.load(STDIN)
puts grid.visible
