#!/usr/bin/env crystal

require "bit_array"

class Grid
  include Enumerable(Bool)

  @grid = BitArray.new(30)
  @x = (0..5)
  @y = (-4..0)
  @segments : Array({x: Int32, y: Int32})

  def initialize(segments = 2)
    @segments = Array.new(segments, {x: 0, y: 0})
  end

  def head
    @segments.first
  end

  private def head=(head)
    @segments[0] = head
  end

  def tail
    @segments.last
  end

  private def tail=(tail)
    @segments[-1] = tail
  end

  def move(direction, amount) : Nil
    self[*head.values] = self[*head.values]
    case direction
    when 'U' then amount.times { move_up }
    when 'D' then amount.times { move_down }
    when 'L' then amount.times { move_left }
    when 'R' then amount.times { move_right }
    end
  end

  def move_up : Nil
    self.head = head.merge(y: head[:y] - 1)
    adjust_tail
  end

  def move_down : Nil
    self.head = head.merge(y: head[:y] + 1)
    adjust_tail
  end

  def move_left : Nil
    self.head = head.merge(x: head[:x] - 1)
    adjust_tail
  end

  def move_right : Nil
    self.head = head.merge(x: head[:x] + 1)
    adjust_tail
  end

  private def adjust_tail : Nil
    @segments.each_index.each_cons_pair do |h, t|
      head = @segments[h]
      tail = @segments[t]
      x_diff = head[:x] - tail[:x]
      y_diff = head[:y] - tail[:y]
      # This is awful and should be replaced with a more mathematical solution.
      if x_diff.abs <= 1 && y_diff > 1
        tail = {x: head[:x], y: head[:y] - 1}
      elsif x_diff.abs <= 1 && y_diff < -1
        tail = {x: head[:x], y: head[:y] + 1}
      elsif x_diff > 1 && y_diff.abs <= 1
        tail = {x: head[:x] - 1, y: head[:y]}
      elsif x_diff < -1 && y_diff.abs <= 1
        tail = {x: head[:x] + 1, y: head[:y]}
      elsif x_diff == 0 && y_diff > 1
        tail = {x: head[:x], y: head[:y] - 1}
      elsif x_diff == 0 && y_diff < -1
        tail = {x: head[:x], y: head[:y] + 1}
      elsif x_diff > 1 && y_diff == 0
        tail = {x: head[:x] - 1, y: head[:y]}
      elsif x_diff < -1 && y_diff == 0
        tail = {x: head[:x] + 1, y: head[:y]}
      elsif x_diff > 1 && y_diff > 1
        tail = {x: head[:x] - 1, y: head[:y] - 1}
      elsif x_diff > 1 && y_diff < -1
        tail = {x: head[:x] - 1, y: head[:y] + 1}
      elsif x_diff < -1 && y_diff > 1
        tail = {x: head[:x] + 1, y: head[:y] - 1}
      elsif x_diff < -1 && y_diff < -1
        tail = {x: head[:x] + 1, y: head[:y] + 1}
      end
      @segments[t] = tail
    end
    self[*tail.values] = true
  end

  def width
    @x.size
  end

  def height
    @y.size
  end

  def each
    @grid.each { |value| yield value }
  end

  def each_coords
    @y.each do |y|
      @x.each do |x|
        yield x, y
      end
    end
  end

  def each_with_coords
    each_coords do |x, y|
      yield self[x, y], x, y
    end
  end

  def [](x, y)
    return false unless x.in?(@x) && y.in?(@y)

    index = coords_to_index(x, y)
    @grid[index]
  end

  def []=(x, y, value)
    if !x.in?(@x) || !y.in?(@y)
      resize_to_contain(x, y)
    end

    index = coords_to_index(x, y)
    @grid[index] = value
  end

  def to_s(io : IO) : Nil
    i = 0
    @y.each do |y|
      @x.each do |x|
        c = @grid[i] ? '#' : '.'

        @segments.each_with_index do |segment, j|
          next unless segment == {x: x, y: y}

          c = case j
              when 0                  then 'H'
              when @segments.size - 1 then 'T'
              else                         j.to_s[0]
              end
        end

        io << c
        i += 1
      end
      io.puts
    end
  end

  private def coords_to_index(x, y)
    coords_to_index(x, y, @x, @y)
  end

  private def coords_to_index(x, y, x_range, y_range)
    (y - y_range.begin) * x_range.size + (x - x_range.begin)
  end

  private def resize_to_contain(x, y)
    x_min = {@x.begin, x}.min
    x_max = {@x.end, x}.max
    y_min = {@y.begin, y}.min
    y_max = {@y.end, y}.max
    resize(x_min..x_max, y_min..y_max)
  end

  private def resize(new_x, new_y)
    new_grid = BitArray.new(new_x.size * new_y.size)
    each_with_coords do |value, x, y|
      next unless value

      index = coords_to_index(x, y, new_x, new_y)
      new_grid[index] = value
    end

    @grid = new_grid
    @x = new_x
    @y = new_y
  end
end

grid = Grid.new(10)
STDIN.each_line do |line|
  raise "Invalid line: #{line}" unless m = line.match(/([UDLR])\s+(\d+)/)

  dir = m[1][0]
  amount = m[2].to_i
  grid.move(dir, amount)
end
puts grid.count(true)
