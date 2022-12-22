#!/usr/bin/env crystal

require "string_scanner"

module Flat2D
  abstract def width
  abstract def height
  abstract def unsafe_fetch(index : Int)

  def []?(x, y)
    return unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    unsafe_fetch(index)
  end

  def [](x, y)
    raise IndexError.new unless in_bounds?(x, y)

    index = coords_to_index(x, y)
    unsafe_fetch(index)
  end

  private def in_bounds?(x, y)
    x.in?(0...width) && y.in?(0...height)
  end

  private def coords_to_index(x, y)
    y * width + x
  end

  private def index_to_coords(index)
    y, x = index.divmod(width)
    {x, y}
  end
end

enum Cell
  Void = 0
  Open = 1
  Wall = 2

  def self.from_char(c)
    case c
    when ' ' then Void
    when '.' then Open
    when '#' then Wall
    else          raise "Unknown cell character #{c}"
    end
  end

  def char
    case self
    in Void then ' '
    in Open then '.'
    in Wall then '#'
    end
  end

  def to_s(io : IO) : Nil
    io << char
  end
end

enum Direction
  Right = 0
  Down  = 1
  Left  = 2
  Up    = 3

  def turn_right
    self.class.from_value((value + 1) % 4)
  end

  def turn_left
    self.class.from_value((value - 1) % 4)
  end

  def char
    case self
    in Right then '>'
    in Down  then 'V'
    in Left  then '<'
    in Up    then '^'
    end
  end

  def to_s(io : IO) : Nil
    io << char
  end
end

class Board
  include Flat2D

  getter width : Int32
  getter height : Int32

  property position : {Int32, Int32}
  property direction = Direction::Right

  @cells : Array(Cell)

  def initialize(@width, @height, @cells)
    raise ArgumentError.new("Size mismatch - #{@width} x #{@height} != #{@cells.size}") if @width * @height != @cells.size

    x = @cells.index! &.open?
    @position = {x, 0}
  end

  def self.read(io : IO) : self
    rows = [] of String
    io.each_line do |line|
      break if line.empty?

      rows << line
    end

    height = rows.size
    width = rows.max_of &.size
    cells = [] of Cell

    rows.each do |row|
      row.each_char do |c|
        cells << Cell.from_char(c)
      end
      (width - row.size).times { cells << Cell::Void }
    end

    new(width, height, cells)
  end

  def row
    position[1] + 1
  end

  def column
    position[0] + 1
  end

  def password
    1_000 * row +
      4 * column +
      direction.to_i
  end

  def unsafe_fetch(index : Int)
    @cells.unsafe_fetch(index)
  end
end

abstract struct Instruction
  abstract def execute(board)
end

struct AdvanceInstruction < Instruction
  def initialize(@amount : Int32)
  end

  def execute(board)
    relative = relative_direction(board)
    @amount.times do
      x, y = advance(board, relative)

      while (cell = board[x, y]?).nil? || cell.void?
        x, y = advance(board, relative)
        x %= board.width
        y %= board.height
        board.position = {x, y}
      end

      if board[x, y].wall?
        puts "Hit wall at (#{x}, #{y})" if DEBUG
        break
      end

      puts "Advance to (#{x}, #{y})" if DEBUG
      board.position = {x, y}
    end
  end

  private def relative_direction(board)
    case board.direction
    in .right? then {1, 0}
    in .down?  then {0, 1}
    in .left?  then {-1, 0}
    in .up?    then {0, -1}
    end
  end

  private def advance(board, relative)
    x = board.position[0] + relative[0]
    y = board.position[1] + relative[1]
    {x, y}
  end
end

struct TurnLeftInstruction < Instruction
  def execute(board)
    board.direction = board.direction.turn_left
    puts "Turn left, now facing #{board.direction}"
  end
end

struct TurnRightInstruction < Instruction
  def execute(board)
    board.direction = board.direction.turn_right
    puts "Turn right, now facing #{board.direction}"
  end
end

class InstructionIterator
  include Iterator(Instruction)

  def initialize(string)
    @scanner = StringScanner.new(string)
  end

  def next
    return stop if @scanner.eos?

    if @scanner.scan(/L/)
      TurnLeftInstruction.new
    elsif @scanner.scan(/R/)
      TurnRightInstruction.new
    elsif string = @scanner.scan(/\d+/)
      amount = string.to_i
      AdvanceInstruction.new(amount)
    else
      raise "Unexpected instruction"
    end
  end
end

DEBUG = ARGV.shift? == "-d"

board = Board.read(STDIN)
instructions = STDIN.gets.not_nil!
instructions = InstructionIterator.new(instructions)
instructions.each do |instruction|
  puts instruction if DEBUG
  instruction.execute(board)
end
puts board.password
