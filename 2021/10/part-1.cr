POINTS = {
  ')' => 3,
  ']' => 57,
  '}' => 1197,
  '>' => 25137,
}

sum = STDIN.each_line(chomp: true).sum do |line|
  stack = [] of Char
  result = line.each_char do |c|
    top = stack.last?
    if c.in?('(', '[', '{', '<')
      stack.push(c)
    elsif (c == ')' && top == '(') ||
          (c == ']' && top == '[') ||
          (c == '}' && top == '{') ||
          (c == '>' && top == '<')
      stack.pop
    else
      break POINTS[c]
    end
  end
  result || 0
end
puts sum
