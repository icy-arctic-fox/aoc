require "bit_array"

record Cuboid,
  x : Range(Int64, Int64),
  y : Range(Int64, Int64),
  z : Range(Int64, Int64) do
  def size
    x.size * y.size * z.size
  end
end

record Step, powered : Bool, cuboid : Cuboid

class Cut
  property position : Int64
  property? powered : Bool

  def initialize(@position, @powered)
  end
end

struct Grid
  @x_axis : Array(Cut)
  @y_axis : Array(Cut)
  @z_axis : Array(Cut)

  def initialize(cuboid : Cuboid)
    @x_axis = [
      Cut.new(cuboid.x.begin, false),
      Cut.new(cuboid.x.end, false),
    ]
    @y_axis = [
      Cut.new(cuboid.y.begin, false),
      Cut.new(cuboid.y.end, false),
    ]
    @z_axis = [
      Cut.new(cuboid.z.begin, false),
      Cut.new(cuboid.z.end, false),
    ]
  end

  def add(step : Step)
    insert(@x_axis, step.cuboid.x, step.powered)
    insert(@y_axis, step.cuboid.y, step.powered)
    insert(@z_axis, step.cuboid.z, step.powered)
  end

  private def insert(axis, range, powered)
    start = Cut.new(range.begin, powered)
    finish = Cut.new(range.end + 1, powered)
    axis << start
    axis << finish
    axis.sort_by!(&.position)
    start_index = axis.index(start).not_nil!
    finish_index = axis.index(finish, start_index).not_nil!
    reset = axis[finish_index + 1].powered?
    axis[start_index...finish_index].each { |c| c.powered = powered }
    axis[finish_index].powered = reset
  end

  def powered
    sum = 0_i64
    @x_axis.each_cons_pair do |cx1, cx2|
      x1 = cx1.position
      x2 = cx2.position
      @y_axis.each_cons_pair do |cy1, cy2|
        y1 = cy1.position
        y2 = cy2.position
        @z_axis.each_cons_pair do |cz1, cz2|
          z1 = cz1.position
          z2 = cz2.position

          powered = cx1.powered? && cy1.powered? && cz1.powered?
          # puts "#{cuboid.colorize(powered ? :green : :red)} = #{cuboid.size}"
          sum += ((z2 - z1) * (y2 - y1) * (x2 - x1)) if powered
        end
      end
    end
    sum
  end

  def to_s(io : IO) : Nil
    @x_axis.each do |cut|
      io.print "#{cut.position} | ".colorize(cut.powered? ? :green : :red)
    end
    puts
    @y_axis.each do |cut|
      io.print "#{cut.position} - ".colorize(cut.powered? ? :green : :red)
    end
    puts
    @z_axis.each do |cut|
      io.print "#{cut.position} / ".colorize(cut.powered? ? :green : :red)
    end
  end
end

require "colorize"

steps = STDIN.each_line(chomp: true).compact_map do |line|
  next unless m = line.match(/(on|off)\s+x=(-?\d+)\.\.(-?\d+),y=(-?\d+)\.\.(-?\d+),z=(-?\d+)\.\.(-?\d+)/)

  powered = m[1] == "on"
  x = (m[2].to_i64)..(m[3].to_i64)
  y = (m[4].to_i64)..(m[5].to_i64)
  z = (m[6].to_i64)..(m[7].to_i64)
  cuboid = Cuboid.new(x, y, z)
  Step.new(powered, cuboid)
end.to_a

min_x = Math.min(-50_i64, steps.min_of(&.cuboid.x.begin))
max_x = Math.max(50_i64, steps.max_of(&.cuboid.x.end))
min_y = Math.min(-50_i64, steps.min_of(&.cuboid.y.begin))
max_y = Math.max(50_i64, steps.max_of(&.cuboid.y.end))
min_z = Math.min(-50_i64, steps.min_of(&.cuboid.z.begin))
max_z = Math.max(50_i64, steps.max_of(&.cuboid.z.end))
cube = Cuboid.new(min_x..max_x, min_y..max_y, min_z..max_z)

grid = Grid.new(cube)
steps.each do |step|
  puts grid
  puts grid.powered
  puts
  grid.add(step)
end
puts grid
puts grid.powered
