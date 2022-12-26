#!/usr/bin/env crystal

struct Snafu
  DIGITS = ['0', '1', '2', '=', '-']
  OFFSET = 2

  getter value

  def initialize(@value : Int64)
  end

  def self.zero
    new(0)
  end

  def self.parse(string)
    value = 0_i64
    place = 1_i64
    string.reverse.each_char do |c|
      int = from_char(c).to_i64
      value += int * place
      place *= DIGITS.size
    end
    new(value)
  end

  private def self.from_char(c)
    case c
    when '=' then -2
    when '-' then -1
    when '0' then 0
    when '1' then 1
    when '2' then 2
    else          raise "Unrecognized SNAFU character #{c}"
    end
  end

  def +(other : Snafu)
    self.class.new(@value + other.value)
  end

  def to_s(io : IO) : Nil
    value = @value

    digits = [] of Char
    while value != 0
      value, int = value.divmod(5)
      value += 1 if int > OFFSET
      digits << DIGITS[int]
    end

    digits.reverse_each do |c|
      io << c
    end
  end
end

nums = STDIN.each_line.map { |line| Snafu.parse(line) }
puts nums.sum
