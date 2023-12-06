#!/usr/bin/env crystal

times = STDIN.gets.not_nil!
times = times.scan(/\d+/).map &.[0].to_i
distances = STDIN.gets.not_nil!
distances = distances.scan(/\d+/).map &.[0].to_i

product = times.zip(distances).product do |time, dist|
  time.times.count do |speed|
    (time - speed) * speed > dist
  end
end
puts product
