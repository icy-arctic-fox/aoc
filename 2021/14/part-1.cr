polymer = gets(chomp: true).not_nil!
gets

rules = {} of Tuple(Char, Char) => Char
STDIN.each_line(chomp: true) do |line|
  pair, insertion = line.split(" -> ", 2)
  a, b = pair
  rules[{a, b}] = insertion.chars.first
end

10.times do
  polymer = String::Builder.build do |builder|
    polymer.chars.each_cons_pair do |a, b|
      pair = {a, b}
      builder << a
      if insertion = rules[pair]?
        builder << insertion
      end
    end
    builder << polymer[-1]
  end
end

elements = polymer.each_char.tally
amounts = elements.map { |k, v| {element: k, amount: v} }.sort_by(&.[:amount])
puts amounts.last[:amount] - amounts.first[:amount]
