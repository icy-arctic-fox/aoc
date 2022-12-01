#!/usr/bin/env crystal

puts STDIN.each_line.map(&.to_i).cons_pair.count { |a, b| b > a }
