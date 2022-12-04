#!/usr/bin/env crystal

adapters = STDIN.each_line.map(&.to_i).to_a.sort
diff1 = 1
diff3 = 1
adapters.each_cons_pair do |a, b|
  case b - a
  when 1 then diff1 += 1
  when 3 then diff3 += 1
  end
end
puts diff1 * diff3
