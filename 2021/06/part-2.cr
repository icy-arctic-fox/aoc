#!/usr/bin/env crystal

DAYS    = 256
RESET   =   6
NEW     =   8
BUCKETS = NEW + 1

buckets = StaticArray(Int64, BUCKETS).new(0_i64)

school = STDIN.gets(chomp: true).try(&.split(',').map(&.to_i))
raise "Missing school of fish" unless school

school.each do |fish|
  buckets[fish] += 1
end

DAYS.times do |i|
  new = buckets[0]
  NEW.times { |i| buckets[i] = buckets[i + 1] }
  buckets[NEW] = new
  buckets[RESET] += new
end

puts buckets.sum
