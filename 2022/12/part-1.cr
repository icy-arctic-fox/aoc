#!/usr/bin/env crystal

alias Point = {Int32, Int32}

class Grid
  getter width : Int32
  getter height : Int32
  getter start
  getter :end

  def initialize(@width, @height, @start : Point, @end : Point, @cells : Array(Char))
    raise "Size mismatch" if @cells.size != @width * @height
  end

  def self.parse(io) : self
    height = 0
    width = 0
    s = nil
    e = nil
    cells = [] of Char

    io.each_line do |line|
      row = line.chars
      row.each_with_index do |cell, x|
        case cell
        when 'S'
          row[x] = 'a'
          s = {x, height}
        when 'E'
          row[x] = 'z'
          e = {x, height}
        end
      end
      width = row.size
      cells.concat(row)
      height += 1
    end

    raise "Didn't find start" if s.nil?
    raise "Didn't find end" if e.nil?

    new(width, height, s, e, cells)
  end

  def solve
    open_set = [start]
    came_from = {} of Point => Point
    g_score = Hash(Point, Int32).new(Int32::MAX)
    g_score[start] = 0
    f_score = Hash(Point, Int32).new(Int32::MAX)
    f_score[start] = h(start)

    until open_set.empty?
      current = open_set.min_by { |point| f_score[point] }
      return reconstruct_path(came_from, current) if current == @end

      open_set.delete(current)
      each_suitable_neighbor(*current) do |x, y, cell|
        neighbor = {x, y}
        tentative_g_score = g_score[current] + d(current, neighbor)
        if tentative_g_score < g_score[neighbor]
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g_score
          f_score[neighbor] = tentative_g_score + h(neighbor)
          open_set << neighbor unless open_set.includes?(neighbor)
        end
      end
    end

    nil
  end

  private def reconstruct_path(came_from, current)
    path = [current]
    while current = came_from[current]?
      path << current
    end
    path.reverse!
  end

  private def h(point)
    dist(point, @end)
  end

  private def d(a, b)
    1
  end

  def dist(a, b)
    (a[0] - b[0]).abs + (a[1] - b[1]).abs
  end

  def neighbors(x, y)
    neighbors = {
      {-1, 0}, {1, 0}, {0, -1}, {0, 1},
    }
    neighbors.map do |(i, j)|
      nx = x + i
      ny = y + j
      self[nx, ny]?
    end
  end

  def each_neighbor(x, y)
    neighbors = {
      {-1, 0}, {1, 0}, {0, -1}, {0, 1},
    }
    neighbors.each do |(i, j)|
      nx = x + i
      ny = y + j
      cell = self[nx, ny]?
      yield nx, ny, cell if cell
    end
  end

  def each_suitable_neighbor(x, y)
    current = self[x, y]
    each_neighbor(x, y) do |nx, ny, cell|
      next unless cell < current || (cell.ord - current.ord) <= 1

      yield nx, ny, cell
    end
  end

  def []?(x, y)
    return unless x.in?(0...width) && y.in?(0...height)

    index = coords_to_index(x, y)
    @cells[index]
  end

  def [](x, y)
    self[x, y]? || raise IndexError.new
  end

  def to_s(io : IO) : Nil
    start_index = coords_to_index(*@start)
    end_index = coords_to_index(*@end)

    @cells.each_with_index do |cell, i|
      io.puts if i != 0 && i.divisible_by?(@width)
      io << case i
      when start_index then 'S'
      when end_index   then 'E'
      else                  cell
      end
    end
  end

  private def coords_to_index(x, y)
    y * width + x
  end

  private def index_to_coords(index)
    y, x = index.divmod(width)
    {x, y}
  end
end

grid = Grid.parse(STDIN)
path = grid.solve
raise "Failed to find solution" unless path
puts path.size - 1
