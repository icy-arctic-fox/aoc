#!/usr/bin/env crystal

REQUIRED = {
  "byr" => false,
  "iyr" => false,
  "eyr" => false,
  "hgt" => false,
  "hcl" => false,
  "ecl" => false,
  "pid" => false,
}

count = STDIN.each_line.sum do |line|
  if line.empty?
    valid = REQUIRED.each_value.all?
    REQUIRED.transform_values! { false }
    valid ? 1 : 0
  else
    pairs = line.split
    pairs.each do |pair|
      key, _ = pair.split(':', 2)
      REQUIRED[key] = true if REQUIRED.has_key?(key)
    end
    0
  end
end
count += 1 if REQUIRED.each_value.all?
puts count
