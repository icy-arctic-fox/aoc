#!/usr/bin/env crystal

enum Cell : UInt8
  Ash
  Rock

  def self.from_char(char : Char) : self
    case char
    when '.' then Ash
    when '#' then Rock
    else          raise "Unrecognized cell '#{char}'"
    end
  end

  def to_char : Char
    case self
    in .ash?  then '.'
    in .rock? then '#'
    end
  end
end

class Grid
  getter width

  def initialize(@grid : Array(Int32), @width : Int32)
  end

  def self.from_lines(lines : Array(String)) : self
    width = 0
    grid = lines.map do |line|
      cells = line.chars.map { |char| Cell.from_char(char) }
      width = cells.size
      value = 0
      cells.each_with_index do |cell, i|
        value |= 1 << i if cell.rock?
      end
      value
    end.to_a
    new(grid, width)
  end

  def self.from_io(io : IO) : Array(self)
    grids = [] of self
    while line = io.gets
      lines = [line]
      io.each_line do |l|
        break if l.empty?
        lines << l
      end
      grids << Grid.from_lines(lines)
    end
    grids
  end

  def height
    @grid.size
  end

  def horizontal_reflection
    height.times.each_cons_pair do |i, j|
      match, diff = compare_rows(i, j)
      next unless match

      k = i - 1
      l = j + 1
      result = loop do
        break !diff if k < 0 || l >= height
        match, diff = compare_rows(k, l, diff)
        break false unless match
        k -= 1
        l += 1
      end
      next unless result

      return i + 1
    end
  end

  private def compare_rows(i, j, diff = true)
    xor = @grid[i] ^ @grid[j]
    if xor == 0
      {true, diff}
    elsif xor.popcount == 1 && diff
      {true, false}
    else
      {false, diff}
    end
  end

  def vertical_reflection
    width.times.each_cons_pair do |i, j|
      match, diff = compare_cols(i, j)
      next unless match

      k = i - 1
      l = j + 1
      result = loop do
        break !diff if k < 0 || l >= width
        match, diff = compare_cols(k, l, diff)
        break false unless match
        k -= 1
        l += 1
      end
      next unless result

      return i + 1
    end
  end

  private def compare_cols(i, j, diff = true)
    col1 = col_to_int(i)
    col2 = col_to_int(j)
    xor = col1 ^ col2
    if xor == 0
      {true, diff}
    elsif xor.popcount == 1 && diff
      {true, false}
    else
      {false, diff}
    end
  end

  private def col_to_int(i)
    value = 0
    height.times do |y|
      value |= 1 << y if @grid[y].bit(i) == 1
    end
    value
  end

  def value
    if hr = horizontal_reflection
      hr * 100
    elsif vr = vertical_reflection
      vr
    else
      raise "Failed to find reflection"
    end
  end
end

grids = Grid.from_io(STDIN)
puts grids.sum(&.value)
