#!/usr/bin/env crystal

require "bit_array"

X_MIN   = -50
X_MAX   =  50
Y_MIN   = -50
Y_MAX   =  50
Z_MIN   = -50
Z_MAX   =  50
X_RANGE = Range.new(X_MIN, X_MAX)
Y_RANGE = Range.new(Y_MIN, Y_MAX)
Z_RANGE = Range.new(Z_MIN, Z_MAX)
SIZE    = X_RANGE.size * Y_RANGE.size * Z_RANGE.size

record Step,
  powered : Bool,
  x : Range(Int32, Int32),
  y : Range(Int32, Int32),
  z : Range(Int32, Int32)

struct Grid
  @cubes = BitArray.new(SIZE)

  def [](x, y, z)
    @cubes[index(x, y, z)]
  end

  def []=(x, y, z, powered)
    @cubes[index(x, y, z)] = powered
  end

  def powered
    @cubes.count(true)
  end

  private def index(x, y, z)
    z * Y_RANGE.size * X_RANGE.size + X_RANGE.size * y + x
  end
end

steps = STDIN.each_line(chomp: true).compact_map do |line|
  next unless m = line.match(/(on|off)\s+x=(-?\d+)\.\.(-?\d+),y=(-?\d+)\.\.(-?\d+),z=(-?\d+)\.\.(-?\d+)/)

  powered = m[1] == "on"
  x = Range.new(m[2].to_i, m[3].to_i)
  y = Range.new(m[4].to_i, m[5].to_i)
  z = Range.new(m[6].to_i, m[7].to_i)
  Step.new(powered, x, y, z)
end

grid = Grid.new
steps.each do |step|
  next if step.x.begin < X_MIN || step.x.end > X_MAX ||
          step.y.begin < Y_MIN || step.y.end > Y_MAX ||
          step.z.begin < Z_MIN || step.z.end > Z_MAX

  step.x.each do |x|
    step.y.each do |y|
      step.z.each do |z|
        grid[x, y, z] = step.powered
      end
    end
  end
end
puts grid.powered
