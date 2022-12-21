#!/usr/bin/env crystal

class CircularLinkedList(T)
  include Indexable(T)

  class Node(T)
    getter value : T
    property head : self?
    property tail : self?

    def initialize(@value : T)
    end

    def insert(node : self) : Nil
      node.head = self
      node.tail = @tail
      @tail = node
    end

    def swap_head : Nil
      # [HH] [H] [S] [T]
      # head.head.tail = self
      # head.tail = tail
      # head.head = self
      # tail.head = head
      # head = head.head
      # tail = head
      return unless head = @head

      head.tail = @tail
      if before = head.head
        before.tail = self
        @head = before
      else
        @head = nil
      end
      head.head = self
      if tail = @tail
        tail.head = head
      end
      @tail = head
    end

    def swap_tail : Nil
      # [H] [S] [T] [TT]
      # tail.tail.head = self
      # tail.tail = self
      # tail.head = head
      # head.tail = tail
      # head = tail
      # tail = tail.tail
      return unless tail = @tail

      tail.head = @head
      if after = tail.tail
        after.head = self
        @tail = after
      else
        @tail = nil
      end
      tail.tail = self
      if head = @head
        head.tail = tail
      end
      @head = tail
    end

    def to_s(io : IO) : Nil
      io << value
    end
  end

  class NodeIterator(T)
    include Iterator(Node(T))

    def initialize(@node : Node(T)?)
    end

    def next
      return stop unless node = @node

      @node = node.tail
      node
    end
  end

  @nodes = [] of Node(T)
  @head : Node(T)

  def initialize(elements : Enumerable(T))
    tail = nil.as(Node(T)?)
    elements.each do |element|
      node = Node.new(element)
      @nodes << node
      tail.insert(node) if tail
      tail = node
    end

    raise "Empty enumerable" if tail.nil?

    @head = @nodes.first
    @head.head = tail
    tail.not_nil!.tail = @head
  end

  def each_node
    @nodes.each { |node| yield node }
  end

  def node_iterator
    NodeIterator.new(@head)
  end

  def unsafe_fetch(index : Int)
    @nodes.unsafe_fetch(index % size).value
  end

  def size
    @nodes.size
  end

  def to_s(io : IO) : Nil
    io << (@head.head.try &.value) << " <- "
    @nodes.join(io, " <-> ")
    io << " -> " << (@head.head.try &.tail.try &.value)
  end
end

values = STDIN.each_line.map &.to_i
list = CircularLinkedList.new(values)
iter = list.node_iterator

list.each_node do |node|
  value = node.value
  case value
  when .positive?
    value.times { node.swap_tail }
  when .negative?
    value.abs.times { node.swap_head }
  end
end

zero = iter.find! { |node| node.value == 0 }
iter = CircularLinkedList::NodeIterator.new(zero)
nodes = iter.first(list.size).map(&.value).to_a

sum = 0
sum += nodes[1000 % nodes.size]
sum += nodes[2000 % nodes.size]
sum += nodes[3000 % nodes.size]
puts sum
