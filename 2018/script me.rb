class Node

  attr_reader :ancestry
  attr_accessor :children

  def initialize(arr = Array.new, is_root = false)
    @children = Array.new

    # Determines whether or not the output string should include its own
    # surrounding parentheses.
    @is_root = is_root

    # Indicates how many decendant generations this node has.
    @ancestry = 0

    # Tracks how many levels deep the current position is when parsing.
    current_level = 0

    arr.each_with_index do |c,i|
      if c == '('
        current_level += 1

        # Save the ancestry as the deepest generation that this node will
        # access when being parsed.
        @ancestry += 1 if current_level > @ancestry

        # This node shouldn't be claiming descendants other than its
        # immediate children as its own.
        self.conceive_child(arr[ i+1 ... arr.length ]) unless current_level > 1

      elsif c == ')'
        current_level -= 1
      end

      # Cancel parsing if this node begins to look at its ancestors.
      break if current_level < 0
    end
  end

  def conceive_child(arr)
    @children << Node.new(arr)
  end

  def to_s
    str = @children.map(&:to_s).join
    return @is_root ? str : "(#{ str })"
  end

  def +(other)
    result = nil

    if self.ancestry == other.ancestry
      result = self
      result.children += other.children
    elsif self.ancestry > other.ancestry
      result = self
      result.children.last.children += other.children
    elsif self.ancestry < other.ancestry
      result = other
      result.children.first.children =
        self.children + result.children.first.children
    end

    return result
  end

end

require 'socket'

s = TCPSocket.new('2018shell3.picoctf.com', 61344)

while line = s.gets
  puts ">>> " + line.chomp

  # The server will always provide the problem to solve with a trailing " = ???".
  next unless tail_index = (line =~ / = \?\?\?/)

  challenge = line[0...tail_index]

  puts "..."

  result = challenge
    .gsub(/\s+/, '')  # Whitespace is not needed.
    .split('+')       # Only the "+" operator is ever used.
    .map { |term| Node.new(term.split(''), true) }
    .reduce(&:+)

  response = "#{ result.to_s }\n"
  puts "<<< " + response
  s.send(response, 0)
end

s.close
