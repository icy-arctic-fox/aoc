require "bit_array"

LIGHT = '#'
DARK  = '.'
SCALE = 2
DEBUG = false

class Image
  getter width : Int32
  getter height : Int32

  @pixels : BitArray

  def initialize(@width, @height)
    @pixels = BitArray.new(width * height)
  end

  def initialize(@width, @height, & : Int32, Int32 -> Bool)
    @pixels = BitArray.new(width * height)
    i = 0
    height.times do |y|
      width.times do |x|
        @pixels[i] = yield x, y
        i += 1
      end
    end
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
    InfiniteImage.new(self, algo)
  end

  def light_count
    @pixels.count(true)
  end

  def light_count(width, height, x = 0, y = 0)
    count = 0
    height.times do |j|
      width.times do |i|
        count += 1 if self[i + x, j + y]
      end
    end
    count
  end

  def [](x, y)
    if x < 0 || y < 0 || x >= width || y >= height
      false
    else
      @pixels[index(x, y)]
    end
  end

  def []=(x, y, value)
    raise IndexError.new if x < 0 || y < 0 || x >= width || y >= height

    @pixels[index(x, y)] = value
  end

  def to_s(io : IO) : Nil
    @pixels.each_with_index do |pixel, i|
      io.puts if i.divisible_by?(width)
      io << (pixel ? LIGHT : DARK)
    end
  end

  def to_s(io : IO, width, height, x = 0, y = 0) : Nil
    height.times do |j|
      width.times do |i|
        io.print self[i + x, j + y] ? LIGHT : DARK
      end
      io.puts
    end
  end

  private def index(x, y)
    y * width + x
  end
end

class InfiniteImage < Image
  def initialize(@source : Image, @algo : BitArray)
    @pixels = BitArray.new(0)
    @width = -1
    @height = -1
  end

  def sample(x, y)
    value = 0
    ((y - 1).to(y + 1)).each do |j|
      ((x - 1).to(x + 1)).each do |i|
        value <<= 1
        value |= (@source[i - 1, j - 1] ? 1 : 0)
      end
    end
    value
  end

  def enhance(algo = @algo)
    InfiniteImage.new(self, algo)
  end

  def [](x, y)
    value = sample(x, y)
    @algo[value]
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
image = Image.new(width, height) do |x, y|
  buffered[y][x]
end
buffered.clear

SCALE.times do |i|
  if DEBUG
    image.to_s(STDOUT, width + 2 * i, height + 2 * i)
    puts
  end

  image = image.enhance(algo)
end

image.to_s(STDOUT, width + 2 * SCALE, height + 2 * SCALE) if DEBUG
puts image.light_count(width + 2 * SCALE, height + 2 * SCALE)
