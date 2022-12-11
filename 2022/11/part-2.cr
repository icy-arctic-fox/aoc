#!/usr/bin/env crystal

struct Operation
  def initialize(@operation : Char, @modifier : Int32)
  end

  def self.parse(line)
    m = line.match(/Operation:\s+new = old ([*+]) ((\d+)|old)/)
    raise "Malformed operation" unless m

    if m[2] == "old"
      operation = '^'
      modifier = 2
    else
      operation = m[1][0]
      modifier = m[2].to_i
    end
    new(operation, modifier)
  end

  def apply(value)
    case @operation
    when '*' then value * @modifier
    when '+' then value + @modifier
    when '^' then value ** @modifier
    else          raise "Unrecognized operation '#{@operation}'"
    end
  end

  def to_s(io : IO) : Nil
    io << "  Operation: new = old " << @operation << ' ' << @modifier
  end
end

struct Test
  def initialize(@divisor : Int32, @true : Int32, @false : Int32)
  end

  def self.parse(io) : self
    condition = io.gets || raise "Unexpected end of input"
    m = condition.match(/Test:\s+divisible by\s+(\d+)/)
    raise "Malformed test condition" unless m

    divisor = m[1].to_i
    true_monkey = nil
    false_monkey = nil

    2.times do
      line = io.gets || raise "Unexpected end of input"
      m = line.match(/If (true|false):\s+throw to monkey\s+(\d+)/)
      raise "Malformed test action" unless m

      monkey = m[2].to_i
      if m[1] == "true"
        true_monkey = monkey
      else
        false_monkey = monkey
      end
    end

    raise "Missing action for test" if true_monkey.nil? || false_monkey.nil?
    new(divisor, true_monkey, false_monkey)
  end

  def perform(value, monkeys) : Nil
    monkey = if value.divisible_by?(@divisor)
               monkeys[@true]
             else
               monkeys[@false]
             end
    monkey.add(value)
  end

  def to_s(io : IO) : Nil
    io << "  Test: divisible by " << @divisor
    io.puts
    io << "    If true: throw to monkey " << @true
    io.puts
    io << "    If false: throw to monkey " << @false
  end
end

struct PrimeFactorization
  PRIME_CACHE = {} of Int32 => Bool

  def initialize(@factors : Hash(Int32, Int32))
  end

  def initialize(value)
    @factors = factorize(value)
  end

  def divisible_by?(value : Int)
    raise "Can only check divisible by with primes!" unless prime?(value)

    @factors.has_key?(value)
  end

  def *(value : Int)
    factors = factorize(value)
    factors = merge(factors)
    self.class.new(factors)
  end

  def +(value : Int)
    raise "oof"
  end

  def **(value : Int)
    factors = @factors.transform_values do |count|
      count * value
    end
    self.class.new(factors)
  end

  def to_s(io : IO) : Nil
    @factors.join(io, " x ") do |(prime, count), h|
      h << prime << '^' << count
    end
  end

  private def factorize(value, factors = {} of Int32 => Int32) : Hash
    if prime?(value)
      factors[value] = factors.fetch(value, 0) + 1
      return factors
    end

    3.step(to: value // 2, by: 2).find do |i|
      next unless prime?(i)

      count, mod = value.divmod(i)
      next unless mod == 0

      factors[i] = factors.fetch(i, 0) + 1
      return factorize(count, factors)
    end

    factors
  end

  private def prime?(value)
    return true if value == 2
    return false if value.divisible_by?(2)

    PRIME_CACHE.fetch(value) do
      prime = 3.step(to: value // 2, by: 2).none? { |i| value.divisible_by?(i) }
      PRIME_CACHE[value] = prime
    end
  end

  private def merge(factors) : Hash
    @factors.merge(factors) do |_prime, count1, count2|
      count1 + count2
    end
  end
end

class Monkey
  @items : Array(PrimeFactorization)
  @operation : Operation
  @test : Test

  getter inspections = 0

  def initialize(@items, @operation, @test)
  end

  def self.parse(io) : self
    line = io.gets || raise "Unexpected end of input"
    m = line.match(/Starting items:\s*((\d+,?\s*)+)/)
    raise "Malformed starting items" unless m

    items = m[1].split(/,\s+/).map { |str| PrimeFactorization.new(str.to_i) }
    line = io.gets || raise "Unexpected end of input"
    operation = Operation.parse(line)
    test = Test.parse(io)
    new(items, operation, test)
  end

  def add(item)
    @items << item
  end

  def update(monkeys)
    @inspections += @items.size
    @items.each do |item|
      value = @operation.apply(item)
      @test.perform(value, monkeys)
    end
    @items.clear
  end

  def to_s(io : IO) : Nil
    io << "  Items: "
    @items.join(io, ", ")
    io.puts
    io.puts @operation
    io.puts @test
  end
end

monkeys = [] of Monkey
STDIN.each_line do |line|
  next if line.empty?

  m = line.match(/Monkey (\d+):/)
  raise "Malformed input" unless m
  raise "Misaligned monkey index" if m[1].to_i != monkeys.size

  monkeys << Monkey.parse(STDIN)
end

monkeys.each do |monkey|
  puts monkey
end
puts(PrimeFactorization.new(9) ** 3)
exit

10_000.times do
  monkeys.each do |monkey|
    monkey.update(monkeys)
  end
end

monkey_business = monkeys.map(&.inspections).sort!.last(2).product
puts monkey_business
