#!/usr/bin/env crystal

enum Action
  North
  South
  East
  West
  Left
  Right
  Forward

  def self.from_char(c : Char)
    case c
    when 'N' then North
    when 'S' then South
    when 'E' then East
    when 'W' then West
    when 'L' then Left
    when 'R' then Right
    when 'F' then Forward
    else          raise "Unknown action character '#{c}'"
    end
  end

  def to_char
    case self
    in North   then 'N'
    in South   then 'S'
    in East    then 'E'
    in West    then 'W'
    in Left    then 'L'
    in Right   then 'R'
    in Forward then 'F'
    end
  end
end

record Instruction, action : Action, amount : Int32 do
  def self.parse(string) : self
    action = Action.from_char(string[0])
    amount = string.lchop.to_i
    new(action, amount)
  end

  def apply(grid)
    case action
    in .north?   then grid.y -= amount
    in .south?   then grid.y += amount
    in .east?    then grid.x += amount
    in .west?    then grid.x -= amount
    in .left?    then grid.direction = grid.direction.rotate_left(amount)
    in .right?   then grid.direction = grid.direction.rotate_right(amount)
    in .forward? then grid.direction.apply(grid, amount)
    end
  end

  def to_s(io : IO) : Nil
    io << action.to_char << amount
  end
end

enum Direction
  East  = 0
  South = 1
  West  = 2
  North = 3

  def rotate_left(amount) : self
    rotate_right(-amount)
  end

  def rotate_right(amount) : self
    self.class.from_value((value + amount // 90) % 4)
  end

  def apply(grid, amount)
    case self
    in North then grid.y -= amount
    in South then grid.y += amount
    in East  then grid.x += amount
    in West  then grid.x -= amount
    end
  end
end

class Grid
  property x = 0, y = 0
  property direction = Direction::East

  def dist
    x.abs + y.abs
  end
end

grid = Grid.new
STDIN.each_line do |line|
  instruction = Instruction.parse(line)
  instruction.apply(grid)
end
puts grid.dist
