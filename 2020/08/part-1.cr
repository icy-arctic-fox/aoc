#!/usr/bin/env crystal

class MachineState
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
      instruction.execute(self)
      return if instruction.execute_count >= 1
    end
  end

  def instruction
    @instructions[position]
  end

  def size
    @instructions.size
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

  private def advance(state)
    state.position += 1
  end

  private abstract def impl(state : MachineState) : Bool
end

class NopInstruction < Instruction
  def impl(state : MachineState) : Bool
    true
  end
end

class AccumulateInstruction < Instruction
  def impl(state : MachineState) : Bool
    state.accumulator += argument
    true
  end
end

class JumpInstruction < Instruction
  def impl(state : MachineState) : Bool
    state.position += argument
    false
  end
end

state = MachineState.load(STDIN)
state.run
puts state.accumulator
