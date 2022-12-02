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

def valid?(key, value)
  case key
  when "byr" then value.size == 4 && value.to_i.in?(1920..2002)
  when "iyr" then value.size == 4 && value.to_i.in?(2010..2020)
  when "eyr" then value.size == 4 && value.to_i.in?(2020..2030)
  when "hgt" then valid_height?(value)
  when "hcl" then value.matches?(/^#[0-9a-f]{6}$/)
  when "ecl" then value.in?("amb", "blu", "brn", "gry", "grn", "hzl", "oth")
  when "pid" then value.size == 9
  else            false
  end
end

def valid_height?(value)
  unit = value[-2..-1]
  return false unless amount = value[0...-2].to_i?

  case unit
  when "cm" then amount.in?(150..193)
  when "in" then amount.in?(59..76)
  else           false
  end
end

count = STDIN.each_line.sum do |line|
  if line.empty?
    valid = REQUIRED.each_value.all?
    REQUIRED.transform_values! { false }
    valid ? 1 : 0
  else
    pairs = line.split
    pairs.each do |pair|
      key, value = pair.split(':', 2)
      REQUIRED[key] = valid?(key, value) if REQUIRED.has_key?(key)
    end
    0
  end
end
count += 1 if REQUIRED.each_value.all?
puts count
