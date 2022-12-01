#!/usr/bin/env crystal

POINTS = {
  '(' => 1,
  '[' => 2,
  '{' => 3,
  '<' => 4,
}

totals = STDIN.each_line(chomp: true).compact_map do |line|
  stack = [] of Char
  invalid = line.each_char do |c|
    top = stack.last?
    if c.in?('(', '[', '{', '<')
      stack.push(c)
    elsif (c == ')' && top == '(') ||
          (c == ']' && top == '[') ||
          (c == '}' && top == '{') ||
          (c == '>' && top == '<')
      stack.pop
    else
      break true
    end
  end

  next if invalid

  stack.reverse.reduce(0_i64) { |sum, c| sum * 5 + POINTS[c] }
end

scores = totals.to_a.sort
puts scores[scores.size // 2]
