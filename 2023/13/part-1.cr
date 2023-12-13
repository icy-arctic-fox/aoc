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
  def initialize(@grid : Array(Array(Cell)))
  end

  def self.from_lines(lines : Array(String)) : self
    grid = lines.map do |line|
      line.chars.map { |char| Cell.from_char(char) }
    end.to_a
    new(grid)
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

  def width
    @grid[0].size
  end

  def height
    @grid.size
  end

  def horizontal_reflection
    height.times.each_cons_pair do |i, j|
      next unless compare_rows(i, j)

      k = i - 1
      l = j + 1
      result = loop do
        break true if k < 0 || l >= height
        break false unless compare_rows(k, l)
        k -= 1
        l += 1
      end
      next unless result

      return i + 1
    end
  end

  private def compare_rows(i, j)
    @grid[i] == @grid[j]
  end

  def vertical_reflection
    width.times.each_cons_pair do |i, j|
      next unless compare_cols(i, j)

      k = i - 1
      l = j + 1
      result = loop do
        break true if k < 0 || l >= width
        break false unless compare_cols(k, l)
        k -= 1
        l += 1
      end
      next unless result

      return i + 1
    end
  end

  private def compare_cols(i, j)
    height.times do |y|
      return false unless @grid[y][i] == @grid[y][j]
    end
    true
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
