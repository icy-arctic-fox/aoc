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

  def high_score
    max = 0
    each_coords do |x, y|
      score = score(x, y)
      max = score if score > max
    end
    max
  end

  def score(x, y)
    return 0 if x == 0 || x == width - 1
    return 0 if y == 0 || y == height - 1

    cell = self[x, y]
    score_left(x, y, cell) *
      score_right(x, y, cell) *
      score_up(x, y, cell) *
      score_down(x, y, cell)
  end

  private def score_left(x, y, cell)
    count = 0
    (0...x).reverse_each do |i|
      count += 1
      break if self[i, y] >= cell
    end
    count
  end

  private def score_right(x, y, cell)
    count = 0
    ((x + 1)...width).each do |i|
      count += 1
      break if self[i, y] >= cell
    end
    count
  end

  private def score_up(x, y, cell)
    count = 0
    (0...y).reverse_each do |i|
      count += 1
      break if self[x, i] >= cell
    end
    count
  end

  private def score_down(x, y, cell)
    count = 0
    ((y + 1)...height).each do |i|
      count += 1
      break if self[x, i] >= cell
    end
    count
  end

  private def coords_to_index(x, y)
    y * width + x
  end

  private def index_to_coords(index)
    index.divmod(width)
  end
end

grid = Grid.load(STDIN)
puts grid.high_score
