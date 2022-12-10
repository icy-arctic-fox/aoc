#!/usr/bin/env crystal

require "bit_array"

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
  def initialize(@value : Int32)
  end

  def self.parse(line)
    _, value = line.split(2)
    new(value.to_i)
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

    def initialize(@device : Device, @value : Int32)
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
  property x : Int32 = 1
  getter cycle : Int32 = 1

  def run(instructions)
    instructions.each do |instruction|
      run_one(instruction) do |x|
        yield x
      end
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

class Display
  WIDTH  = 40
  HEIGHT =  6

  @position = 0
  @sprite = (0..2)

  @grid = BitArray.new(WIDTH * HEIGHT)

  def update(x) : Nil
    @sprite = (x - 1)..(x + 1)
    @grid[@position] = current_pixel
    @position += 1
    @position %= @grid.size
  end

  def current_pixel
    x_position.in?(@sprite)
  end

  def x_position
    @position % WIDTH
  end

  def to_s(io : IO) : Nil
    @grid.each_with_index do |pixel, index|
      io.puts if index.divisible_by?(WIDTH)
      io << (pixel ? '#' : '.')
    end
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
display = Display.new
device.run(instructions) do |x|
  display.update(x)
end
puts display
