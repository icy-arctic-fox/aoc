#!/usr/bin/env crystal

puts STDIN.each_line.map(&.to_i).to_a.each_combination(3, reuse: true).find! { |c| c.sum == 2020 }.product
