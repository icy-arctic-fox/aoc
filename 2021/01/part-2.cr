#!/usr/bin/env crystal

puts STDIN.each_line.map(&.to_i).cons(3).map(&.sum).cons_pair.count { |a, b| b > a }
