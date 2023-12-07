#!/usr/bin/env crystal

enum Card : UInt8
  Joker
  Num2
  Num3
  Num4
  Num5
  Num6
  Num7
  Num8
  Num9
  Ten
  # Jack
  Queen
  King
  Ace

  def self.from_char(char : Char) : self
    case char
    when 'J' then Joker
    when '2' then Num2
    when '3' then Num3
    when '4' then Num4
    when '5' then Num5
    when '6' then Num6
    when '7' then Num7
    when '8' then Num8
    when '9' then Num9
    when 'T' then Ten
    when 'Q' then Queen
    when 'K' then King
    when 'A' then Ace
    else          raise "Unrecognized card character '#{char}'"
    end
  end

  def to_char : Char
    case self
    in Joker then 'J'
    in Num2  then '2'
    in Num3  then '3'
    in Num4  then '4'
    in Num5  then '5'
    in Num6  then '6'
    in Num7  then '7'
    in Num8  then '8'
    in Num9  then '9'
    in Ten   then 'T'
    in Queen then 'Q'
    in King  then 'K'
    in Ace   then 'A'
    end
  end
end

enum Type
  HighCard
  OnePair
  TwoPair
  ThreeOfAKind
  FullHouse
  FourOfAKind
  FiveOfAKind
end

class Hand
  include Comparable(Hand)

  getter cards : StaticArray(Card, 5)

  getter type : Type

  def initialize(@cards, @type)
  end

  def self.from_s(string : String) : self
    raise "Hand must contain 5 cards" if string.size != 5

    cards = StaticArray(Card, 5).new do |i|
      char = string.char_at(i)
      Card.from_char(char)
    end

    type = identify_type(cards)
    new(cards, type)
  end

  private def self.identify_type(cards) : Type
    counts = cards.tally
    jokers = counts.fetch(Card::Joker, 0)
    pairs = counts.count { |card, count| count == 2 && !card.joker? }

    if counts.values.includes?(5)
      Type::FiveOfAKind
    elsif counts.values.includes?(4)
      if jokers.in?(1, 4)
        Type::FiveOfAKind
      else
        Type::FourOfAKind
      end
    elsif counts.values.includes?(3)
      if jokers == 3
        if pairs == 1
          Type::FiveOfAKind
        else
          Type::FourOfAKind
        end
      elsif jokers == 2
        Type::FiveOfAKind
      elsif jokers == 1
        Type::FourOfAKind
      elsif pairs == 1
        Type::FullHouse
      else
        Type::ThreeOfAKind
      end
    elsif jokers == 2
      if pairs == 1
        Type::FourOfAKind
      else
        Type::ThreeOfAKind
      end
    elsif pairs == 2
      if jokers == 1
        Type::FullHouse
      else
        Type::TwoPair
      end
    elsif pairs == 1
      if jokers == 2
        Type::FourOfAKind
      elsif jokers == 1
        Type::ThreeOfAKind
      else
        Type::OnePair
      end
    elsif jokers == 1
      Type::OnePair
    else
      Type::HighCard
    end
  end

  def to_s(io : IO) : Nil
    @cards.each do |card|
      io << card.to_char
    end

    io << ' ' << @type
  end

  def <=>(other : Hand)
    cmp = type <=> other.type
    return cmp if cmp != 0
    cards <=> other.cards
  end
end

pairs = STDIN.each_line.map do |line|
  hand_str, bid_str = line.split(/\s+/)
  bid = bid_str.to_i
  hand = Hand.from_s(hand_str)
  {hand, bid}
end.to_a

pairs.sort_by! &.first
points = pairs.each_with_index(1).sum do |(hand, bid), i|
  bid * i
end
puts points
