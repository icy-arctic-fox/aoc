#!/usr/bin/env crystal

enum Cell : UInt8
  Empty
  Mirror1
  Mirror2
  VerticalSplit
  HorizontalSplit

  def self.from_char(char : Char) : self
    case char
    when '.'  then Empty
    when '/'  then Mirror1
    when '\\' then Mirror2
    when '|'  then VerticalSplit
    when '-'  then HorizontalSplit
    else           raise "Unknown cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .empty?            then '.'
    in .mirror1?          then '/'
    in .mirror2?          then '\\'
    in .vertical_split?   then '|'
    in .horizontal_split? then '-'
    end
  end
end

enum Direction : UInt8
  Left
  Right
  Up
  Down

  def offset
    case self
    in .left?  then {-1, 0}
    in .right? then {+1, 0}
    in .up?    then {0, -1}
    in .down?  then {0, +1}
    end
  end

  def as_flags
    case self
    in .left?  then Directions::Left
    in .right? then Directions::Right
    in .up?    then Directions::Up
    in .down?  then Directions::Down
    end
  end
end

@[Flags]
enum Directions : UInt8
  Left
  Right
  Up
  Down

  def includes?(direction : Direction)
    case direction
    in .left?  then left?
    in .right? then right?
    in .up?    then up?
    in .down?  then down?
    end
  end

  def |(direction : Direction) : self
    self | direction.as_flags
  end
end

record(Beam, x : Int32, y : Int32, direction : Direction) do
  def pos
    {x, y}
  end

  def apply(cell : Cell) : self | {self, self}
    if cell.mirror1? # /
      new_direction = case direction
                      in .left?  then Direction::Down
                      in .right? then Direction::Up
                      in .up?    then Direction::Right
                      in .down?  then Direction::Left
                      end
      apply(new_direction)
    elsif cell.mirror2? # \
      new_direction = case direction
                      in .left?  then Direction::Up
                      in .right? then Direction::Down
                      in .up?    then Direction::Left
                      in .down?  then Direction::Right
                      end
      apply(new_direction)
    elsif cell.vertical_split? && (direction.left? || direction.right?) # |
      {apply(:up), apply(:down)}
    elsif cell.horizontal_split? && (direction.up? || direction.down?) # -
      {apply(:left), apply(:right)}
    else
      apply(direction)
    end
  end

  def apply(direction : Direction) : self
    offset = direction.offset
    x = self.x + offset[0]
    y = self.y + offset[1]
    Beam.new(x, y, direction)
  end
end

class Grid
  @values : Array(Array(Directions))

  def initialize(@grid : Array(Array(Cell)))
    @values = @grid.map do |row|
      Array.new(row.size, Directions::None)
    end
  end

  def self.from_io(io : IO) : self
    grid = io.each_line.map do |line|
      line.chars.map { |char| Cell.from_char(char) }
    end.to_a
    new(grid)
  end

  def width
    @grid[0].size
  end

  def height
    @grid.size
  end

  def [](x, y)
    @values[y][x]
  end

  def []=(x, y, value)
    @values[y][x] = value
  end

  def energized
    @values.sum do |row|
      row.count do |value|
        !value.none?
      end
    end
  end

  def simulate(x = 0, y = 0, direction : Direction = :right)
    beams = [Beam.new(x, y, direction)]
    until beams.empty?
      beam = beams.pop
      simulate_beam(beam, beams)
    end
  end

  private def simulate_beam(beam : Beam, others : Array(Beam)) : Nil
    loop do
      return unless 0 <= beam.x < width
      return unless 0 <= beam.y < height

      directions = @values[beam.y][beam.x]
      return if directions.includes?(beam.direction)
      @values[beam.y][beam.x] |= beam.direction
      cell = @grid[beam.y][beam.x]
      result = beam.apply(cell)
      if result.is_a?(Tuple)
        return others.concat(result)
      else
        beam = result
      end
    end
  end

  def to_s(io : IO) : Nil
    @grid.each do |row|
      row.each do |cell|
        io << cell.to_char
      end
      io.puts
    end
  end
end

grid = Grid.from_io(STDIN)
grid.simulate
puts grid.energized
