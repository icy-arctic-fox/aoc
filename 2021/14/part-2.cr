alias Pair = Tuple(Char, Char)

class ExpansionIterator
  include Iterator(Pair)

  @pushback : Pair?
  @i = 0

  def initialize(@iter : Iterator(Pair), @rules : Hash(Pair, Char))
  end

  def next
    unless @iter.is_a?(ExpansionIterator)
      puts "Step #{@i}"
      @i += 1
    end

    if pair = @pushback
      @pushback = nil
      return pair
    end

    pair = @iter.next
    return stop if pair.is_a?(Iterator::Stop)

    a, b = pair
    if c = @rules[pair]?
      @pushback = {c, b}
      {a, c}
    else
      pair
    end
  end
end

class PolymerIterator
  include Iterator(Char)

  @last : Char?

  def initialize(@iter : Iterator(Pair))
  end

  def next
    pair = @iter.next
    if pair.is_a?(Iterator::Stop)
      if c = @last
        @last = nil
        c
      else
        stop
      end
    else
      a, b = pair
      @last = b
      a
    end
  end
end

module Iterator(T)
  def tally64_by(& : T -> U) : Hash(U, Int64) forall U
    each_with_object(Hash(U, Int64).new) do |item, hash|
      value = yield item
      count = hash[value]?
      hash[value] = count ? count + 1_i64 : 1_i64
    end
  end

  def tally64 : Hash(T, Int64)
    tally64_by { |item| item }
  end
end

template = gets(chomp: true).not_nil!
gets

rules = {} of Pair => Char
STDIN.each_line(chomp: true) do |line|
  pair, insertion = line.split(" -> ", 2)
  a, b = pair
  rules[{a, b}] = insertion.chars.first
end

expansion = template.each_char.cons_pair
40.times do
  expansion = ExpansionIterator.new(expansion, rules)
end
polymer = PolymerIterator.new(expansion)

elements = polymer.tally64
p elements
amounts = elements.map { |k, v| {element: k, amount: v} }.sort_by(&.[:amount])
puts amounts.last[:amount] - amounts.first[:amount]
