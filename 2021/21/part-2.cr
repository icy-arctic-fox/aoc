SIDES =  3
BOARD = 10
SCORE = 21
DEBUG = true

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
  enum TurnState
    Player1Roll1
    Player1Roll2
    Player1Roll3
    Player2Roll1
    Player2Roll2
    Player2Roll3

    def next
      case self
      in Player1Roll1 then Player1Roll2
      in Player1Roll2 then Player1Roll3
      in Player1Roll3 then Player2Roll1
      in Player2Roll1 then Player2Roll2
      in Player2Roll2 then Player2Roll3
      in Player2Roll3 then Player1Roll1
      end
    end
  end

  @player1 : PlayerState
  @player2 : PlayerState
  @turn_state : TurnState
  @roll_score : Int32

  def initialize(player1_position, player2_position)
    @player1 = PlayerState.new(player1_position)
    @player2 = PlayerState.new(player2_position)
    @turn_state = TurnState::Player1Roll1
    @roll_score = 0
  end

  def initialize(@player1, @player2, @turn_state, @roll_score)
  end

  def process
    case @turn_state
    when TurnState::Player1Roll3 then roll_move_player1
    when TurnState::Player2Roll3 then roll_move_player2
    else                              roll_add
    end
  end

  def winner
    case
    when @player1.win? then 1
    when @player2.win? then 2
    else                    0
    end
  end

  private def roll_add
    {
      GameState.new(@player1, @player2, @turn_state.next, @roll_score + 1),
      GameState.new(@player1, @player2, @turn_state.next, @roll_score + 2),
      GameState.new(@player1, @player2, @turn_state.next, @roll_score + 3),
    }
  end

  private def roll_move_player1
    {
      GameState.new(@player1.advance(@roll_score + 1), @player2, @turn_state.next, 0),
      GameState.new(@player1.advance(@roll_score + 2), @player2, @turn_state.next, 0),
      GameState.new(@player1.advance(@roll_score + 3), @player2, @turn_state.next, 0),
    }
  end

  private def roll_move_player2
    {
      GameState.new(@player1, @player2.advance(@roll_score + 1), @turn_state.next, 0),
      GameState.new(@player1, @player2.advance(@roll_score + 2), @turn_state.next, 0),
      GameState.new(@player1, @player2.advance(@roll_score + 3), @turn_state.next, 0),
    }
  end
end

class Multiverse
  getter player1_wins : Int64 = 0_i64
  getter player2_wins : Int64 = 0_i64

  @stack : Array(GameState)
  
  def initialize(player1_position, player2_position)
    initial_state = GameState.new(player1_position, player2_position)
    @stack = [initial_state]
  end

  def process
    return true if @stack.empty?

    current = @stack.pop
    states = current.process
    states.each do |state|
      case state.winner
      when 0 then @stack << state
      when 1 then @player1_wins += 1
      when 2 then @player2_wins += 1
      end
    end

    false
  end
end

positions = STDIN.each_line(chomp: true).map do |line|
  m = line.match(/\d+$/)
  raise "Missing player position" unless m

  m[0].to_i
end.to_a

multiverse = Multiverse.new(positions[0], positions[1])
loop do
  break if multiverse.process

  if DEBUG
    games = multiverse.player1_wins + multiverse.player2_wins
    puts games if games % 10_000_000 == 0
  end
end
puts Math.max(multiverse.player1_wins, multiverse.player2_wins)
