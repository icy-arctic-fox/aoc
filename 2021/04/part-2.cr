require "bit_array"

ROWS  = 5
COLS  = 5
CELLS = ROWS * COLS

private def index(row, col)
  row * COLS + col
end

class Board
  @cells : StaticArray(Int32, CELLS)
  @marks = BitArray.new(CELLS)

  def initialize(@cells)
  end

  def self.read(io = STDIN) : self
    cells = StaticArray(Int32, CELLS).new(0)

    ROWS.times do |row|
      row_cells = io.gets(chomp: true).try(&.split)
      raise "Missing row cells" unless row_cells

      COLS.times do |col|
        cells[index(row, col)] = row_cells[col].to_i
      end
    end

    new(cells)
  end

  def mark(call)
    return unless index = @cells.index(call)

    @marks[index] = true
  end

  def win?
    ROWS.times.any? { |row| row_win?(row) } ||
      COLS.times.any? { |col| col_win?(col) }
  end

  def score(call)
    unmarked * call
  end

  private def unmarked
    value = 0
    @cells.zip(@marks) do |cell, mark|
      value += cell unless mark
    end
    value
  end

  private def row_win?(row)
    COLS.times.all? { |col| marked?(row, col) }
  end

  private def col_win?(col)
    ROWS.times.all? { |row| marked?(row, col) }
  end

  private def left_diag_win?
    ROWS.times.all? { |i| marked?(i, i) }
  end

  private def right_diag_win?
    COLS.times.all? { |i| marked?(i, COLS - i - 1) }
  end

  private def marked?(row, col)
    @marks[index(row, col)]
  end

  def to_s(io)
    ROWS.times do |row|
      COLS.times do |col|
        cell = @cells[index(row, col)]
        if marked?(row, col)
          io.printf("[%3d]", cell)
        else
          io.printf(" %3d ", cell)
        end
      end
      io.puts
    end
  end
end

calls = gets(chomp: true).try(&.split(',').map(&.to_i))
raise "Missing calls" unless calls

boards = [] of Board
while gets
  boards << Board.read
end

calls.each do |call|
  boards.each(&.mark(call))
  remaining = boards.reject(&.win?)
  if remaining.empty?
    puts boards.min_of(&.score(call))
    break
  end
  boards = remaining
end
