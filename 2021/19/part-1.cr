alias Point = Tuple(Int32, Int32, Int32)

struct Matrix
  @mat : Array(Int32)

  def initialize(@mat : Array(Int32))
  end

  def *(point : Point)
    {
      point[0] * @mat[0] + point[1] * @mat[1] + point[2] * @mat[2],
      point[0] * @mat[3] + point[1] * @mat[4] + point[2] * @mat[5],
      point[0] * @mat[6] + point[1] * @mat[7] + point[2] * @mat[8],
    }
  end
end

class Scanner
  getter beacons

  def initialize(@beacons : Array(Point))
  end

  def each_rotation
    each_rotation_matrix do |matrix|
      yield @beacons.map { |point| matrix * point }
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
    points << coords.values_at(0, 1, 2)
  end
end

rotations = [] of Array(Point)
scanners.values.first.each_rotation do |beacons|
  rotations << beacons
end
