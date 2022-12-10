#!/usr/bin/env crystal

abstract struct Instruction
  abstract def execute(device, &)

  abstract def execute(device)
end

struct NoopInstruction < Instruction
  def execute(device)
    yield
  end

  def execute(device)
    Iterator.new(device)
  end

  class Iterator
    include ::Iterator(Int64)

    @executed = false

    def initialize(@device : Device)
    end

    def next
      return stop if @executed

      @executed = true
      @device.x
    end
  end
end

struct AddXInstruction < Instruction
  def initialize(@value : Int64)
  end

  def self.parse(line)
    _, value = line.split(2)
    new(value.to_i64)
  end

  def execute(device)
    2.times { yield }
    device.x += @value
  end

  def execute(device)
    Iterator.new(device, @value)
  end

  class Iterator
    include ::Iterator(Int64)

    @cycle = 0

    def initialize(@device : Device, @value : Int64)
    end

    def next
      return stop if @cycle > 1

      @cycle += 1
      @device.x += @value if @cycle == 2
      @device.x
    end
  end
end

class Device
  property x : Int64 = 1
  getter cycle : Int64 = 1

  def run(instructions)
    instructions.each do |instruction|
      run_one(instruction)
    end
  end

  def run(instructions)
    iters = instructions.each.map { |instruction| instruction.execute(self) }
    Iterator.chain(iters)
  end

  def run_one(instruction)
    instruction.execute(self) do
      yield x
      @cycle += 1
    end
  end

  def run_one(instruction)
    instruction.execute(self)
  end
end

def parse_instruction(line)
  case line
  when "noop"  then NoopInstruction.new
  when /^addx/ then AddXInstruction.parse(line)
  else              raise "Unknown instruction: #{line}"
  end
end

instructions = STDIN.each_line.map { |line| parse_instruction(line) }
device = Device.new
iter = device.run(instructions)
samples = iter.with_index(2).skip(18).step(40).first(6)
puts samples.sum(&.product)
