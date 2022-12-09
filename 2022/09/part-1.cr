#!/usr/bin/env crystal

require "bit_array"

class Grid
  include Enumerable(Bool)

  @grid = BitArray.new(1)
  @x = (0..0)
  @y = (0..0)

  getter head = {x: 0, y: 0}
  getter tail = {x: 0, y: 0}

  def move(direction, amount) : Nil
    case direction
    when 'U' then amount.times { move_up }
    when 'D' then amount.times { move_down }
    when 'L' then amount.times { move_left }
    when 'R' then amount.times { move_right }
    end
  end

  def move_up : Nil
    @head = @head.merge(y: @head[:y] - 1)
    adjust_tail
  end

  def move_down : Nil
    @head = @head.merge(y: @head[:y] + 1)
    adjust_tail
  end

  def move_left : Nil
    @head = @head.merge(x: @head[:x] - 1)
    adjust_tail
  end

  def move_right : Nil
    @head = @head.merge(x: @head[:x] + 1)
    adjust_tail
  end

  private def adjust_tail : Nil
    adjust_tail_dimension(:x, :y)
    adjust_tail_dimension(:y, :x)
    self[*tail.values] = true
  end

  private macro adjust_tail_dimension(d, e)
    min = @head[{{d}}] - 1
    max = @head[{{d}}] + 1

    if @tail[{{d}}] < min
      @tail = { {{d.id}}: min, {{e.id}}: @head[{{e}}] }
    elsif @tail[{{d}}] > max
      @tail = { {{d.id}}: max, {{e.id}}: @head[{{e}}] }
    end
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
        c = case
            when @head[:x] == x && @head[:y] == y then 'H'
            when @tail[:x] == x && @tail[:y] == y then 'T'
            when @grid[i]                         then '#'
            else                                       '.'
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

grid = Grid.new
STDIN.each_line do |line|
  raise "Invalid line: #{line}" unless m = line.match(/([UDLR])\s+(\d+)/)

  dir = m[1][0]
  amount = m[2].to_i
  grid.move(dir, amount)
end
puts grid.count(true)
