require "bit_array"

record Cuboid,
  x : Range(Int64, Int64),
  y : Range(Int64, Int64),
  z : Range(Int64, Int64) do
  def size
    x.size * y.size * z.size
  end

  def intersect?(other : self)
    x.begin <= other.x.end &&
      x.end >= other.x.begin &&
      y.begin <= other.y.end &&
      y.end >= other.y.begin &&
      z.begin <= other.z.end &&
      z.end >= other.z.begin
  end

  def intersection?(other : self) : self?
    return unless intersect?(other)

    x1 = Math.max(x.begin, other.x.begin)
    x2 = Math.min(x.end, other.x.end)
    y1 = Math.max(y.begin, other.y.begin)
    y2 = Math.min(y.end, other.y.end)
    z1 = Math.max(z.begin, other.z.begin)
    z2 = Math.min(z.end, other.z.end)
    Cuboid.new(x1..x2, y1..y2, z1..z2)
  end
end

record Step, powered : Bool, cuboid : Cuboid

struct Grid
  @steps = [] of Step

  def add(step : Step)
    intersections = @steps.compact_map do |s|
      next unless c = s.cuboid.intersection?(step.cuboid)

      puts s
      puts step
      puts c.size

      Step.new(s.powered ^ step.powered, c).tap { |v| puts v; puts }
    end

    @steps << step
    @steps.concat(intersections)
  end

  def powered
    @steps.sum do |s|
      s.powered ? s.cuboid.size : -s.cuboid.size
    end
  end
end

steps = STDIN.each_line(chomp: true).compact_map do |line|
  next unless m = line.match(/(on|off)\s+x=(-?\d+)\.\.(-?\d+),y=(-?\d+)\.\.(-?\d+),z=(-?\d+)\.\.(-?\d+)/)

  powered = m[1] == "on"
  x = (m[2].to_i64)..(m[3].to_i64)
  y = (m[4].to_i64)..(m[5].to_i64)
  z = (m[6].to_i64)..(m[7].to_i64)
  cuboid = Cuboid.new(x, y, z)
  Step.new(powered, cuboid)
end

grid = Grid.new
steps.each do |step|
  grid.add(step)
end
puts grid.powered
