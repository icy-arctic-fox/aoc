record Point, x : Int32, y : Int32
record Line, a : Point, b : Point

lines = [] of Line

STDIN.each_line(chomp: true) do |line|
  a, b = line.split(" -> ")
  ax, ay = a.split(',').map(&.to_i)
  bx, by = b.split(',').map(&.to_i)
  lines << Line.new(
    Point.new(ax, ay),
    Point.new(bx, by)
  )
end

width = lines.max_of { |line| Math.max(line.a.x, line.b.x) } + 1
height = lines.max_of { |line| Math.max(line.a.y, line.b.y) } + 1

grid = Array.new(width * height, 0)

private macro index(x, y)
  {{y.id}} * width + {{x.id}}
end

lines.each do |line|
  if line.a.x == line.b.x
    x = line.a.x
    line.a.y.to(line.b.y) do |y|
      grid[index(x, y)] += 1
    end
  elsif line.a.y == line.b.y
    y = line.a.y
    line.a.x.to(line.b.x) do |x|
      grid[index(x, y)] += 1
    end
  else
    x_axis = line.a.x.to(line.b.x)
    y_axis = line.a.y.to(line.b.y)
    x_axis.zip(y_axis) do |x, y|
      grid[index(x, y)] += 1
    end
  end
end

puts grid.count(&.>(1))
