#!/usr/bin/env crystal

require "bit_array"

record Cube, x : Int32, y : Int32, z : Int32 do
  def self.parse(string)
    x, y, z = string.split(',', 3).map &.to_i
    new(x, y, z)
  end

  def each_neighbor(grid)
    NEIGHBOR_RELATIVE_COORDS.each do |(rx, ry, rz)|
      nx = x + rx
      ny = y + ry
      nz = z + rz
      yield grid[nx, ny, nz] if grid.in_bounds?(nx, ny, nz)
    end
  end

  def count_neighboring_cubes(grid)
    count = 0
    each_neighbor(grid) do |neighbor|
      count += 1 if neighbor
    end
    count
  end

  def exposed_surfaces(grid)
    NEIGHBOR_RELATIVE_COORDS.size - count_neighboring_cubes(grid)
  end

  NEIGHBOR_RELATIVE_COORDS = [
    {-1, 0, 0}, {1, 0, 0},
    {0, -1, 0}, {0, 1, 0},
    {0, 0, -1}, {0, 0, 1},
  ]
end

module Flat3D
  def coords_to_index(x, y, z)
    (z * height * width) + (y * width) + x
  end

  def index_to_coords(index)
    z, yx = index.divmod(height * width)
    y, x = yx.divmod(width)
    {x, y, z}
  end

  def []?(x, y, z)
    return unless in_bounds?(x, y, z)

    index = coords_to_index(x, y, z)
    unsafe_fetch(index)
  end

  def [](x, y, z)
    raise IndexError.new("Coords out of bounds (#{x}, #{y}, #{z})") unless in_bounds?(x, y, z)

    index = coords_to_index(x, y, z)
    unsafe_fetch(index)
  end

  def []=(x, y, z, value)
    raise IndexError.new("Coords out of bounds (#{x}, #{y}, #{z})") unless in_bounds?(x, y, z)

    index = coords_to_index(x, y, z)
    unsafe_put(index, value)
  end

  def in_bounds?(x, y, z)
    x.in?(0...width) && y.in?(0...height) && z.in?(0...depth)
  end

  abstract def width
  abstract def height
  abstract def depth
  abstract def unsafe_fetch(index : Int)
  abstract def unsafe_put(index : Int, value)
end

class Grid
  include Flat3D

  getter width, height, depth

  def initialize(@width : Int32, @height : Int32, @depth : Int32)
    @grid = BitArray.new(@width * @height * @depth)
  end

  def unsafe_fetch(index : Int)
    @grid.unsafe_fetch(index)
  end

  def unsafe_put(index : Int, value)
    @grid.unsafe_put(index, value)
  end
end

cubes = STDIN.each_line.map { |line| Cube.parse(line) }.to_a
grid = Grid.new(20, 20, 20)
cubes.each do |cube|
  grid[cube.x, cube.y, cube.z] = true
end
puts cubes.sum(&.exposed_surfaces(grid))
