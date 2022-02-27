# ENCODING: UTF-8

def require_gem gemname, requirename = nil
  requirename = gemname if requirename.nil?
  require 'rubygems'
  begin
    gem gemname
  rescue Gem::LoadError
    Gem.install gemname
    gem gemname
  end
  require requirename
end

require_gem 'rainbow'

class Periodic
  def initialize period
    @period = period
    @timestamp = self.class.time_float
  end
  
  def self.time_float
    time = Time.now
    return time.to_i + time.nsec / 1e9
  end
  
  def remainder
    return @period - (self.class.time_float - @timestamp)
  end
  
  def wait
    sleep(remainder) if remainder.positive?
    @timestamp = self.class.time_float
    return true
  end
end

class Paragraph
  attr_accessor :lines, :order, :column_count, :tick_lambda
  
  def initialize column_count = 80, tick_lambda = nil
    @column_count = column_count
    @tick_lambda = tick_lambda
    @tick = 0
    @lines = Hash.new
    @order = Array.new
  end
  
  def [] index
    if index.is_a? Symbol
      return @lines[index]
    elsif index.is_a? Integer then return @lines[@order[index]] end
    raise TypeError.new("Order given isn't a Symbol nor Integer!")
  end
  
  def []= index, value
    if index.is_a? Symbol
      if @lines.include? index
        @lines[index][:string] = value
        @lines[index][:tick] = @tick_lambda.call if @tick_lambda
        return true
      else return add(index, value) end
    elsif index.is_a? Integer
      @lines[@order[index]][:string] = value
      @lines[@order[index]][:tick] = @tick_lambda.call if @tick_lambda
      return true
    end
    raise TypeError.new("Order given isn't a Symbol nor Integer!")
  end
  
  def add key, value
    raise 'Duplicate key' if @lines.include? key
    @lines[key] = Hash.new
    @lines[key][:string] = value
    @lines[key][:tick] = @tick_lambda.call if @tick_lambda
    @order << key
    return @order.last
  end
  alias :push :add
  
  def pop key = nil
    if key
      @order.delete key
      return @lines.delete key
    else return @lines.delete(@order.delete_at(-1)) end
  end
  
  def insert key, value, order
    raise 'Duplicate key' if @lines.include? key
    @lines[key][:string] = value
    @lines[key][:tick] = @tick_lambda.call if @tick_lambda
    if order.is_a? Symbol
      @order.insert((index = @order.index key), value)
      return index
    elsif order.is_a? Integer
      @order.insert order, value
      return @order[order.next]
    end
    raise TypeError.new("Order given isn't a Symbol nor Integer!")
  end
  
  def string
    return @order.map do |key|
      tick_stamp = '(%9i) ' % @lines[key][:tick]
      label_width = @order.max{|a, b| a.size <=> b.size}.size
      header = tick_stamp + (('%' + label_width.to_s + 's') % key.to_s) + ': '
      string = header + @lines[key][:string].to_s
      indent = false
      string = string.split("\n").map do |substring|
        substring = (indent ? (' ' * header.size) : '') + substring
        indent = true
        next substring + ' ' * (@column_count - (substring.size % @column_count))
      end.join("\n")
      next string
    end.join("\n")
  end
  
  def print
    STDOUT.print string
    return true
  end
end

class Array
  def mean
    return inject(0.0) {|sum, number| sum + number} / size
  end
  
  def wrap_at index
    return at(index % size)
  end
end

class String
  private
  
  def _bin_to_spaced_upper_hex size, mutative
    raise "size #{size.inspect} isn't an integer!" unless size.is_a? Integer
    size = self.size if size.zero?
    bin = mutative ? slice!(0, size) : slice(0, size)
    return bin.unpack("H*").join.upcase.unpack("a2" * bin.size).join(' ')
  end
  
  def _bin_to_spaced_bits size, mutative
    raise "size #{size.inspect} isn't an integer!" unless size.is_a? Integer
    size = self.size if size.zero?
    bin = mutative ? slice!(0, size / 8) : slice(0, size / 8)
    return bin.unpack("B*").join.reverse.unpack("a8" * bin.size).join(' ').reverse
  end
  
  public
  
  def bin_to_spaced_upper_hex size = 0
    return _bin_to_spaced_upper_hex(size, false)
  end
  alias :binhex :bin_to_spaced_upper_hex
  
  def bin_to_spaced_upper_hex! size = 0
    return _bin_to_spaced_upper_hex(size, true)
  end
  alias :binhex! :bin_to_spaced_upper_hex!
  
  def bin_to_spaced_bits size = 0
    return _bin_to_spaced_bits(size, false)
  end
  alias :binbits :bin_to_spaced_bits
  
  def bin_to_spaced_bits! size = 0
    return _bin_to_spaced_bits(size, true)
  end
  alias :binbits! :bin_to_spaced_bits!
  
  def buffer_slice! size, directive
    return slice!(0, size).unpack1(directive)
  end
  alias :bslice! :buffer_slice!
  
  def utf_16le_to_8 # To do: accomodate UTF-16LE in the binding wrapper.
    self.force_encoding('UTF-16LE').encode('UTF-8')
  end
  alias :utf_down :utf_16le_to_8
end

class Integer
  def int_to_spaced_bits directive
    str = [self].pack(directive).unpack('B*').join
    return str.reverse.unpack("a8" * (str.size / 8)).join(' ').reverse
  end
  alias :intbits :int_to_spaced_bits
end

class Hash
  def flags_by_bitfield bitfield
    raise "bitfield #{bitfield.inspect} isn't an integer!" unless bitfield.is_a? Integer
    flags = Array.new
    each do |key, value|
      break if bitfield.zero?
      if bitfield & value == value
        bitfield ^ value
        flags << key(value)
      end
    end
    return flags
  end
  alias :flagbits :flags_by_bitfield
end

class FalseClass
  def to_i
    return 0
  end
end

class TrueClass
  def to_i
    return 1
  end
end
