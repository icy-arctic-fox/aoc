#!/usr/bin/env crystal

DEBUG = ARGV.shift? == "-d"

class Graph
  getter released = 0
  property rate = 0
  getter position : Node

  def initialize(@nodes : Array(Node), @time = 30, start = "AA")
    @position = @nodes.find! { |node| node.name == start }
  end

  def self.parse(lines)
    nodes = lines.map { |line| Node.parse(line) }
    new(nodes).tap do |graph|
      lines.each do |line|
        parse_edge(line, graph)
      end
    end
  end

  private def self.parse_edge(line, graph)
    m = line.match(/Valve\s+(\S+).*?valves?\s+(.*)/)
    raise "Malformed edge definitions" unless m

    source = m[1]
    edges = m[2].split(", ")
    edges.each do |destination|
      graph.add_edge(source, destination)
    end
  end

  def time_remaining?
    @time > 0
  end

  def each_node
    @nodes.each { |node| yield node }
  end

  def largest_node
    node = @nodes.max_by &.rate
  end

  def move(node) : Node
    raise "Attempted to move to non-adjacent node" unless position.has_edge?(node)
    raise "Attempted to move after time ran out" unless time_remaining?

    puts "Move to #{node.name}" if DEBUG
    tick
    @position = node
  end

  def navigate(node) : Node
    return node if position == node
    return move(node) if position.has_edge?(node)

    open unless position.open?
    puts "Navigate to #{node.name}" if DEBUG
    navigate(node.largest_edge)
  end

  def navigate_to_largest
    return false if @nodes.all? &.open?

    node = @nodes.max_by &.rate
    navigate(node)
    true
  end

  def open
    raise "Attempted to open valve after time ran out" unless time_remaining?

    puts "Open #{position.name}" if DEBUG
    tick
    position.open(self)
  end

  def tick
    return false unless time_remaining?

    @released += rate
    @time -= 1
    puts "Time left: #{@time}, #{released} released" if DEBUG
    true
  end

  def create_node(*args)
    Node.new(*args).tap do |node|
      @nodes << node
    end
  end

  def add_edge(from src_name : String, to dest_name : String) : Nil
    src_node = @nodes.find! { |node| node.name == src_name }
    dest_node = @nodes.find! { |node| node.name == dest_name }
    src_node.add_edge(dest_node)
  end

  def to_s(io : IO) : Nil
    @nodes.each do |node|
      node.to_s(io)
      io.puts
    end
  end
end

class Node
  getter name : String

  getter rate : Int32

  def initialize(@name, @rate)
    @edges = [] of Node
  end

  def self.parse(string) : self
    m = string.match(/Valve\s+(\S+)\s+has flow rate=(-?\d+)/)
    raise "Malformed node definition" unless m

    new(m[1], m[2].to_i)
  end

  def open?
    rate <= 0
  end

  def add_edge(node) : Nil
    @edges << node
  end

  def each_edge
    @edges.each { |node| yield node }
  end

  def has_edge?(other)
    @edges.includes?(other)
  end

  def largest_edge
    @edges.max_by &.rate
  end

  def open(graph) : Nil
    graph.rate += rate
    @rate = 0
  end

  def to_s(io : IO) : Nil
    io << name << " rate=" << rate
    io << " edges=["
    @edges.join(io, ", ") { |edge, io| io << edge.name }
    io << ']'
  end
end

graph = Graph.parse(STDIN.each_line.to_a)
puts graph if DEBUG

while graph.time_remaining?
  break unless graph.navigate_to_largest

  graph.open
end
puts graph.released
