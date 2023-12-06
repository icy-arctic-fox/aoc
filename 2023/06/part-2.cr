#!/usr/bin/env crystal

times = STDIN.gets.not_nil!
time = times.scan(/\d+/).map(&.[0]).join.to_i64
distances = STDIN.gets.not_nil!
dist = distances.scan(/\d+/).map(&.[0]).join.to_i64

count = time.times.count do |speed|
  (time - speed) * speed > dist
end
puts count
