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

class Array
  def mean
    return self.inject(0.0) {|sum, number| sum + number} / self.size
  end
  
  def wrap_at index
    return self.at(index % self.size)
  end
end

class String
  private
  
  def _bin_to_spaced_upper_hex size, mutative
    raise "size #{size.inspect} isn't an integer!" unless size.is_a? Fixnum
    size = self.size if size.zero?
    bin = mutative ? self.slice!(0, size) : self.slice(0, size)
    return bin.unpack("H*").join.upcase.unpack("a2" * bin.size).join(' ')
  end
  
  def _bin_to_spaced_bits size, mutative
    raise "size #{size.inspect} isn't an integer!" unless size.is_a? Fixnum
    size = self.size if size.zero?
    bin = mutative ? self.slice!(0, size / 8) : self.slice(0, size / 8)
    return bin.unpack("B*").join.reverse.unpack("a8" * bin.size).join(' ').reverse
  end
  
  public
  
  def bin_to_spaced_upper_hex size = 0
    _bin_to_spaced_upper_hex size, false
  end
  alias :binhex :bin_to_spaced_upper_hex
  
  def bin_to_spaced_upper_hex! size = 0
    _bin_to_spaced_upper_hex size, true
  end
  alias :binhex! :bin_to_spaced_upper_hex!
  
  def bin_to_spaced_bits size = 0
    _bin_to_spaced_bits size, false
  end
  alias :binbits :bin_to_spaced_bits
  
  def bin_to_spaced_bits! size = 0
    _bin_to_spaced_bits size, true
  end
  alias :binbits! :bin_to_spaced_bits!
  
  def buffer_slice! size, directive
    self.slice!(0, size).unpack1(directive)
  end
  alias :bslice! :buffer_slice!
end

class Fixnum
  def int_to_spaced_bits directive
    str = [self].pack(directive).unpack('B*').join
    return str.reverse.unpack("a8" * (str.size / 8)).join(' ').reverse
  end
  alias :intbits :int_to_spaced_bits
end

class Hash
  def key_by_value query
    self.each do |key, value|
      return key if value == query
    end
    return nil
  end
  
  def flags_by_bitfield bitfield
    raise "bitfield #{bitfield.inspect} isn't an integer!" unless bitfield.is_a? Fixnum
    flags = Array.new
    self.each do |key, value|
      break if bitfield.zero?
      if bitfield & value == value
        bitfield ^ value
        flags << self.key_by_value(value)
      end
    end
    return flags
  end
  alias :flagbits :flags_by_bitfield
end
