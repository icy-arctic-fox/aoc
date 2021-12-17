class HexToBinaryIterator
  include Iterator(Bool)

  @nibble : UInt8 = 0
  @bit = -1

  def initialize(@source : Iterator(Char))
  end

  def next
    if @bit < 0
      return stop unless next_nibble
    end

    bit = @nibble.bit(@bit)
    @bit -= 1
    p bit
    !bit.zero?
  end

  private def next_nibble
    c = @source.next
    return false if c.is_a?(Iterator::Stop)

    @bit = 3
    @nibble = c.to_u8(16)
    true
  end
end

class StreamReader
  def initialize(@stream : Iterator(Bool))
  end

  def limit(bits)
    StreamReader.new(@stream.first(bits))
  end

  def read_u8(count) : UInt8
    value = 0_u8
    count.times do |i|
      value <<= 1
      value |= read_bit
    end
    value
  end

  def read_u16(count) : UInt16
    value = 0_u16
    count.times do |i|
      value <<= 1
      value |= read_bit
    end
    value
  end

  def read_i64 : Int64
    value = 0_i64
    loop do
      more = read_flag
      4.times do
        value |= read_bit
        value <<= 1
      end
      break unless more
    end
    value
  end

  def read_flag : Bool
    flag = @stream.next
    raise IO::EOFError.new("End of stream") if flag.is_a?(Iterator::Stop)

    flag
  end

  def read_bit
    read_flag ? 1_u8 : 0_u8
  end
end

abstract class Packet
  getter version : UInt8

  abstract def type_id : UInt8

  def initialize(@version)
  end
end

class ValuePacket < Packet
  ID = 4_u8

  def type_id : UInt8
    ID
  end

  getter value : Int64

  def initialize(version, @value : Int64)
    super(version)
  end

  def self.read(version, reader) : self
    value = reader.read_i64
    new(version, value)
  end
end

class OperatorPacket < Packet
  getter type_id : UInt8

  getter packets : Array(Packet)

  def initialize(version, @type_id, @packets)
    super(version)
  end

  def self.read(version, type_id, reader) : self
    packets = if length_type_id = reader.read_flag
                read_packets_count(reader)
              else
                read_packets_length(reader)
              end

    new(version, type_id, packets)
  end

  private def self.read_packets_count(reader)
    count = reader.read_u16(11)
    iterator = PacketIterator.new(reader)
    iterator.first(count).to_a
  end

  private def self.read_packets_length(reader)
    length = reader.read_u16(15)
    iterator = PacketIterator.new(reader.limit(length))
    iterator.to_a
  end
end

struct PacketIterator
  include Iterator(Packet)

  def initialize(@reader : StreamReader)
  end

  def next
    version = @reader.read_u8(3)
    type_id = @reader.read_u8(3)
    decode(type_id, version)
  end

  private def decode(id, version)
    case id
    when ValuePacket::ID then ValuePacket.read(version, @reader)
    else                      OperatorPacket.read(version, id, @reader)
    end
  end
end

hex2bin = HexToBinaryIterator.new(STDIN.each_char)
reader = StreamReader.new(hex2bin)
packets = PacketIterator.new(reader)
puts packets.sum(&.version)
