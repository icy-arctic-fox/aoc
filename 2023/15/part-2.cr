#!/usr/bin/env crystal

record Lens, label : String, focal_length : UInt8

def hash(string : String) : UInt8
  value = 0_u8
  string.each_char do |char|
    value &+= char.ord
    value &*= 17
  end
  value
end

def store(boxes, lens)
  hash = hash(lens.label)
  box = boxes[hash]
  box.each_with_index do |l, i|
    if l.label == lens.label
      box[i] = lens
      return
    end
  end
  box << lens
end

def remove(boxes, label)
  hash = hash(label)
  box = boxes[hash]
  box.each_with_index do |lens, i|
    if lens.label == label
      box.delete_at(i)
      break
    end
  end
end

boxes = Array(Array(Lens)).new(256) { [] of Lens }

sequence = STDIN.gets || ""
steps = sequence.split(",")
steps.each do |step|
  if m = step.match(/^([^=]+)=(\d)$/)
    lens = Lens.new(m[1], m[2].to_u8)
    store(boxes, lens)
  elsif m = step.match(/^([^-]+)-$/)
    remove(boxes, m[1])
  end
end

sum = boxes.each_with_index(1).sum(0_i64) do |(box, i)|
  box.each_with_index(1).sum do |(lens, j)|
    i * j * lens.focal_length
  end
end
puts sum
