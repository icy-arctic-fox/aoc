#!/usr/bin/env crystal

enum Direction
  Left
  Right
  Up
  Down

  def horizontal?
    self.left? || self.right?
  end

  def vertical?
    self.up? || self.down?
  end

  def self.from_char(char : Char) : self
    case char
    when '0' then Right
    when '1' then Down
    when '2' then Left
    when '3' then Up
    else          raise "Unrecognized direction '#{char}'"
    end
  end

  def apply(amount)
    case self
    in .left?  then {-amount, 0}
    in .right? then {+amount, 0}
    in .up?    then {0, -amount}
    in .down?  then {0, +amount}
    end
  end
end

record(Step, direction : Direction, amount : Int64) do
  def self.parse(text : String) : self
    match = text.match(/^[LRUD] \d+ \(#([0-9a-f]{6})\)$/)
    raise "Invalid step string" unless match

    direction = Direction.from_char(match[1][5])
    amount = match[1][0...5].to_i64(16)
    new(direction, amount)
  end
end

record(Bounds, x : Int64, y : Int64, width : Int64, height : Int64) do
  def left
    x
  end

  def right
    x + width
  end

  def top
    y
  end

  def bottom
    y + height
  end

  def size
    width * height
  end

  def intersection(other : Bounds)
    min_x = Math.min(right, other.right)
    max_x = Math.max(left, other.left)
    min_y = Math.min(bottom, other.bottom)
    max_y = Math.max(top, other.top)
    width = max_x - min_x
    height = max_y - min_y
    Bounds.new(min_x, min_y, width, height) if width > 0 && height > 0
  end
end

class Grid
  @bounds = [] of Bounds
  @direction : Direction?

  @x1 = 0_i64
  @y1 = 0_i64
  @x2 = 0_i64
  @y2 = 0_i64

  def apply(step : Step)
    x_off, y_off = step.direction.apply(step.amount)
    @x2 += x_off
    @y2 += y_off
    if @direction.try &.horizontal? == step.direction.vertical?
      add_bounds
      @x1 += @x2
      @y1 += @y2
      @direction = nil
    else
      @direction = step.direction
    end
  end

  private def add_bounds
    # TODO: Add inner square
    x = Math.min(@x1, @x2)
    y = Math.min(@y1, @y2)
    @bounds << Bounds.new(x, y, (@x2 - @x1).abs, (@y2 - @y1).abs)
  end

  def size
    size = @bounds.sum &.size
    @bounds.each_combination(2, true) do |(a, b)|
      intersection = a.intersection(b)
      size -= intersection.size if intersection
    end
    size
  end
end

grid = Grid.new
STDIN.each_line do |line|
  step = Step.parse(line)
  grid.apply(step)
end
puts grid.size
