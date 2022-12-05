#!/usr/bin/env crystal

enum Cell
  Floor
  Empty
  Occupied

  def self.from_char(c : Char) : self
    case c
    when '.' then Floor
    when 'L' then Empty
    when '#' then Occupied
    else          raise "Unrecognized cell character '#{c}'"
    end
  end

  def to_s(io : IO) : Nil
    io << to_char
  end

  def to_char : Char
    case self
    in Floor    then '.'
    in Empty    then 'L'
    in Occupied then '#'
    end
  end
end

class Grid
  def initialize(@width : Int32, @height : Int32, @grid : Array(Cell))
    raise "Dimensions don't match grid element count #{@width} x #{@height} (#{@width * @height}) != #{@grid.size})" if @width * @height != @grid.size
  end

  def self.load(io : IO) : self
    grid = [] of Cell
    width = 0
    height = 0
    io.each_line do |line|
      width = line.size
      height += 1
      line.each_char do |char|
        grid << Cell.from_char(char)
      end
    end

    new(width, height, grid)
  end

  def simulate
    new_grid = @grid.dup
    changed = false

    @width.times do |x|
      @height.times do |y|
        index = coords_to_index(x, y)
        if suitable?(x, y)
          new_grid[index] = :occupied
          changed = true
        elsif crowded?(x, y)
          new_grid[index] = :empty
          changed = true
        end
      end
    end

    @grid = new_grid
    changed
  end

  def occupied
    @grid.count &.occupied?
  end

  def to_s(io : IO) : Nil
    @height.times do |y|
      @width.times do |x|
        io << self[x, y]
      end
      io.puts
    end
  end

  def []?(x, y)
    return nil unless x.in?(0...@width) && y.in?(0...@height)

    index = coords_to_index(x, y)
    @grid[index]
  end

  def [](x, y)
    self[x, y]? || raise ArgumentError.new("Coordinates out of bounds")
  end

  def []=(x, y, value)
    index = coords_to_index(x, y)
    @grid[index] = value
  end

  private def suitable?(x, y)
    return false unless self[x, y].empty?

    each_adjacent(x, y) do |cell|
      return false if cell.occupied?
    end
    true
  end

  private def crowded?(x, y)
    return unless self[x, y].occupied?

    count = 0
    each_adjacent(x, y) do |cell|
      count += 1 if cell.occupied?
      return true if count >= 5
    end
    false
  end

  private def each_adjacent(x cx, y cy)
    (-1..1).each do |rx|
      (-1..1).each do |ry|
        next if rx == 0 && ry == 0

        x = cx + rx
        y = cy + ry

        loop do
          break unless cell = self[x, y]?
          break yield cell unless cell.floor?

          x += rx
          y += ry
        end
      end
    end
  end

  private def coords_to_index(x, y)
    y * @width + x
  end

  private def index_to_coords(index)
    index.divmod(@width)
  end
end

grid = Grid.load(STDIN)
rounds = 0
while grid.simulate
  rounds += 1
end
puts grid.occupied
