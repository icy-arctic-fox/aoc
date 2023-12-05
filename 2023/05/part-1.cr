#!/usr/bin/env crystal

record RangeMap, source_start : Int64, destination_start : Int64, size : Int64 do
  def source_includes?(value)
    source_start <= value <= (source_start + size)
  end

  def map(value)
    return value unless source_includes?(value)

    value - source_start + destination_start
  end
end

record Mapping, source : String, destination : String, ranges : Array(RangeMap)

class Almanac
  @mappings = [] of Mapping
  @current_mapping = [] of RangeMap

  def start_mapping(source, destination) : Nil
    @current_mapping = [] of RangeMap
    @mappings << Mapping.new(source, destination, @current_mapping)
  end

  def add_range(source_start, destination_start, length) : Nil
    @current_mapping << RangeMap.new(source_start, destination_start, length)
  end

  def map(source_type : String, destination_type : String, source_value)
    return source_value if source_type == destination_type

    mapping = @mappings.find! { |m| m.source == source_type }
    range = mapping.ranges.find { |r| r.source_includes?(source_value) }
    destination_value = range.try &.map(source_value) || source_value
    map(mapping.destination, destination_type, destination_value)
  end
end

almanac = Almanac.new
seeds = [] of Int64

STDIN.each_line do |line|
  next if line.empty?

  if line.starts_with?("seeds:")
    seeds = line.split(':').last.scan(/\d+/).map &.[0].to_i64
  elsif match = line.match(/([^-]+)-to-([^-]+) map:/)
    source = match[1]
    destination = match[2]
    almanac.start_mapping(source, destination)
  elsif match = line.match(/(\d+)\s+(\d+)\s+(\d+)/)
    destination_start = match[1].to_i64
    source_start = match[2].to_i64
    length = match[3].to_i64
    almanac.add_range(source_start, destination_start, length)
  else
    raise "Unmatched line: #{line}"
  end
end

min = seeds.min_of { |seed| almanac.map("seed", "location", seed) }
puts min
