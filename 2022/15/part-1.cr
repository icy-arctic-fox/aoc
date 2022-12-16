#!/usr/bin/env crystal

struct Sensor
  getter x, y, beacon_x, beacon_y

  def initialize(@x : Int32, @y : Int32, @beacon_x : Int32, @beacon_y : Int32)
  end

  def distance
    distance(beacon_x, beacon_y)
  end

  private def distance(other_x, other_y)
    (other_x - x).abs + (other_y - y).abs
  end

  def in_range?(x, y)
    distance(x, y) <= distance
  end

  def x_range(y)
    dist_y = (@y - y).abs
    dist = distance - dist_y
    return if dist < 0

    (x - dist)..(x + dist)
  end

  def min_x
    x - distance
  end

  def max_x
    x + distance
  end

  def self.parse(line) : self
    m = line.match(/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/)
    raise "Malformed sensor input" unless m

    new(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i)
  end
end

def combine_ranges(a : Range, b : Range)
  if a.includes?(b.begin) || b.includes?(a.begin)
    {a.begin, b.begin}.min..{a.end, b.end}.max
  else
    if a.begin < b.begin
      {a, b}
    else
      {b, a}
    end
  end
end

def combine_ranges(ranges : Enumerable(Range))
  ranges = ranges.sort_by &.begin
  combined = [ranges.first]
  ranges.skip(1).each do |current|
    prev = combined.pop
    range = combine_ranges(prev, current)
    if range.is_a?(Tuple)
      combined.concat(range)
    else
      combined << range
    end
  end
  combined
end

sensors = STDIN.each_line.map { |line| Sensor.parse(line) }.to_a
y = (ARGV.shift? || 2000000).to_i
ranges = combine_ranges(sensors.compact_map &.x_range(y))
count = sensors.compact_map { |sensor| sensor.beacon_x if sensor.beacon_y == y }.uniq.size
puts ranges.sum &.size - count
