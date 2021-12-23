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

steps = STDIN.each_line(chomp: true).compact_map do |line|
  next unless m = line.match(/(on|off)\s+x=(-?\d+)\.\.(-?\d+),y=(-?\d+)\.\.(-?\d+),z=(-?\d+)\.\.(-?\d+)/)

  powered = m[1] == "on"
  x = (m[2].to_i64)..(m[3].to_i64)
  y = (m[4].to_i64)..(m[5].to_i64)
  z = (m[6].to_i64)..(m[7].to_i64)
  cuboid = Cuboid.new(x, y, z)
  Step.new(powered, cuboid)
end.to_a.reverse

xs = steps.flat_map { |step| [step.cuboid.x.begin, step.cuboid.x.end + 1] }.sort
ys = steps.flat_map { |step| [step.cuboid.y.begin, step.cuboid.y.end + 1] }.sort
zs = steps.flat_map { |step| [step.cuboid.z.begin, step.cuboid.z.end + 1] }.sort

sum = 0_i64
xs.each_cons_pair do |x1, x2|
  x_steps = steps.select { |step| step.cuboid.x.includes?(x1) }
  ys.each_cons_pair do |y1, y2|
    y_steps = x_steps.select { |step| step.cuboid.y.includes?(y1) }
    zs.each_cons_pair do |z1, z2|
      z_steps = y_steps.select { |step| step.cuboid.z.includes?(z1) }
      z_steps.each do |step|
        break unless step.powered
        
        size = (x2 - x1) * (y2 - y1) * (z2 - z1)
        sum += size
        break
      end
    end
  end
end

puts sum
