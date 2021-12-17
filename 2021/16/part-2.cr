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
  def initialize(@stream : HexToBinaryIterator)
  end

  def limit(bits)
    LimitedStreamReader.new(@stream, bits.to_u32)
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
        value <<= 1
        value |= read_bit
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

class LimitedStreamReader < StreamReader
  def initialize(stream : HexToBinaryIterator, @limit : UInt32, @original : LimitedStreamReader? = nil)
    super(stream)
  end

  def limit(bits)
    LimitedStreamReader.new(@stream, bits.to_u32, self)
  end

  def read_flag : Bool
    raise IO::EOFError.new("Limit reached") if @limit == 0

    dec
    super
  end

  protected def dec
    @limit -= 1
    @original.try &.dec
  end
end

abstract class Packet
  getter version : UInt8

  abstract def type_id : UInt8

  abstract def value : Int64

  def initialize(@version)
  end

  def sum_nested_versions
    @version.to_i
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

abstract class OperatorPacket < Packet
  getter packets : Array(Packet)

  def initialize(version, @packets)
    super(version)
  end

  def self.read(version, reader) : self
    length_type_id = reader.read_flag
    packets = if length_type_id
                read_packets_count(reader)
              else
                read_packets_length(reader)
              end

    new(version, packets)
  end

  private def self.read_packets_count(reader) : Array(Packet)
    count = reader.read_u16(11)
    iterator = PacketIterator.new(reader)
    iterator.first(count).to_a
  end

  private def self.read_packets_length(reader) : Array(Packet)
    length = reader.read_u16(15)
    iterator = PacketIterator.new(reader.limit(length))
    packets = [] of Packet
    begin
      iterator.each { |packet| packets << packet }
    rescue IO::EOFError
    end
    packets
  end

  def sum_nested_versions
    @version.to_i + @packets.sum(&.sum_nested_versions)
  end
end

class SumPacket < OperatorPacket
  ID = 0_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets.sum &.value
  end
end

class ProductPacket < OperatorPacket
  ID = 1_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets.product &.value
  end
end

class MinimumPacket < OperatorPacket
  ID = 2_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets.min_of &.value
  end
end

class MaximumPacket < OperatorPacket
  ID = 3_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets.max_of &.value
  end
end

class GreaterPacket < OperatorPacket
  ID = 5_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets[0].value > packets[1].value ? 1_i64 : 0_i64
  end
end

class LesserPacket < OperatorPacket
  ID = 6_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets[0].value < packets[1].value ? 1_i64 : 0_i64
  end
end

class EqualPacket < OperatorPacket
  ID = 7_u8

  def type_id : UInt8
    ID
  end

  def value : Int64
    packets[0].value == packets[1].value ? 1_i64 : 0_i64
  end
end

class PacketIterator
  include Iterator(Packet)

  def initialize(@reader : StreamReader)
  end

  def next
    version = @reader.read_u8(3)
    type_id = @reader.read_u8(3)
    decode(type_id, version)
  rescue e : IO::EOFError
    stop
  end

  private def decode(id, version)
    case id
    when ValuePacket::ID   then ValuePacket.read(version, @reader)
    when SumPacket::ID     then SumPacket.read(version, @reader)
    when ProductPacket::ID then ProductPacket.read(version, @reader)
    when MinimumPacket::ID then MinimumPacket.read(version, @reader)
    when MaximumPacket::ID then MaximumPacket.read(version, @reader)
    when GreaterPacket::ID then GreaterPacket.read(version, @reader)
    when LesserPacket::ID  then LesserPacket.read(version, @reader)
    when EqualPacket::ID   then EqualPacket.read(version, @reader)
    else                        raise "Unknown packet type ID #{id}"
    end
  end
end

hex2bin = HexToBinaryIterator.new(STDIN.each_char)
reader = StreamReader.new(hex2bin)
packets = PacketIterator.new(reader)
puts packets.first.value
