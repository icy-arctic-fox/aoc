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
    in .north? then grid.ay += amount
    in .south? then grid.ay -= amount
    in .east?  then grid.ax += amount
    in .west?  then grid.ax -= amount
    in .left?  then grid.rotate_left(amount)
    in .right? then grid.rotate_right(amount)
    in .forward?
      grid.x += grid.ax * amount
      grid.y += grid.ay * amount
    end
  end

  def to_s(io : IO) : Nil
    io << action.to_char << amount
  end
end

class Grid
  property ax, ay
  property x = 0, y = 0

  def initialize(@ax = 0, @ay = 0)
  end

  def rotate_left(amount)
    rotate_right(-amount)
  end

  def rotate_right(amount)
    units = amount // 90 % 4
    @ax, @ay = case units
               when 0 then {@ax, @ay}
               when 1 then {@ay, -@ax}
               when 2 then {-@ax, -@ay}
               when 3 then {-@ay, @ax}
               else        raise "Invalid rotations #{units}"
               end
  end

  def dist
    x.abs + y.abs
  end
end

grid = Grid.new(10, 1)
STDIN.each_line do |line|
  instruction = Instruction.parse(line)
  instruction.apply(grid)
end
puts grid.dist
