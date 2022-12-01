#!/usr/bin/env crystal

WIDTH  = 10
HEIGHT = 10
SIZE   = WIDTH * HEIGHT
FLASH  =  10
STEPS  = 100

private def index(x, y)
  y * WIDTH + x
end

private def coords(index)
  y, x = index.divmod(WIDTH)
  {x, y}
end

private def each_neighbor(x, y)
  ((x - 1)..(x + 1)).each do |x2|
    ((y - 1)..(y + 1)).each do |y2|
      next if x == x2 && y == y2
      yield({x2, y2}) if x2 >= 0 && x2 < WIDTH && y2 >= 0 && y2 < HEIGHT
    end
  end
end

private def flash(grid, x, y)
  each_neighbor(x, y) do |x2, y2|
    i = index(x2, y2)
    grid[i] += 1
    flash(grid, x2, y2) if grid[i] == FLASH
  end
end

grid = Array(Int32).new(SIZE, 0)

STDIN.each_line(chomp: true).each_with_index do |line, y|
  line.each_char.each_with_index do |c, x|
    grid[index(x, y)] = c.to_i
  end
end

count = STEPS.times.sum do
  grid.each_index do |i|
    x, y = coords(i)
    grid[i] += 1
    flash(grid, x, y) if grid[i] == FLASH
  end

  flashed = 0
  grid.each_with_index do |energy, i|
    next if energy < FLASH

    grid[i] = 0
    flashed += 1
  end

  flashed
end

puts count
