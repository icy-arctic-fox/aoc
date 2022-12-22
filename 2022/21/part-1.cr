#!/usr/bin/env crystal

abstract struct Monkey
  getter name

  def initialize(@name : String)
  end

  abstract def result
end

alias Monkeys = Hash(String, Monkey)

struct ValueMonkey < Monkey
  getter result

  def initialize(@name : String, @result : Int64)
  end

  def self.parse(name, result)
    new(name, result.to_i64)
  end
end

abstract struct ComputationMonkey < Monkey
  def initialize(@name : String, @left : String, @right : String, @monkeys : Monkeys)
  end

  def result
    result = operation(left_result, right_result)
    @monkeys[name] = ValueMonkey.new(name, result)
    result
  end

  private def left_result
    @monkeys[@left].result
  end

  private def right_result
    @monkeys[@right].result
  end

  private abstract def operation(left_result, right_result)

  def self.parse(name, job, monkeys)
    m = job.match(/^(\S+)\s+([-+\/*])\s+(\S+)$/)
    raise "Malformed job - #{job}" unless m

    left, operation, right = m.captures.map &.not_nil!
    type = case operation
           when "+" then AdditionMonkey
           when "-" then SubtractionMonkey
           when "*" then MultiplicationMonkey
           when "/" then DivisionMonkey
           else          raise "Unknown operation #{operation}"
           end
    type.new(name, left, right, monkeys)
  end
end

struct AdditionMonkey < ComputationMonkey
  def operation(left_result, right_result)
    left_result + right_result
  end
end

struct SubtractionMonkey < ComputationMonkey
  def operation(left_result, right_result)
    left_result - right_result
  end
end

struct MultiplicationMonkey < ComputationMonkey
  def operation(left_result, right_result)
    left_result * right_result
  end
end

struct DivisionMonkey < ComputationMonkey
  def operation(left_result, right_result)
    left_result // right_result
  end
end

def parse_monkey(line, monkeys)
  m = line.match(/^([^:]+):\s*(.*)$/)
  raise "Malformed line - #{line}" unless m

  name = m[1]
  job = m[2]
  if job =~ /^\d+$/
    ValueMonkey.parse(name, job)
  else
    ComputationMonkey.parse(name, job, monkeys)
  end
end

monkeys = Monkeys.new
STDIN.each_line do |line|
  monkey = parse_monkey(line, monkeys)
  monkeys[monkey.name] = monkey
end
root = monkeys["root"]
puts root.result
