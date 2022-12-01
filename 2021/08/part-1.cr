#!/usr/bin/env crystal

puts STDIN.each_line(chomp: true).sum(&.split(" | ").last.split.count { |e| e.size.in?(2, 3, 4, 7) })
