EXPLODE = 4

abstract class Node
  property parent : TupleNode?

  def initialize(@parent : Node? = nil)
  end

  def +(other : Node)
    TupleNode.new(self, other).tap do |node|
      while node.reducible?
        node.reduce
      end
    end
  end

  abstract def reducible?

  def level
    level = 1
    node = self
    while parent = node.parent
      node = parent
      level += 1
    end
    level
  end

  def left?
    if parent = @parent.as?(TupleNode)
      parent.left == self
    end
  end

  def right?
    if parent = @parent.as?(TupleNode)
      parent.right == self
    end
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
    needs_explode? || @left.reducible? || @right.reducible?
  end

  def needs_explode?
    @left.is_a?(ValueNode) && @right.is_a?(ValueNode) && level > EXPLODE
  end

  def reduce
    if needs_explode?
      explode
      true
    elsif @left.reducible?
      @left.reduce
    elsif @right.reducible?
      @right.reduce
    else
      false
    end
  end

  private def explode
    values = flatten
    left = @left.as(ValueNode)
    right = @right.as(ValueNode)
    left_value.try { |node| node.value += left.value }
    right_value.try { |node| node.value += right.value }
    node = ValueNode.new(0)
    if left?
      parent.not_nil!.left = node
    else
      parent.not_nil!.right = node
    end
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

  def root
    node = self
    while parent = node.parent
      node = parent
    end
    node
  end

  def flatten_all
    root.flatten
  end

  private def left_sibling : Node?
    return unless parent = @parent

    if parent.right == self
      parent.left
    else
      parent.try(&.parent.right)
    end
  end

  private def right_sibling : Node?
    return unless parent = @parent

    if parent.left == self
      parent.right
    else
      parent.try(&.parent.left)
    end
  end

  private def left_value : ValueNode?
    return unless parent = @parent

    if parent.right == self && (left = parent.left).as?(ValueNode)
      left.as(ValueNode)
    else
      values = flatten_all
      index = values.index(@left).not_nil! - 1
      values[index].as(ValueNode) if index >= 0
    end
  end

  private def right_value : ValueNode?
    return unless parent = @parent

    if parent.left == self && (right = parent.right).as?(ValueNode)
      right.as(ValueNode)
    else
      values = flatten_all
      index = values.index(@right).not_nil! + 1
      values[index].as(ValueNode) if index < values.size
    end
  end

  def to_s(io : IO) : Nil
    io << '['
    left.to_s(io)
    io << ','
    right.to_s(io)
    io << ']'
  end
end

class ValueNode < Node
  property value : Int32

  def initialize(@value : Int32)
  end

  def reducible?
    @value > 9
  end

  def reduce
    return false unless reducible?

    if left?
      @parent.as(TupleNode).left = split
    else
      @parent.as(TupleNode).right = split
    end
    true
  end

  def split
    left_value = value // 2
    right_value = value // 2
    right_value += 1 if left_value + right_value < value
    left = ValueNode.new(left_value)
    right = ValueNode.new(right_value)
    TupleNode.new(left, right)
  end

  def to_s(io : IO) : Nil
    io << value
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
puts node
