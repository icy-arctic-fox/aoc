START  = "start"
FINISH = "end"

class Node
  enum Mark
    None
    Temp
    Perm
  end

  getter name : String

  getter?(small : Bool) { name.downcase == name }

  property mark : Mark = Mark::None

  @links = [] of self

  def initialize(@name : String)
  end

  def large?
    !small?
  end

  def link(other : self) : Nil
    @links << other
  end

  def linked?(other : self)
    @links.includes?(other)
  end

  def each_link
    @links.each { |node| yield node }
  end

  def to_s(io : IO) : Nil
    io << @name
  end
end

def reject?(path, c)
  c.small? && c.in?(path)
end

def accept?(path, c)
  return false if c.name != FINISH

  complete = path + [c]
  complete.each_cons_pair do |a, b|
    return false unless a.linked?(b)
  end

  small = complete.select(&.small?)
  small.size == small.uniq.size
end

def output(solutions, path, c)
  solutions << (path + [c])
end

def each_candidate(path, c)
  complete = path + [c]
  c.each_link { |s| yield complete, s }
end

# https://en.wikipedia.org/wiki/Backtracking
def backtrack(solutions, path, c)
  return if reject?(path, c)

  output(solutions, path, c) if accept?(path, c)
  each_candidate(path, c) do |subpath, s|
    backtrack(solutions, subpath, s)
  end
end

nodes = Hash(String, Node).new { |hash, key| hash[key] = Node.new(key) }

STDIN.each_line(chomp: true) do |line|
  name_a, name_b = line.split('-', 2)
  node_a = nodes[name_a]
  node_b = nodes[name_b]
  node_a.link(node_b)
  node_b.link(node_a)
end

start = nodes[START]
solutions = Array(Array(Node)).new(0)
backtrack(solutions, [] of Node, start)
puts solutions.size
