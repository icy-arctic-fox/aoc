enum Cell
  Void
  Open
  Wall
  Amber
  Bronze
  Copper
  Desert

  def self.from_char(char) : self
    case char
    when ' ' then Void
    when '.' then Open
    when '#' then Wall
    when 'A' then Amber
    when 'B' then Bronze
    when 'C' then Copper
    when 'D' then Desert
    else          raise "Unexpected cell char #{char}"
    end
  end

  def char
    case self
    in .void?   then ' '
    in .open?   then '.'
    in .wall?   then '#'
    in .amber?  then 'A'
    in .bronze? then 'B'
    in .copper? then 'C'
    in .desert? then 'D'
    end
  end

  def amphipod?
    amber? || bronze? || copper? || desert?
  end

  def energy
    case self
    when .amber?  then Energy::Amber
    when .bronze? then Energy::Bronze
    when .copper? then Energy::Copper
    when .desert? then Energy::Desert
    else               raise "Can't get energy of non-amphipod"
    end.value
  end
end

enum Energy
  Amber  =    1
  Bronze =   10
  Copper =  100
  Desert = 1000
end

struct Grid
  AMBER_CELL_1  = {3, 2}
  AMBER_CELL_2  = {3, 3}
  BRONZE_CELL_1 = {5, 2}
  BRONZE_CELL_2 = {5, 3}
  COPPER_CELL_1 = {7, 2}
  COPPER_CELL_2 = {7, 3}
  DESERT_CELL_1 = {9, 2}
  DESERT_CELL_2 = {9, 3}
  HALLWAY       = 1..11

  @grid : Array(Cell)

  def initialize(@width : Int32, @height : Int32, @grid : Array(Cell))
  end

  def initialize(@width : Int32, @height : Int32, & : Int32, Int32 -> Cell)
    size = width * height
    @grid = Array.new(size) do |i|
      x, y = coords(i)
      yield x, y
    end
  end

  def dup
    Grid.new(@width, @height, @grid.dup)
  end

  def each_amphipod
    @grid.each_with_index do |cell, i|
      yield cell, coords(i) if cell.amphipod?
    end
  end

  def solution?
    @grid[index(*AMBER_CELL_1)].amber? && @grid[index(*AMBER_CELL_2)].amber? &&
      @grid[index(*BRONZE_CELL_1)].bronze? && @grid[index(*BRONZE_CELL_2)].bronze? &&
      @grid[index(*COPPER_CELL_1)].copper? && @grid[index(*COPPER_CELL_2)].copper? &&
      @grid[index(*DESERT_CELL_1)].desert? && @grid[index(*DESERT_CELL_2)].desert?
  end

  def [](x, y)
    raise IndexError.new("Coordinates (#{x}, #{y}) out of range") if x < 0 || x >= @width || y < 0 || y >= @height

    @grid[index(x, y)]
  end

  def []=(x, y, cell)
    raise IndexError.new("Coordinates (#{x}, #{y}) out of range") if x < 0 || x >= @width || y < 0 || y >= @height

    @grid[index(x, y)] = cell
  end

  private def coords(index)
    y, x = index.divmod(@width)
    {x, y}
  end

  private def index(x, y)
    y * @width + x
  end

  def to_s(io : IO) : Nil
    @grid.each_with_index do |cell, i|
      io.puts if i % @width == 0
      io << cell.char
    end
  end

  def hash(hasher)
    hasher = @width.hash(hasher)
    hasher = @height.hash(hasher)
    @grid.each(&.hash(hasher))
    hasher
  end
end

struct Move
  getter from : Tuple(Int32, Int32)
  getter to : Tuple(Int32, Int32)
  getter energy : Int32

  def initialize(@from, @to, @energy)
  end

  def apply(grid)
    grid.dup.tap do |new|
      content = new[*from]
      new[*to] = content
      new[*from] = Cell::Open
    end
  end
end

struct State
  getter grid : Grid
  getter moves : Array(Move)
  getter energy : Int32
  getter seen : Set(Grid)

  def initialize(@grid, @moves = [] of Move, @energy = 0, @seen = Set(Grid).new)
  end

  def apply(move)
    State.new(
      move.apply(grid),
      moves + [move],
      energy + move.energy,
      @seen.dup.add(grid)
    )
  end

  def repeat?(move)
    move.apply(grid).in?(seen)
  end
end

class Solver
  @solutions = Array(Array(Move)).new
  @max_energy = Int32::MAX

  def initialize(@initial : Grid)
  end

  def solve
    @solutions = Array(Array(Move)).new
    @max_energy = Int32::MAX

    state = State.new(@initial)
    each_move(state) do |move|
      puts state.apply(move).grid
      backtrack(state, move)
    end

    @solutions
  end

  private def backtrack(state, move)
    return unless legal?(state.grid, move)

    next_state = state.apply(move)
    return if reject?(next_state)
    return if next_state.energy > @max_energy

    if next_state.grid.solution?
      @solutions << next_state.moves
      @max_energy = Math.min(next_state.energy, @max_energy)
      puts "SOLUTION:"
      puts next_state.moves
      puts next_state.grid
    end

    each_move(next_state) do |move|
      backtrack(next_state, move)
    end
  end

  private def reject?(state)
    hallway_blocked?(state)
  end

  private def hallway_blocked?(state)
    state.grid.each_amphipod do |cell, coords|
      next unless hallway?(*coords)

      target = cell_target(cell)
      state.grid.each_amphipod do |cell2, coords2|
        next if coords == coords2
        next unless hallway?(*coords2)

        target2 = cell_target(cell2)
        return true if coords[0] < target && target >= coords2[0] && coords2[0] > target2 && target2 <= coords[0]
      end
    end

    false
  end

  private def each_move(state)
    state.grid.each_amphipod do |cell, coords|
      flood(state.grid, coords).each do |dest, dist|
        move = Move.new(coords, dest, cell.energy * dist)
        yield move if state.grid[*dest].open? && !state.repeat?(move)
      end
    end
  end

  private def flood(grid, coords)
    fill = Array(Tuple(Tuple(Int32, Int32), Int32)).new(16)
    queue = [{coords, 0}]
    while current = queue.pop?
      next if fill.find { |f| f[0] == current[0] }

      fill << current
      each_direction(current[0]) do |dir|
        queue << {dir, current[1] + 1} if grid[*dir].open?
      end
    end
    fill
  end

  private def each_direction(coords)
    x, y = coords
    yield({x - 1, y})
    yield({x + 1, y})
    yield({x, y - 1})
    yield({x, y + 1})
  end

  private def legal?(grid, move)
    return false if entrance?(*move.to)
    return false if hallway?(*move.from) && (!dest_room?(grid[*move.from], move.to) || mixed_room?(grid, grid[*move.from], move.to))
    return false if hallway?(*move.from) && hallway?(*move.to)

    true
  end

  private def entrance?(x, y)
    y == 1 && x.in?(3, 5, 7, 9)
  end

  private def hallway?(x, y)
    y == 1 && x.in?(Grid::HALLWAY)
  end

  private def dest_room?(cell, coords)
    case cell
    when .amber?  then coords == Grid::AMBER_CELL_1 || coords == Grid::AMBER_CELL_2
    when .bronze? then coords == Grid::BRONZE_CELL_1 || coords == Grid::BRONZE_CELL_2
    when .copper? then coords == Grid::COPPER_CELL_1 || coords == Grid::COPPER_CELL_2
    when .desert? then coords == Grid::DESERT_CELL_1 || coords == Grid::DESERT_CELL_2
    else               false
    end
  end

  private def mixed_room?(grid, cell, coords)
    case coords
    when Grid::AMBER_CELL_1  then grid[*Grid::AMBER_CELL_2] != cell
    when Grid::AMBER_CELL_2  then grid[*Grid::AMBER_CELL_1] != cell
    when Grid::BRONZE_CELL_1 then grid[*Grid::BRONZE_CELL_2] != cell
    when Grid::BRONZE_CELL_2 then grid[*Grid::BRONZE_CELL_1] != cell
    when Grid::COPPER_CELL_1 then grid[*Grid::COPPER_CELL_2] != cell
    when Grid::COPPER_CELL_2 then grid[*Grid::COPPER_CELL_1] != cell
    when Grid::DESERT_CELL_1 then grid[*Grid::DESERT_CELL_2] != cell
    when Grid::DESERT_CELL_2 then grid[*Grid::DESERT_CELL_1] != cell
    else                          raise "Coords #{coords} do not refer to a room"
    end
  end

  private def cell_target(cell)
    case cell
               when .amber?  then 3
               when .bronze? then 5
               when .copper? then 7
               when .desert? then 9
               else               raise "Unexpected non-amphipod"
               end
  end
end

input = STDIN.each_line(chomp: true).map(&.chars).to_a
width = input.max_of(&.size)
height = input.size

grid = Grid.new(width, height) do |x, y|
  Cell.from_char(input[y].fetch(x, ' '))
end
puts grid

solutions = Solver.new(grid).solve
puts solutions
