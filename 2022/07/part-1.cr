#!/usr/bin/env crystal

abstract class Node
  getter name : String
  property! parent : DirectoryNode

  def initialize(@name : String, @parent : Node? = nil)
  end

  abstract def size : Int64
end

class DirectoryNode < Node
  getter contents : Array(Node)

  def initialize(@name, @contents = [] of Node)
    @contents.each { |node| node.parent = self }
  end

  def descend
    remaining = contents.select(DirectoryNode)
    while current = remaining.pop?
      yield current
      child_directories = current.contents.select(DirectoryNode)
      remaining.concat(child_directories)
    end
  end

  def size : Int64
    contents.sum &.size
  end

  def to_s(io : IO) : Nil
    io << "dir " << name
  end
end

class FileNode < Node
  getter size : Int64

  def initialize(@name, @size)
  end

  def to_s(io : IO) : Nil
    io << size << ' ' << name
  end
end

class Filesystem
  getter root = DirectoryNode.new("/")
  getter cwd : DirectoryNode

  def initialize
    @cwd = root
  end

  def cd(path)
    case path
    when "/"  then @cwd = root
    when ".." then @cwd = @cwd.parent
    else           @cwd = @cwd.contents.find { |node| node.name == path }.as(DirectoryNode)
    end
  end
end

abstract class Command
  abstract def execute(filesystem)
end

class ChangeDirectoryCommand < Command
  def initialize(@path : String)
  end

  def self.parse(line) : self
    m = line.match(/cd\s+(.*)/)
    raise "Invalid `cd` command" unless m

    path = m[1].strip
    new(path)
  end

  def execute(filesystem)
    filesystem.cd(@path)
  end

  def to_s(io : IO) : Nil
    io << "$ cd " << @path
  end
end

class ListDirectoryCommand < Command
  def initialize(@entries : Array(Node))
  end

  def self.parse(lines) : self
    entries = lines.map { |line| parse_node(line) }
    new(entries)
  end

  private def self.parse_node(line)
    m = line.match(/^((\d+)|(dir))\s+(.*)/)
    raise "Invalid `ls` entry" unless m

    name = m[4].strip
    if m[1] == "dir"
      DirectoryNode.new(name)
    else
      size = m[2].to_i64
      FileNode.new(name, size)
    end
  end

  def execute(filesystem)
    dir = filesystem.cwd
    @entries.each do |entry|
      found = dir.contents.find { |node| node.name == entry.name }
      dir.contents.delete(found) if found
      dir.contents << entry
      entry.parent = dir
    end
  end

  def to_s(io : IO) : Nil
    io.puts "$ ls"
    @entries.each do |entry|
      io.puts entry
    end
  end
end

filesystem = Filesystem.new
lines = STDIN.each_line.to_a
until lines.empty?
  line = lines.shift
  m = line.match(/^\$\s+(\S+)/)
  raise "Malformed line - #{line}" unless m

  command = case m[1]
            when "cd"
              ChangeDirectoryCommand.parse(line)
            when "ls"
              entries = [] of String
              loop do
                break unless line = lines.shift?
                if line.starts_with?('$')
                  lines.unshift(line)
                  break
                end
                entries << line
              end
              ListDirectoryCommand.parse(entries)
            else
              raise "Unrecognized command `#{m[1]}`"
            end
  command.execute(filesystem)
end

found = [] of DirectoryNode
filesystem.root.descend do |directory|
  found << directory if directory.size <= 100000
end
puts found.sum &.size
