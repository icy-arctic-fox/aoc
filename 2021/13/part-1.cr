require "bit_array"

record Point, x : Int32, y : Int32 do
  def fold(fold, width, height)
    case fold.axis
    in .x?
      if x <= fold.pos
        self
      else
        Point.new(fold.pos - (x - (width - fold.pos)) - 1, y)
      end
    in .y?
      if y <= fold.pos
        self
      else
        Point.new(x, fold.pos - (y - (height - fold.pos)) - 1)
      end
    end
  end
end

enum Axis
  X
  Y
end

record Fold, axis : Axis, pos : Int32

private macro index(x, y)
  {{y}} * width + {{x}}
end

points = [] of Point
STDIN.each_line(chomp: true) do |line|
  break if line.empty?

  x, y = line.split(',', 2).map(&.to_i)
  points << Point.new(x, y)
end

folds = [] of Fold
STDIN.each_line(chomp: true) do |line|
  raise "Missing fold" unless m = line.match(/([xy])=(\d+)/)

  folds << Fold.new(Axis.parse(m[1]), m[2].to_i)
end

width = points.max_of(&.x) + 1
height = points.max_of(&.y) + 1

folds.each do |fold|
  points.map!(&.fold(fold, width, height)).uniq!

  case fold.axis
  in .x? then width = Math.max(width - fold.pos, fold.pos) - 1
  in .y? then height = Math.max(height - fold.pos, fold.pos) - 1
  end

  break # Part 1 requires one fold only.
end
puts points.size
