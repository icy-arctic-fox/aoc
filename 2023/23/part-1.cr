#!/usr/bin/env crystal

enum Cell : UInt8
  Empty
  Forest
  SlopeNorth
  SlopeEast
  SlopeSouth
  SlopeWest

  def slope?
    slope_north? || slope_east? || slope_south? || slope_west?
  end

  def walkable?
    !forest?
  end

  def self.from_char(char : Char) : self
    case char
    when '.' then Empty
    when '#' then Forest
    when '^' then SlopeNorth
    when '>' then SlopeEast
    when 'v' then SlopeSouth
    when '<' then SlopeWest
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char
    case self
    in .empty?       then '.'
    in .forest?      then '#'
    in .slope_north? then '^'
    in .slope_east?  then '>'
    in .slope_south? then 'v'
    in .slope_west?  then '<'
    end
  end

  def apply(x, y)
    case self
    when .slope_north? then {x, y - 1}
    when .slope_east?  then {x + 1, y}
    when .slope_south? then {x, y + 1}
    when .slope_west?  then {x - 1, y}
    else                    {x, y}
    end
  end
end

class PriorityQueue(T)
  @items = [] of {T, Int32}
  @set = Set(T).new

  def size
    @items.size
  end

  def includes?(value : T)
    @set.includes?(value)
  end

  def empty?
    @items.empty?
  end

  def push(value : T, priority : Int32) : Nil
    @items << {value, priority}
    @set << value
    ci = @items.size - 1

    while ci > 0
      pi = (ci - 1) // 2
      break if @items[ci][1] <= @items[pi][1]

      tmp = @items[ci]
      @items[ci] = @items[pi]
      @items[pi] = tmp
      ci = pi
    end
  end

  def pop : T
    li = @items.size - 1
    value, priority = @items[0]
    @items[0] = @items[li]
    @items.pop
    @set.delete(value)

    li -= 1
    pi = 0

    loop do
      ci = pi * 2 + 1
      break if ci > li
      rc = ci + 1
      ci = rc if rc <= li && @items[rc][1] < @items[ci][1]
      break if @items[pi][1] >= @items[ci][1]
      tmp = @items[pi]
      @items[pi] = @items[ci]
      @items[ci] = tmp
      pi = ci
    end

    value
  end
end

class Grid
  getter start : {Int32, Int32}
  getter finish : {Int32, Int32}

  def initialize(@grid : Array(Array(Cell)), @start, @finish)
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map { |char| Cell.from_char(char) }
    end.to_a

    start_x = grid[0].index!(Cell::Empty)
    finish_x = grid[-1].index!(Cell::Empty)

    new(grid, {start_x, 0}, {finish_x, grid.size - 1})
  end

  def width
    @grid[0].size
  end

  def height
    @grid.size
  end

  def size
    width * height
  end

  def includes?(x, y)
    (0 <= x < width) && (0 <= y < height)
  end

  def [](x, y)
    @grid[y][x]
  end

  def each_neighbor(x, y, &)
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1
  end

  def each_valid_neighbor(x, y, &)
    each_neighbor(x, y) do |nx, ny|
      yield nx, ny if includes?(nx, ny)
    end
  end

  def each_walkable_neighbor(x, y, &)
    cell = self[x, y]
    if cell.slope?
      nx, ny = cell.apply(x, y)
      yield nx, ny if includes?(nx, ny) && self[nx, ny].walkable?
    else
      each_valid_neighbor(x, y) do |nx, ny|
        yield nx, ny if self[nx, ny].walkable?
      end
    end
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell.to_char
      end
      io.puts
    end
  end

  def longest_path
  end
end

grid = Grid.from_io(STDIN)
puts grid.longest_path
