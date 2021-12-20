require "bit_array"

LIGHT   = '#'
DARK    = '.'
SCALE   = 50
DEBUG   = true
PADDING = 1

record Bounds, x : Int32, y : Int32, width : Int32, height : Int32 do
  def left
    x
  end

  def top
    y
  end

  def right
    x + width
  end

  def bottom
    y + height
  end

  def includes?(x, y)
    x >= left && x < right && y >= top && y < bottom
  end

  def size
    width * height
  end

  def index(x, y)
    (y - top) * width + (x - left)
  end

  def expand(amount)
    Bounds.new(x - amount, y - amount, width + amount * 2, height + amount * 2)
  end

  def each
    (top...bottom).each do |y|
      (left...right).each do |x|
        yield x, y
      end
    end
  end

  def each_with_index
    i = 0
    each do |x, y|
      yield x, y, i
      i += 1
    end
  end
end

class Image
  def initialize(@bounds : Bounds, @default : Bool)
    @pixels = BitArray.new(@bounds.size)
  end

  def initialize(@bounds : Bounds, @default : Bool, & : Int32, Int32 -> Bool)
    @pixels = BitArray.new(@bounds.size)
    @bounds.each_with_index do |x, y, i|
      @pixels[i] = yield x, y
    end
  end

  def initialize(width, height, @default : Bool, & : Int32, Int32 -> Bool)
    @bounds = Bounds.new(0, 0, width, height)
    @pixels = BitArray.new(@bounds.size)
    @bounds.each_with_index do |x, y, i|
      @pixels[i] = yield x, y
    end
  end

  def width
    @bounds.width
  end

  def height
    @bounds.height
  end

  def sample(x, y)
    value = 0
    ((y - 1).to(y + 1)).each do |j|
      ((x - 1).to(x + 1)).each do |i|
        value <<= 1
        value |= (self[i, j] ? 1 : 0)
      end
    end
    value
  end

  def enhance(algo)
    bounds = @bounds.expand(PADDING)
    swap = algo.first
    Image.new(bounds, swap ? !@default : @default) do |x, y|
      value = sample(x, y)
      algo[value]
    end
  end

  def light_count(bounds = @bounds)
    count = 0
    bounds.each do |x, y|
      count += 1 if self[x, y]
    end
    count
  end

  def [](x, y)
    if @bounds.includes?(x, y)
      @pixels[index(x, y)]
    else
      @default
    end
  end

  def to_s(io : IO) : Nil
    @pixels.each_with_index do |pixel, i|
      io.puts if i.divisible_by?(width)
      io << (pixel ? LIGHT : DARK)
    end
  end

  private def index(x, y)
    @bounds.index(x, y)
  end
end

algo = BitArray.new(512)
algo_chars = gets.try &.chars
raise "Failed to get algo" unless algo_chars

algo_chars.each_with_index do |c, i|
  algo[i] = c == LIGHT
end
algo_chars.clear

gets
buffered = [] of BitArray
STDIN.each_line(chomp: true) do |line|
  chars = line.chars
  pixels = BitArray.new(chars.size)
  chars.each_with_index { |c, i| pixels[i] = chars[i] == LIGHT }
  buffered << pixels
end

width = buffered.first.size
height = buffered.size
default = algo.first == algo.last
image = Image.new(width, height, default) do |x, y|
  buffered[y][x]
end
buffered.clear

SCALE.times do |i|
  puts "#{i}/#{SCALE}" if DEBUG
  puts image if DEBUG
  image = image.enhance(algo)
end

puts image if DEBUG
puts image.light_count
