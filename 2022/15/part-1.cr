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

sensors = STDIN.each_line.map { |line| Sensor.parse(line) }.to_a
y = (ARGV.shift? || 2000000).to_i
min_x = sensors.min_of &.min_x
max_x = sensors.max_of &.max_x
count = 0
min_x.step(to: max_x) do |x|
  next if sensors.any? { |sensor| sensor.beacon_y == y && sensor.beacon_x == x }

  count += 1 if sensors.any? { |sensor| sensor.in_range?(x, y) }
end
puts count
