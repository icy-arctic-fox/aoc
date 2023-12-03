#!/usr/bin/env crystal

alias Cell = Int32 | Char | Nil

class Schematic
  def initialize(@rows : Array(Array(Cell)))
  end

  def self.from_io(io : IO) : self
    rows = io.each_line.map do |line|
      numbers = Array(Cell).new(line.size, nil)
      line.scan(/\d+/) do |match|
        number = match[0].to_i
        (match.begin...match.end).each do |i|
          numbers[i] = number
        end
      end
      line.chars.each_with_index do |char, i|
        numbers[i] = char if !char.number? && char != '.'
      end
      numbers
    end
    new(rows.to_a)
  end

  def width
    @rows[0].size
  end

  def height
    @rows.size
  end

  def [](x : Int32, y : Int32) : Cell
    @rows[y][x]
  end

  def each_symbol(& : Int32, Int32, Char -> _)
    @rows.each_with_index do |cols, y|
      cols.each_with_index do |cell, x|
        yield x, y, cell if cell.is_a?(Char)
      end
    end
  end

  def each_neighbor(x : Int32, y : Int32, & : Int32, Int32, Cell -> _)
    min_x = Math.max(0, x - 1)
    max_x = Math.min(width, x + 1)
    min_y = Math.max(0, y - 1)
    max_y = Math.min(height, y + 1)
    (min_x..max_x).each do |cx|
      (min_y..max_y).each do |cy|
        next if cx == x && cy == y
        yield cx, cy, self[cx, cy]
      end
    end
  end

  def each_neighbor_number(x : Int32, y : Int32, & : Int32 -> _)
    numbers = Set(Int32).new
    each_neighbor(x, y) do |cx, cy, cell|
      numbers << cell if cell.is_a?(Int32)
    end
    numbers.each { |number| yield number }
  end

  def each_symbol_number(& : Int32, Int32, Char, Int32 -> _)
    each_symbol do |x, y, char|
      each_neighbor_number(x, y) do |number|
        yield x, y, char, number
      end
    end
  end
end

schematic = Schematic.from_io(STDIN)
sum = 0
schematic.each_symbol_number do |x, y, char, number|
  STDERR.puts "(#{x}, #{y}) #{char} #{number}"
  sum += number
end
puts sum
