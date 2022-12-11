#!/usr/bin/env crystal

struct Operation
  def initialize(@operation : Char, @modifier : Int64)
  end

  def self.parse(line)
    m = line.match(/Operation:\s+new = old ([*+]) ((\d+)|old)/)
    raise "Malformed operation" unless m

    if m[2] == "old"
      operation = '^'
      modifier = 2_i64
    else
      operation = m[1][0]
      modifier = m[2].to_i64
    end
    new(operation, modifier)
  end

  def apply(value, lcm)
    value = case @operation
            when '*' then value * @modifier
            when '+' then value + @modifier
            when '^' then value ** @modifier
            else          raise "Unrecognized operation '#{@operation}'"
            end
    value % lcm
  end

  def to_s(io : IO) : Nil
    io << "  Operation: new = old " << @operation << ' ' << @modifier
  end
end

struct Test
  getter divisor

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

class Monkey
  @items : Array(Int64)
  @operation : Operation
  @test : Test

  getter inspections = 0_i64

  def initialize(@items, @operation, @test)
  end

  def self.parse(io) : self
    line = io.gets || raise "Unexpected end of input"
    m = line.match(/Starting items:\s*((\d+,?\s*)+)/)
    raise "Malformed starting items" unless m

    items = m[1].split(/,\s+/).map &.to_i64
    line = io.gets || raise "Unexpected end of input"
    operation = Operation.parse(line)
    test = Test.parse(io)
    new(items, operation, test)
  end

  def test_divisor
    @test.divisor
  end

  def add(item)
    @items << item
  end

  def update(monkeys, lcm)
    @inspections += @items.size
    @items.each do |item|
      value = @operation.apply(item, lcm)
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

# Note that all divisible checks are against prime numbers!
lcm = monkeys.product &.test_divisor

10_000.times do
  monkeys.each do |monkey|
    monkey.update(monkeys, lcm)
  end
end

monkey_business = monkeys.map(&.inspections).sort!.last(2).product
puts monkey_business
