#!/usr/bin/env crystal

require "bit_array"

enum Cell : UInt8
  Empty
  Round
  Cube

  def self.from_char(char : Char) : self
    case char
    when '.' then Empty
    when 'O' then Round
    when '#' then Cube
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .empty? then '.'
    in .round? then 'O'
    in .cube?  then '#'
    end
  end
end

class Grid
  def initialize(@grid : Array(Array(Cell)))
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map { |char| Cell.from_char(char) }
    end.to_a
    new(grid)
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

  def []=(x, y, cell : Cell)
    @grid[y][x] = cell
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell.to_char
      end
      io.puts
    end
  end

  def load
    load = 0
    @grid.each_with_index do |row, y|
      row.each do |cell|
        load += height - y if cell.round?
      end
    end
    load
  end

  def cycle
    tilt_north
    tilt_west
    tilt_south
    tilt_east
  end

  def tilt_north : self
    height.times do |y|
      width.times do |x|
        move_north(x, y) if self[x, y].round?
      end
    end
    self
  end

  def tilt_south : self
    height.times do |y|
      y = height - y - 1
      width.times do |x|
        move_south(x, y) if self[x, y].round?
      end
    end
    self
  end

  def tilt_west : self
    height.times do |y|
      width.times do |x|
        move_west(x, y) if self[x, y].round?
      end
    end
    self
  end

  def tilt_east : self
    height.times do |y|
      width.times do |x|
        x = width - x - 1
        move_east(x, y) if self[x, y].round?
      end
    end
    self
  end

  def move_north(x, y) : Nil
    return if y <= 0
    cell = self[x, y]
    y.downto(1) do |y2|
      break unless self[x, y2 - 1].empty?
      self[x, y2 - 1] = cell
      self[x, y2] = :empty
    end
  end

  def move_south(x, y) : Nil
    return if y >= height - 1
    cell = self[x, y]
    y.upto(height - 2) do |y2|
      break unless self[x, y2 + 1].empty?
      self[x, y2 + 1] = cell
      self[x, y2] = :empty
    end
  end

  def move_west(x, y) : Nil
    return if x <= 0
    cell = self[x, y]
    x.downto(1) do |x2|
      break unless self[x2 - 1, y].empty?
      self[x2 - 1, y] = cell
      self[x2, y] = :empty
    end
  end

  def move_east(x, y) : Nil
    return if x >= width - 1
    cell = self[x, y]
    x.upto(width - 2) do |x2|
      break unless self[x2 + 1, y].empty?
      self[x2 + 1, y] = cell
      self[x2, y] = :empty
    end
  end

  def state
    BitArray.new(width * height) do |i|
      y, x = i.divmod(width)
      self[x, y].round?
    end
  end
end

def find_loop(states)
  return if states.size < 2
  last = states.last
  index = states.rindex(last, states.size - 2)
  return unless index

  size = states.size - index - 1
  offset = states.size % size
  {offset, size}
end

states = [] of UInt64
grid = Grid.from_io(STDIN)

CYCLES = 1000000000

CYCLES.times do |i|
  grid.cycle
  states << grid.state.hash
  if l = find_loop(states)
    offset, size = l
    loop_states = states[offset, size]
    remaining = (CYCLES - offset) % size
    remaining.times { grid.cycle }
    break
  end
end
puts grid.load
