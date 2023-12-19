#!/usr/bin/env crystal

enum Property
  X
  M
  A
  S
end

enum Operator
  LessThan
  GreaterThan

  def self.parse(string : String) : self
    case string
    when "<" then LessThan
    when ">" then GreaterThan
    else          raise "Unrecognized operator '#{string}'"
    end
  end
end

record(Part, x : Int32, m : Int32, a : Int32, s : Int32) do
  def self.parse(string : String) : self
    x = 0
    m = 0
    a = 0
    s = 0
    string.scan(/([xmas])\s*=\s*(-?\d+)/) do |match|
      value = match[2].to_i
      case match[1]
      when "x" then x = value
      when "m" then m = value
      when "a" then a = value
      when "s" then s = value
      else          raise "Unrecognized category '#{match[1]}'"
      end
    end
    new(x, m, a, s)
  end

  def sum
    @x + @m + @a + @s
  end

  def get(property : Property) : Int32
    case property
    in .x? then x
    in .m? then m
    in .a? then a
    in .s? then s
    end
  end
end

abstract struct Rule
  abstract def eval(part : Part) : Bool
end

struct AcceptRule < Rule
  def self.parse?(string : String) : self?
    new if string == "A"
  end

  def eval(part : Part) : Bool
    ACCEPTED << part
    true
  end
end

struct RejectRule < Rule
  def self.parse?(string : String) : self?
    new if string == "R"
  end

  def eval(part : Part) : Bool
    true
  end
end

struct ForwardRule < Rule
  def self.parse?(string : String) : self?
    new(string) unless string.includes?(':')
  end

  def initialize(@workflow : String)
  end

  def eval(part : Part) : Bool
    QUEUES[@workflow] << part
    true
  end
end

struct ConditionalRule < Rule
  def initialize(@property : Property, @operator : Operator, @value : Int32, @action : String)
  end

  def self.parse?(string : String) : self?
    return unless match = string.match(/^([xmas])([<>])(-?\d+):(.*)$/)

    property = Property.parse(match[1])
    operator = Operator.parse(match[2])
    value = match[3].to_i
    action = match[4]

    new(property, operator, value, action)
  end

  def eval(part : Part) : Bool
    rating = part.get(@property)
    result = case @operator
             in .greater_than? then rating > @value
             in .less_than?    then rating < @value
             end
    return false unless result

    case @action
    when "A" then ACCEPTED << part
    when "R" then return true
    else          QUEUES[@action] << part
    end

    true
  end
end

class Workflow
  getter name

  def initialize(@name : String, @rules : Array(Rule))
  end

  def self.parse(string : String) : self
    match = string.match(/^([^{]+)\{([^}]+)\}$/)
    raise "Unrecognized workflow '#{string}'" unless match

    name = match[1]
    rules_string = match[2]
    rules = rules_string.split(',').map do |rule_string|
      parse_rule(rule_string)
    end

    new(name, rules)
  end

  private def self.parse_rule(string : String) : Rule
    {% begin %}
      {% for type in Rule.all_subclasses %}
        {{type}}.parse?(string) ||
      {% end %}
      raise "Unrecognized rule: #{string}"
    {% end %}
  end

  def eval(part : Part)
    @rules.each do |rule|
      return if rule.eval(part)
    end
    raise "Part unhandled by workflow '#{@name}' - #{part}"
  end
end

ACCEPTED  = [] of Part
WORKFLOWS = {} of String => Workflow
QUEUES    = {} of String => Array(Part)

def parse_workflow(string : String)
  workflow = Workflow.parse(string)
  WORKFLOWS[workflow.name] = workflow
  QUEUES[workflow.name] = [] of Part
end

def parse_part(string : String)
  part = Part.parse(string)
  QUEUES["in"] << part
end

operation = ->parse_workflow(String)
STDIN.each_line do |line|
  operation = ->parse_part(String) if line.blank?
  operation.call(line)
end

def queues_empty?
  QUEUES.all? { |_name, queue| queue.empty? }
end

until queues_empty?
  QUEUES.each do |name, queue|
    workflow = WORKFLOWS[name]
    until queue.empty?
      part = queue.pop
      workflow.eval(part)
    end
  end
end

puts ACCEPTED.sum &.sum
