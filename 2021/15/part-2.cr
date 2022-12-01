#!/usr/bin/env crystal

record Coord, x : Int32, y : Int32 do
  def each_neighbor(w, h)
    yield Coord.new(x + 1, y) if x + 1 < w
    yield Coord.new(x, y + 1) if y + 1 < h
    yield Coord.new(x - 1, y) if x > 0
    yield Coord.new(x, y - 1) if y > 0
  end
end

def reconstruct_path(came_from, current)
  total_path = [current]
  prev = current
  while prev = came_from[prev]?
    total_path << prev
  end
  total_path.reverse!
end

def h(a : Coord, b : Coord)
  0 # ((b.x - a.x).abs + (b.y - a.y).abs) * 5
end

def a_star(start : Coord, finish : Coord, w, h, & : Coord -> Int32)
  open_set = [start]
  came_from = {} of Coord => Coord
  g_score = Hash(Coord, Int32).new { Int32::MAX }
  g_score[start] = 0

  f_score = Hash(Coord, Int32).new { Int32::MAX }
  f_score[start] = h(start, finish)

  until open_set.empty?
    current = open_set.min_by { |coord| f_score[coord] }
    return reconstruct_path(came_from, current) if current == finish

    open_set.delete(current)

    current.each_neighbor(w, h) do |neighbor|
      tentative_g_score = g_score[current] + yield(current, neighbor)
      if tentative_g_score < g_score[neighbor]
        came_from[neighbor] = current
        g_score[neighbor] = tentative_g_score
        f_score[neighbor] = tentative_g_score + h(neighbor, finish)

        open_set.push(neighbor) unless neighbor.in?(open_set)
      end
    end
  end

  raise "Failed to find path"
end

def cost(grid, x, y, cw, ch)
  cell_x, x_off = x.divmod(cw)
  cell_y, y_off = y.divmod(ch)
  adj = cell_x + cell_y
  (grid[y_off][x_off] + adj - 1) % 9 + 1
end

grid = Array(Array(Int32)).new

STDIN.each_line(chomp: true) do |line|
  grid << line.chars.map(&.to_i)
end

MULT = 5
cw = grid.first.size
ch = grid.size
width = cw * MULT
height = ch * MULT

start = Coord.new(0, 0)
finish = Coord.new(width - 1, height - 1)
path = a_star(start, finish, width, height) { |_a, b| cost(grid, b.x, b.y, cw, ch) }

cost = path.sum { |coord| cost(grid, coord.x, coord.y, cw, ch) } - cost(grid, start.x, start.y, cw, ch)
puts cost
