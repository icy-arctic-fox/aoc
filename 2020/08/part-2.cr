#!/usr/bin/env crystal

class MachineState
  def_clone

  property accumulator : Int32 = 0,
    position : Int32 = 0

  def initialize(@instructions : Array(Instruction))
  end

  def self.load(io : IO) : self
    instructions = io.each_line.map { |line| Instruction.load(line) }
    new(instructions.to_a)
  end

  def run
    while position.in?(0...size)
      return false if instruction.execute_count >= 1

      instruction.execute(self)
    end
    true
  end

  def corrupt(position)
    @instructions[position] =
      case instruction = @instructions[position]
      when NopInstruction  then JumpInstruction.new(instruction.argument)
      when JumpInstruction then NopInstruction.new(instruction.argument)
      else                      return false
      end
    true
  end

  def instruction
    @instructions[position]
  end

  def size
    @instructions.size
  end

  def to_s(io : IO) : Nil
    @instructions.each { |i| io.puts(i) }
    io << "ACC: " << accumulator << " POS: " << position
  end
end

abstract class Instruction
  getter argument : Int32
  getter execute_count : Int32 = 0

  def initialize(@argument : Int32)
  end

  def self.load(line)
    name, argument = line.split(2)
    argument = argument.to_i
    case name
    when "nop" then NopInstruction.new(argument)
    when "acc" then AccumulateInstruction.new(argument)
    when "jmp" then JumpInstruction.new(argument)
    else            raise "Unknown instruction \"#{name}\""
    end
  end

  def execute(state : MachineState) : Nil
    @execute_count += 1
    advance(state) if impl(state)
  end

  def to_s(io : IO) : Nil
    io << name << ' ' << argument
  end

  private def advance(state)
    state.position += 1
  end

  private abstract def name : String

  private abstract def impl(state : MachineState) : Bool
end

class NopInstruction < Instruction
  def_clone

  def name : String
    "nop"
  end

  def impl(state : MachineState) : Bool
    true
  end
end

class AccumulateInstruction < Instruction
  def_clone

  def name : String
    "acc"
  end

  def impl(state : MachineState) : Bool
    state.accumulator += argument
    true
  end
end

class JumpInstruction < Instruction
  def_clone

  def name : String
    "jmp"
  end

  def impl(state : MachineState) : Bool
    state.position += argument
    false
  end
end

original = MachineState.load(STDIN)
state = original.clone
position = 0
until state.run
  loop do
    state = original.clone
    break if state.corrupt(position).tap { position += 1 }
  end
end
puts state.accumulator
