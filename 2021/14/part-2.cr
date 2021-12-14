alias Pair = Tuple(Char, Char)

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

elements = template.each_char.tally64
pairs = template.each_char.cons_pair.tally64

40.times do
  new_pairs = {} of Pair => Int64
  pairs.each do |(a, b), count|
    if c = rules[{a, b}]?
      elements[c] = elements.fetch(c, 0_i64) + count
      p1 = {a, c}
      p2 = {c, b}
      new_pairs[p1] = new_pairs.fetch(p1, 0_i64) + count
      new_pairs[p2] = new_pairs.fetch(p2, 0_i64) + count
    else
      pair = {a, b}
      new_pairs[pair] = new_pairs.fetch(pair, 0_i64) + count
    end
  end
  pairs = new_pairs
end

amounts = elements.map { |k, v| {element: k, amount: v} }.sort_by(&.[:amount])
puts amounts.last[:amount] - amounts.first[:amount]
