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

MIN_RATING   =    1
MAX_RATING   = 4000
RATING_RANGE = MIN_RATING..MAX_RATING

record(Part,
  x : Range(Int32, Int32),
  m : Range(Int32, Int32),
  a : Range(Int32, Int32),
  s : Range(Int32, Int32)) do
  def self.all : self
    new(RATING_RANGE, RATING_RANGE, RATING_RANGE, RATING_RANGE)
  end

  def sum
    @x.size.to_i64 * @m.size * @a.size * @s.size
  end

  def split(property : Property, value : Int32)
    case property
    in .x? then split_x(value)
    in .m? then split_m(value)
    in .a? then split_a(value)
    in .s? then split_s(value)
    end
  end

  def split_x(value : Int32)
    if value > @x.end
      {self, nil}
    elsif value < @x.begin
      {nil, self}
    else
      {
        copy_with(x: (x.begin)...value),
        copy_with(x: value..(x.end)),
      }
    end
  end

  def split_m(value : Int32)
    if value > @m.end
      {self, nil}
    elsif value < @m.begin
      {nil, self}
    else
      {
        copy_with(m: (m.begin)...value),
        copy_with(m: value..(m.end)),
      }
    end
  end

  def split_a(value : Int32)
    if value > @a.end
      {self, nil}
    elsif value < @a.begin
      {nil, self}
    else
      {
        copy_with(a: (a.begin)...value),
        copy_with(a: value..(a.end)),
      }
    end
  end

  def split_s(value : Int32)
    if value > @s.end
      {self, nil}
    elsif value < @s.begin
      {nil, self}
    else
      {
        copy_with(s: (s.begin)...value),
        copy_with(s: value..(s.end)),
      }
    end
  end
end

abstract struct Rule
  abstract def filter(part : Part) : Part?
end

struct AcceptRule < Rule
  def self.parse?(string : String) : self?
    new if string == "A"
  end

  def filter(part : Part) : Part?
    ACCEPTED << part
    nil
  end
end

struct RejectRule < Rule
  def self.parse?(string : String) : self?
    new if string == "R"
  end

  def filter(part : Part) : Part?
    # ...
  end
end

struct ForwardRule < Rule
  def self.parse?(string : String) : self?
    new(string) unless string.includes?(':')
  end

  def initialize(@workflow : String)
  end

  def filter(part : Part) : Part?
    QUEUES[@workflow] << part
    nil
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

  def filter(part : Part) : Part?
    lower_part, upper_part = part.split(@property, @value)

    accepted, passed = case @operator
                       in .greater_than? then {upper_part, lower_part}
                       in .less_than?    then {lower_part, upper_part}
                       end

    case @action
    when "A" then ACCEPTED << accepted if accepted
    when "R" then return
    else          QUEUES[@action] << accepted if accepted
    end

    passed
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

  def filter(part : Part) : Nil
    current = part.as(Part?)
    @rules.each do |rule|
      return unless current = rule.filter(part)
    end
    raise "Part unhandled by workflow '#{@name}' - #{part}"
  end
end

ACCEPTED  = [] of Part
WORKFLOWS = {} of String => Workflow
QUEUES    = {} of String => Array(Part)

STDIN.each_line do |line|
  break if line.blank?

  workflow = Workflow.parse(line)
  WORKFLOWS[workflow.name] = workflow
  QUEUES[workflow.name] = [] of Part
end

def queues_empty?
  QUEUES.all? { |_name, queue| queue.empty? }
end

QUEUES["in"] << Part.all

until queues_empty?
  QUEUES.each do |name, queue|
    workflow = WORKFLOWS[name]
    until queue.empty?
      part = queue.pop
      workflow.filter(part)
    end
  end
end

def reduce_ranges(ranges : Enumerable(Range))
  # TODO
end

puts ACCEPTED
