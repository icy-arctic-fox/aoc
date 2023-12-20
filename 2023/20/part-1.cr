#!/usr/bin/env crystal

enum PulseSignal
  Low
  High
end

record(Pulse, signal : PulseSignal, source : String, destination : String) do
  def to_s(io : IO) : Nil
    io << source << " -" << signal << "-> " << destination
  end
end

abstract class Module
  abstract def name : String
  abstract def destinations : Array(String)
  abstract def pulse(pulse, network) : Nil
end

class ButtonModule
  def push(network)
    network.send_pulse(:low, "", "broadcaster")
  end
end

class FlipFlopModule < Module
  getter name : String
  getter destinations : Array(String)

  @state = false

  def pulse(pulse, network) : Nil
    return if pulse.signal.high?
    signal = @state ? PulseSignal::Low : PulseSignal::High
    @state = !@state
    @destinations.each do |destination|
      network.send_pulse(signal, name, destination)
    end
  end

  def initialize(@name, @destinations)
  end
end

class ConjunctionModule < Module
  getter name : String
  getter destinations : Array(String)

  private getter! inputs : Hash(String, PulseSignal)

  def pulse(pulse, network) : Nil
    inputs[pulse.source] = pulse.signal
    signal = inputs.all? { |_source, last_signal| last_signal.high? } ? PulseSignal::Low : PulseSignal::High
    @destinations.each do |destination|
      network.send_pulse(signal, name, destination)
    end
  end

  def sources=(names : Array(String))
    @inputs = names.to_h { |name| {name, PulseSignal::Low} }
  end

  def initialize(@name, @destinations)
  end
end

class BroadcastModule < Module
  getter destinations : Array(String)

  def name : String
    "broadcaster"
  end

  def pulse(pulse, network) : Nil
    @destinations.each do |destination|
      network.send_pulse(pulse.signal, name, destination)
    end
  end

  def initialize(@destinations)
  end
end

class OutputModule < Module
  def name : String
    "output"
  end

  def destinations : Array(String)
    [] of String
  end

  def pulse(pulse, network) : Nil
  end
end

class Network
  @modules : Hash(String, Module)
  @button = ButtonModule.new
  @queue = Deque(Pulse).new

  getter high_pulses = 0_i64
  getter low_pulses = 0_i64

  def pulses
    high_pulses * low_pulses
  end

  def initialize(modules : Array(Module))
    @modules = modules.to_h { |m| {m.name, m} }
    set_conjunction_sources
  end

  private def set_conjunction_sources
    @modules.each do |name, m|
      next unless m.is_a?(ConjunctionModule)
      m.sources = find_conjunction_sources(name)
    end
  end

  private def find_conjunction_sources(name) : Array(String)
    @modules.compact_map do |module_name, m|
      module_name if m.destinations.includes?(name)
    end
  end

  def push_button
    @button.push(self)
    process_queue
  end

  private def process_queue : Nil
    while pulse = @queue.shift?
      STDERR.puts pulse
      dest_mod = @modules.fetch(pulse.destination) do |destination|
        OutputModule.new if destination == "output"
      end
      dest_mod.try &.pulse(pulse, self)
    end
  end

  def send_pulse(signal : PulseSignal, from source : String, to destination : String)
    if signal.low?
      @low_pulses += 1
    elsif signal.high?
      @high_pulses += 1
    end
    @queue << Pulse.new(signal, source, destination)
  end

  def self.from_io(io : IO) : self
    modules = io.each_line.map do |line|
      parse_module(line)
    end
    new(modules.to_a)
  end

  private def self.parse_module(line : String) : Module
    id, destinations_string = line.split("->").map &.strip
    destinations = destinations_string.split(',').map &.strip
    name = id[1..]
    case id
    when "broadcaster"      then BroadcastModule.new(destinations)
    when .starts_with?('%') then FlipFlopModule.new(name, destinations)
    when .starts_with?('&') then ConjunctionModule.new(name, destinations)
    else                         raise "Unrecognized module - #{line}"
    end
  end
end

network = Network.from_io(STDIN)
1000.times { network.push_button }
puts network.pulses
