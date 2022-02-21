# ENCODING: UTF-8

require './lib/helpers.rb'
require './lib/binding_wrappers.rb'
require 'io/console'
require_gem 'rainbow'

Period = ['-p', '--period'].include?(ARGV[0]) ? ARGV[1].to_i : 0.2
Character = ?@
Column_max = 80
Critter_count = 60 * 12
Predator_count = 5

# TO DO: make footer enumerable.
$footer = "Try #{Rainbow('ruby ./main.rb --period 0').yellow} (or #{Rainbow('-p 0').yellow}) for unlimited speed.\n" +
  "Exit by issuing an interrupt signal using #{Rainbow('[Ctrl]+[C]').yellow}.\n"

class Critter
  # Character = Character
  
  attr_accessor :r, :g, :b, :s, :parent
  
  def initialize s: Rainbow(Character), r: rand(255), g: rand(255), b: rand(255), parent: nil
    @r, @g, @b, @s, @parent = r, g, b, s, parent
  end
  
  # def rand_c
  #   @r, @g, @b = rand(255), rand(255), rand(255)
  #   return self
  # end
  
  def inspect
    # return self.dup.remove_instance_variable(:@parent).inspect
    return self.dup.tap{|critter| critter.parent = '[REDACTED]'}.inspect
  end
  
  def replace
    # neighbor_left = critter.neighbor(-1, 0)
    # neighbor_right = critter.neighbor(+1, 0)
    # neighbor_down = critter.neighbor(0, 1)
    # neighbor_up = critter.neighbor(0, -1)
    # critter.r = [neighbor_left.r, neighbor_right.r, neighbor_down.r, neighbor_up.r].mean
    # critter.g = [neighbor_left.g, neighbor_right.g, neighbor_down.g, neighbor_up.g].mean
    # critter.b = [neighbor_left.b, neighbor_right.b, neighbor_down.b, neighbor_up.b].mean
    neighbor = [
      self.neighbor(-1, -1),
      self.neighbor(-1, 0),
      self.neighbor(-1, 1),
      self.neighbor(0, -1),
      self.neighbor(0, 1),
      self.neighbor(1, -1),
      self.neighbor(1, 0),
      self.neighbor(1, 1)
    ].sample
    self.r, self.g, self.b = neighbor.r, neighbor.g, neighbor.b
    return true
  end
  
  def neighbor x, y
    own_index = @parent.find_index(self)
    offset_index = own_index + x + y * @parent.column_count
    out = @parent.wrap_at(offset_index)
    # if offset_index > @parent.size
      # $footer.concat "#{own_index} + (#{x}) = #{offset_index} (max=#{@parent.size})\n"
      # raise 'Fuck!'
    # end
    return out
  end
  
  def string
    return @s.fg(@r, @g, @b)
  end
  
  def print
    print string
    return true
  end
end

class Field
  # Column_max = Column_max
  
  attr_reader :column_count
  
  def initialize critter_count = Critter_count, predator_count = Predator_count, column_max = Column_max
    @predator_count = predator_count
    @column_count = (Math.sqrt(critter_count) * 1.5).truncate.clamp(0, column_max)
    # @column_count can possibly be off by one.
    @critters = Array.new(critter_count)
    # @critters = @critters.each_with_index.map{|e, i| next Critter.new parent: self, pos: i}
    @critters.map!{|e| next Critter.new parent: self}
  end
  
  def [] *args
    return @critters.[] *args
  end
  
  def map! *args
    return @critters.map! *args
  end
  
  def each *args
    return @critters.each *args
  end
  
  def inject *args, &block
    return @critters.inject *args, &block
  end
  
  def size *args
    return @critters.size *args
  end
  
  def wrap_at *args
    return @critters.wrap_at(*args)
  end
  
  def find_index *args
    return @critters.find_index *args
  end
  
  def reset
    self.initialize
    # To do: preserve some settings by default.
    return true
  end
  
  def string
    buffer = String.new
    column = 0
    @critters.each do |critter|
      if column < @column_count
        # critter.print
        buffer.concat critter.string
        column += 1
      else
        buffer.concat "\n"
        column = 0
        redo
      end
    end
    buffer.concat "\n", $footer
    return buffer
  end
  
  def print
    
    # dwSize = console_screen_buffer_info[0].unpack('s2')
    # dwCursorPosition = console_screen_buffer_info[1].unpack('s2')
    # wAttributes = console_screen_buffer_info[2]
    # srWindow = console_screen_buffer_info[3].unpack('s4')
    # dwMaximumWindowSize = console_screen_buffer_info[4].unpack('s2')
    
    STDOUT.sync = false
    STDOUT.goto 0, 0
    STDOUT.write string
    STDOUT.flush
    STDOUT.sync = true
    
    return true
  end
  
  def predate
    # probability_space = Array.new
    # self.each do |critter|
    #   (critter.r + critter.g).times{probability_space << critter}
    # end
    # @predator_count.times do
    #   critter = probability_space.sample
    #   critter.rand_c
    
    # @predated = (defined?(@predated) && !@predated.nil?) ? @predated + 1 : 0
    # @palevo = (defined?(@palevo) && !@palevo.nil?) ? @palevo + (critter.r + critter.g) : 0
    # $footer = "palevo_ratio: #{@palevo.fdiv @predated}" if defined?(@palevo)
    
    # end
    # # palevo_ratio: 254.745014900298
    
    # Antender's algo.
    lottery_entries = @critters.inject(0){|sum, critter| next (sum + critter.r + critter.g)}
    @predator_count.times do
      winning_ticket = rand(lottery_entries)
      @critters.each do |critter|
        winning_ticket -= critter.r + critter.g
        unless winning_ticket.positive?
          
          # @predated = (defined?(@predated) && !@predated.nil?) ? @predated + 1 : 0
          # @palevo = (defined?(@palevo) && !@palevo.nil?) ? @palevo + (critter.r + critter.g) : 0
          # $footer = "palevo_ratio: #{@palevo.fdiv @predated}" if defined?(@palevo)
          
          # critter.rand_c
          critter.replace
          # To do: move to a Critter method.
          break
        end
      end
    end
    # # palevo_ratio: 254.45631067961165
    return true
  end
end

begin
  Stdout_handle = get_std_handle WinBase_Handle_ID[:STD_OUTPUT_HANDLE]
  # $footer << "Stdout_handle: #{Stdout_handle}"
  Field = Field.new
  Sim_turn = Periodic.new Period
  STDOUT.erase_screen 2
  
  set_console_cursor_info Stdout_handle, 25, false
  
  while Sim_turn.wait
    Field.print
    Field.predate
  end
ensure
  STDOUT.goto 0, 0
  STDOUT.erase_screen 2
  puts $footer
  set_console_cursor_info Stdout_handle, 25, true
end
