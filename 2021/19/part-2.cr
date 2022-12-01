#!/usr/bin/env crystal

THRESHOLD = 12
DEBUG     = false

record Point, x : Int32, y : Int32, z : Int32 do
  def distance(other : self)
    (other.x - x).abs + (other.y - y).abs + (other.z - z).abs
  end

  def offset(other : self) : self
    self.class.new(x - other.x, y - other.y, z - other.z)
  end

  def +(other : self) : self
    self.class.new(x + other.x, y + other.y, z + other.z)
  end

  def -(other : self) : self
    self.class.new(x - other.x, y - other.y, z - other.z)
  end

  def - : self
    self.class.new(-x, -y, -z)
  end

  def to_s(io : IO) : Nil
    io << '(' << x << ", " << y << ", " << z << ')'
  end
end

struct Matrix
  @mat : Array(Int32)

  def initialize(@mat : Array(Int32))
  end

  def *(point : Point) : Point
    Point.new(
      point.x * @mat[0] + point.y * @mat[1] + point.z * @mat[2],
      point.x * @mat[3] + point.y * @mat[4] + point.z * @mat[5],
      point.x * @mat[6] + point.y * @mat[7] + point.z * @mat[8],
    )
  end
end

class Scanner
  getter beacons

  def initialize(@beacons : Array(Point))
  end

  def align(other : self) : Point?
    offsets = {} of Point => Int32
    @beacons.each_cartesian(other.beacons) do |(a, b)|
      offset = a.offset(b)
      offsets[offset] = offsets.has_key?(offset) ? offsets[offset] + 1 : 1
    end
    offset, count = offsets.max_by(&.[1])
    return offset if count >= THRESHOLD
  end

  def find_aligned_rotation(other : self) : Tuple(Scanner, Point)?
    each_rotation do |rotation|
      offset = other.align(rotation)
      return rotation, offset if offset
    end
  end

  def translate(offset : Point) : self
    beacons = @beacons.map { |point| point + offset }
    Scanner.new(beacons)
  end

  def each_rotation
    each_rotation_matrix do |matrix|
      beacons = @beacons.map { |point| matrix * point }
      yield Scanner.new(beacons)
    end
  end

  private def each_rotation_matrix
    yield Matrix.new(Int32[1, 0, 0, 0, 1, 0, 0, 0, 1])
    yield Matrix.new(Int32[1, 0, 0, 0, 0, -1, 0, 1, 0])
    yield Matrix.new(Int32[1, 0, 0, 0, -1, 0, 0, 0, -1])
    yield Matrix.new(Int32[1, 0, 0, 0, 0, 1, 0, -1, 0])
    yield Matrix.new(Int32[0, -1, 0, 1, 0, 0, 0, 0, 1])
    yield Matrix.new(Int32[0, 0, 1, 1, 0, 0, 0, 1, 0])
    yield Matrix.new(Int32[0, 1, 0, 1, 0, 0, 0, 0, -1])
    yield Matrix.new(Int32[0, 0, -1, 1, 0, 0, 0, -1, 0])
    yield Matrix.new(Int32[-1, 0, 0, 0, -1, 0, 0, 0, 1])
    yield Matrix.new(Int32[-1, 0, 0, 0, 0, -1, 0, -1, 0])
    yield Matrix.new(Int32[-1, 0, 0, 0, 1, 0, 0, 0, -1])
    yield Matrix.new(Int32[-1, 0, 0, 0, 0, 1, 0, 1, 0])
    yield Matrix.new(Int32[0, 1, 0, -1, 0, 0, 0, 0, 1])
    yield Matrix.new(Int32[0, 0, 1, -1, 0, 0, 0, -1, 0])
    yield Matrix.new(Int32[0, -1, 0, -1, 0, 0, 0, 0, -1])
    yield Matrix.new(Int32[0, 0, -1, -1, 0, 0, 0, 1, 0])
    yield Matrix.new(Int32[0, 0, -1, 0, 1, 0, 1, 0, 0])
    yield Matrix.new(Int32[0, 1, 0, 0, 0, 1, 1, 0, 0])
    yield Matrix.new(Int32[0, 0, 1, 0, -1, 0, 1, 0, 0])
    yield Matrix.new(Int32[0, -1, 0, 0, 0, -1, 1, 0, 0])
    yield Matrix.new(Int32[0, 0, -1, 0, -1, 0, -1, 0, 0])
    yield Matrix.new(Int32[0, -1, 0, 0, 0, 1, -1, 0, 0])
    yield Matrix.new(Int32[0, 0, 1, 0, 1, 0, -1, 0, 0])
    yield Matrix.new(Int32[0, 1, 0, 0, 0, -1, -1, 0, 0])
  end
end

scanners = {} of Int32 => Scanner
points = [] of Point
STDIN.each_line(chomp: true) do |line|
  next if line.blank?

  if m = line.match(/scanner\s+(\d+)/)
    i = m[1].to_i
    points = [] of Point
    scanner = Scanner.new(points)
    scanners[i] = scanner
  else
    coords = line.split(',', 3).map(&.to_i)
    points << Point.new(*coords.values_at(0, 1, 2))
  end
end

scanner0 = scanners.delete(0)
raise "Can't find scanner 0" unless scanner0

aligned = {0 => scanner0}
offsets = {0 => Point.new(0, 0, 0)}

remaining = scanners.to_a
until remaining.empty?
  index, scanner = remaining.shift
  puts "Aligning #{index}..." if DEBUG
  found = aligned.each do |ref_index, ref_rotation|
    if alignment = scanner.find_aligned_rotation(ref_rotation)
      rotation, offset = alignment
      puts "Found alignment against #{ref_index}, translation: #{offset}" if DEBUG
      aligned[index] = rotation.translate(offset)
      offsets[index] = offset
      puts aligned[index].beacons.map(&.to_s).join("\n") if DEBUG
      break true
    end
  end
  remaining << {index, scanner} unless found
end

puts offsets.values.each_combination(2, reuse: true).max_of { |(a, b)| a.distance(b) }
