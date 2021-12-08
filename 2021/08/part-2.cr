def solve_unique(digits, solved)
  digits.each do |digit|
    case digit.size
    when 2 then solved[digit.chars.sort.join] = 1
    when 3 then solved[digit.chars.sort.join] = 7
    when 4 then solved[digit.chars.sort.join] = 4
    when 7 then solved[digit.chars.sort.join] = 8
    end
  end
  digits.reject! { |digit| digit.size.in?(1, 7, 4, 8) }
end

def solve(digits, solved)
  one = solved.key_for(1)
  four = solved.key_for(4)
  seven = solved.key_for(7)
  eight = solved.key_for(8)
  a = (seven.chars - one.chars).first
  six_nine_zero = digits.select { |digit| digit.size == 6 }
  six = six_nine_zero.find { |digit| (digit.chars | one.chars).size == 7 }.not_nil!
  solved[six.chars.sort.join] = 6
  digits.delete(six)
  c = (eight.chars - six.chars).first
  nine_zero = six_nine_zero - [six]
  zero = nine_zero.find { |digit| (digit.chars | four.chars).size == 7 }.not_nil!
  solved[zero.chars.sort.join] = 0
  digits.delete(zero)
  d = (eight.chars - zero.chars).first
  nine = (nine_zero - [zero]).first
  solved[nine.chars.sort.join] = 9
  digits.delete(nine)
  e = (eight.chars - nine.chars).first
  f = (one.chars - (one.chars - six.chars)).first
  b = (four.chars - one.chars - [d]).first
  g = (nine.chars - four.chars - [a]).first

  [a, b, c, d, e, f, g]
end

def solve_remaining(segments, solved)
  solved[solve_2(segments)] = 2
  solved[solve_3(segments)] = 3
  solved[solve_5(segments)] = 5
end

def solve_2(segments)
  segments.values_at(0, 2, 3, 4, 6).to_a.sort.join
end

def solve_3(segments)
  segments.values_at(0, 2, 3, 5, 6).to_a.sort.join
end

def solve_5(segments)
  segments.values_at(0, 1, 3, 5, 6).to_a.sort.join
end

samples = [] of Int32

total = STDIN.each_line(chomp: true).sum do |line|
  unique, values = line.split(" | ")
  digits = unique.split
  solved = {} of String => Int32
  solve_unique(digits, solved)
  segments = solve(digits, solved)
  solve_remaining(segments, solved)
  values.split.map { |value| solved[value.chars.sort.join].to_s }.join.to_i
end
puts total
