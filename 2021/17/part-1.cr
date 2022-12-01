#!/usr/bin/env crystal

DRAG    = 1
GRAVITY = 1

alias Coords = Tuple(Int32, Int32)

record Area, x : Range(Int32, Int32), y : Range(Int32, Int32) do
  def includes?(x : Int32, y : Int32)
    @x.includes?(x) && @y.includes?(y)
  end
end

record Trajectory, points : Array(Coords), velocity : Coords do
  def initialize(x, y)
    @points = [] of Coords
    @velocity = {x, y}
  end

  def <<(coords)
    @points << coords
  end
end

class Probe
  getter x : Int32 = 0
  getter y : Int32 = 0
  getter x_vel : Int32
  getter y_vel : Int32

  def initialize(@x_vel, @y_vel)
  end

  def step
    @x += @x_vel
    @y += @y_vel

    if @x_vel < 0
      @x_vel += DRAG
    elsif @x_vel > 0
      @x_vel -= DRAG
    end

    @y_vel -= GRAVITY
  end

  def coords
    {x, y}
  end

  def in?(target : Area)
    target.includes?(@x, @y)
  end

  def overshot?(target : Area)
    @y < target.y.begin
  end
end

coords = gets.try &.match(/x=(-?\d+)..(-?\d+), y=(-?\d+)..(-?\d+)/)
raise "Couldn't find coords" unless coords
x = Range.new(coords[1].to_i, coords[2].to_i)
y = Range.new(coords[3].to_i, coords[4].to_i)
target = Area.new(x, y)

x_vel_range = Range.new(Math.min(0, x.begin), Math.max(0, x.end))
y_vel_range = Range.new(0, y.size * 3)

possible = [] of Trajectory
x_vel_range.each do |x_vel|
  y_vel_range.each do |y_vel|
    trajectory = Trajectory.new(x_vel, y_vel)
    probe = Probe.new(x_vel, y_vel)
    until probe.overshot?(target)
      probe.step
      trajectory << probe.coords
      if probe.in?(target)
        possible << trajectory
        break
      end
    end
  end
end
puts possible.max_of(&.points.max_of(&.[1]))
