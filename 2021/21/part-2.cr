SIDES =  3
ROLLS =  3
BOARD = 10
SCORE = 21

SIDE_VALUES = (1..SIDES).to_a

record PlayerState, position : Int32, score : Int32 do
  def initialize(@position)
    @score = 0
  end

  def advance(amount)
    position = (@position + amount - 1) % BOARD + 1
    score = @score + position
    PlayerState.new(position, score)
  end

  def win?
    @score >= SCORE
  end
end

struct GameState
  @player1 : PlayerState
  @player2 : PlayerState

  def initialize(@player1 : PlayerState, @player2 : PlayerState)
  end

  def initialize(player1_position : Int32, player2_position : Int32)
    @player1 = PlayerState.new(player1_position)
    @player2 = PlayerState.new(player2_position)
  end

  def each_sub_state
    SIDE_VALUES.each_repeated_permutation(ROLLS, reuse: true) do |dice|
      amount = dice.sum
      yield GameState.new(@player2, @player1.advance(amount))
    end
  end

  def winner
    case
    when @player1.win? then 1
    when @player2.win? then 2
    else                    0
    end
  end
end

struct Multiverse
  @known = Hash(GameState, Tuple(Int64, Int64)).new

  def process(current : GameState)
    if known = @known[current]?
      return known
    end

    scores = case current.winner
             when 1 then {1_i64, 0_i64}
             when 2 then {0_i64, 1_i64}
             else
               tally = {0_i64, 0_i64}
               current.each_sub_state do |state|
                 p2_wins, p1_wins = process(state)
                 tally = {tally[0] + p1_wins, tally[1] + p2_wins}
               end
               tally
             end

    @known[current] = scores
    scores
  end
end

positions = STDIN.each_line(chomp: true).map do |line|
  m = line.match(/\d+$/)
  raise "Missing player position" unless m

  m[0].to_i
end.to_a

start_state = GameState.new(positions[0], positions[1])
puts Multiverse.new.process(start_state).max
