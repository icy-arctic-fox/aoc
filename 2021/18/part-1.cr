require "colorize"

EXPLODE = 4
SPLIT   = 9
DEBUG   = false

abstract class Node
  property! parent : TupleNode?

  def initialize(@parent : TupleNode? = nil)
  end

  abstract def reducible?

  abstract def magnitude

  def +(other : Node)
    node = TupleNode.new(self, other)
    puts "after addition: #{node}" if DEBUG
    Reducer.new(node).reduce
  end

  def root
    node = self
    while parent = node.parent
      node = parent
    end
    node
  end

  def left?
    parent.try { |node| node.left == self }
  end

  def right?
    parent.try { |node| node.right == self }
  end

  def flatten_all
    root.flatten
  end

  def level
    level = 1
    node = self
    while parent = node.parent?
      node = parent
      level += 1
    end
    level
  end
end

class TupleNode < Node
  getter left : Node
  getter right : Node

  def left=(node : Node)
    @left.parent = nil
    node.parent = self
    @left = node
  end

  def right=(node : Node)
    @right.parent = nil
    node.parent = self
    @right = node
  end

  def initialize(@left : Node, @right : Node)
    @left.parent = self
    @right.parent = self
  end

  def reducible?
    left.is_a?(ValueNode) && right.is_a?(ValueNode) && level > EXPLODE
  end

  def magnitude
    3 * @left.magnitude + 2 * @right.magnitude
  end

  def explode(left_value : ValueNode?, right_value : ValueNode?)
    left = @left.as?(ValueNode)
    right = @right.as?(ValueNode)
    raise "Unexpected explosion of non-value tuple" unless left && right

    left_value.try { |node| node.value += left.value }
    right_value.try { |node| node.value += right.value }
    ValueNode.new(0)
  end

  def flatten(array = [] of ValueNode)
    case left = @left
    when ValueNode then array << left
    when TupleNode then left.flatten(array)
    end
    case right = @right
    when ValueNode then array << right
    when TupleNode then right.flatten(array)
    end
    array
  end

  def to_s(io : IO) : Nil
    io << (level > EXPLODE ? '['.colorize(:red) : '[')
    left.to_s(io)
    io << ','
    right.to_s(io)
    io << (level > EXPLODE ? ']'.colorize(:red) : ']')
  end
end

class ValueNode < Node
  property value : Int32

  def initialize(@value : Int32)
  end

  def reducible?
    @value > SPLIT
  end

  def magnitude
    @value
  end

  def split
    left_value, mod = value.divmod(2)
    right_value = left_value
    right_value += 1 unless mod.zero?
    left = ValueNode.new(left_value)
    right = ValueNode.new(right_value)
    TupleNode.new(left, right)
  end

  def to_s(io : IO) : Nil
    io << value
  end
end

class NodeIterator
  include Iterator(Node)

  @stack = [] of Node

  def initialize(@root : TupleNode)
    @stack << @root
  end

  def next
    return stop if @stack.empty?

    node = @stack.pop
    if node.is_a?(TupleNode)
      @stack << node.right
      @stack << node.left
    end
    node
  end
end

class Reducer
  def initialize(@root : TupleNode)
  end

  def reduce
    loop do
      explodable = explodable_nodes
      splittable = splittable_nodes
      break if explodable.empty? && splittable.empty?

      explodable_nodes.each { |node| explode(node) }
      splittable_nodes.first?.try { |node| split(node) }
    end
    @root
  end

  private def explode(node : TupleNode)
    left = node.left.as?(ValueNode)
    right = node.right.as?(ValueNode)
    raise "Unexpected explosion of non-value tuple" unless left && right

    value_nodes = @root.flatten
    left_value = left_of(left, value_nodes)
    right_value = right_of(right, value_nodes)
    replacement = node.explode(left_value, right_value)
    replace(node, replacement)
    puts "after explode:  #{@root}" if DEBUG
  end

  private def split(node : ValueNode)
    replacement = node.split
    replace(node, replacement)
    puts "after split:    #{@root}" if DEBUG
  end

  private def replace(old, new)
    if old.left?
      old.parent.left = new
    else
      old.parent.right = new
    end
  end

  private def left_of(node : ValueNode, value_nodes)
    index = value_nodes.index(node).not_nil! - 1
    value_nodes[index] if index >= 0
  end

  private def right_of(node : ValueNode, value_nodes)
    index = value_nodes.index(node).not_nil! + 1
    value_nodes[index] if index < value_nodes.size
  end

  private def explodable_nodes : Iterator(TupleNode)
    each_node.select(TupleNode).select(&.reducible?)
  end

  private def splittable_nodes : Iterator(ValueNode)
    each_node.select(ValueNode).select(&.reducible?)
  end

  private def each_node : Iterator(Node)
    NodeIterator.new(@root)
  end
end

class NodeReader
  @root : Node?

  def initialize(@string : String)
    @stack = [] of Tuple(Node, Bool)
    @right = false
  end

  def read
    @string.each_char do |c|
      case c
      when '['      then start_tuple
      when .number? then start_value(c.to_i)
      when ','      then second_value
      when ']'      then end_tuple
      end
    end
    raise "Misaligned stack" unless @stack.empty?

    @root.not_nil!
  end

  private def start_tuple
    tuple = TupleNode.new(ValueNode.new(0), ValueNode.new(0))
    if @stack.empty?
      @root = tuple
    else
      attach(tuple)
    end
    @stack << {tuple, false}
  end

  private def start_value(value)
    attach(ValueNode.new(value))
  end

  private def second_value
    entry = @stack.last
    @stack[-1] = {entry[0], true}
  end

  private def end_tuple
    @stack.pop
  end

  private def attach(node)
    entry = @stack.last
    tuple = entry[0].as(TupleNode)
    if entry[1]
      tuple.right = node
    else
      tuple.left = node
    end
  end
end

first = gets(chomp: true).not_nil!
node = NodeReader.new(first).read
node = STDIN.each_line(chomp: true).sum(node) do |line|
  reader = NodeReader.new(line)
  reader.read
end
puts node.magnitude
