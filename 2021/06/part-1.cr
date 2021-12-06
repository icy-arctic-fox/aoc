DAYS  = 80
RESET =  6
NEW   =  8

school = STDIN.gets(chomp: true).try(&.split(',').map(&.to_i))
raise "Missing school of fish" unless school

DAYS.times do
  new = 0
  school.map! do |fish|
    if fish.zero?
      new += 1
      RESET
    else
      fish - 1
    end
  end
  new.times { school << NEW }
end

puts school.size
