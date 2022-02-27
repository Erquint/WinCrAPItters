# ENCODING: UTF-8

require './lib/helpers.rb'
require './lib/binding_wrappers.rb'
require 'io/console'
STDERR.reopen("./STDERR.TXT", "w")

Period = ['-p', '--period'].include?(ARGV[0]) ? ARGV[1].to_i : 0.2
Character = ?@
Console_size = STDOUT.winsize
# 80×24 is just a well-recognized standard.
Column_max = 80
Critter_count = 60 * 12
Predator_count = 5
Footer = Paragraph.new((Console_size.last), lambda{return 0})

Footer[:hint] = "Try #{Rainbow('ruby ./app/main.rb --period 0').yellow} (or #{Rainbow('-p 0').yellow}) for unlimited speed.\n" +
  "Exit by issuing an interrupt signal with #{Rainbow('[Ctrl]+[C]').yellow} or by pressing #{Rainbow('[ESC]').yellow}.\n" +
  "Reset the field with #{Rainbow('[R]').yellow}."

class Critter
  attr_accessor :r, :g, :b, :s, :backlight, :field
  
  def initialize s: Rainbow(Character), r: rand(255), g: rand(255), b: rand(255), backlight: false, field: nil
    @r, @g, @b, @s, @backlight, @field = r, g, b, s, backlight, field
  end
  
  def inspect
    temp_field = @field
    @field = :REDACTED
    info = super
    @field = temp_field
    return info
  end
  
  def replace
    own_index = @field.index(self)
    parent = neighbors(own_index).sample
    @r, @g, @b = parent.r, parent.g, parent.b
    return true
  end
  
  def neighbor own_index = nil, x_offset, y_offset
    own_index = @field.index(self) unless own_index
    return @field.wrap_at(*@field.translate(own_index, x_offset, y_offset))
  end
  
  def neighbors own_index = nil
    own_index = @field.index(self) unless own_index
    return [
      neighbor(own_index, -1, -1),
      neighbor(own_index, -1, 0),
      neighbor(own_index, -1, 1),
      neighbor(own_index, 0, -1),
      # neighbor(own_index, 0, 0), # self
      neighbor(own_index, 0, 1),
      neighbor(own_index, 1, -1),
      neighbor(own_index, 1, 0),
      neighbor(own_index, 1, 1)
    ]
  end
  
  def string
    string = @s
    string = @backlight ? string.bg(:silver) : string.bg(:default)
    return string.fg(@r, @g, @b)
  end
  
  def print
    STDOUT.print string
    return true
  end
end

class Field
  attr_reader :column_count, :row_count
  
  def initialize critter_count = Critter_count, predator_count = Predator_count, column_max = Column_max
    @predator_count = predator_count
    @column_count = (Math.sqrt(critter_count) * 1.5).truncate.clamp(0, column_max)
    @row_count = (critter_count - 1).div(@column_count) + 1
    @critters = Array.new(critter_count)
    @critters.map!{next Critter.new field: self}
  end
  
  def inspect
    temp_critters = @critters
    @critters = :REDACTED
    info = super
    @critters = temp_critters
    return info
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
  
  def index *args
    return @critters.index *args
  end
  
  def valid_1d? index, report = false
    result = true
    result = false unless index.is_a?(Integer)
    raise ArgumentError.new("Index #{index.inspect} isn't an Integer!") if
      report && !result
    result = false unless (0..@critters.size).include?(index)
    raise ArgumentError.new("Index #{index.inspect} is out of bounds #{@critters.size - 1}!") if
      report && !result
    return result
  end
  
  def valid_2d? x, y, report = false
    result = true
    result = false unless [x, y].all?(Integer)
    raise ArgumentError.new("Coordinates #{x.inspect}, #{y.inspect} aren't both Integers!") if
      report && !result
    result = false unless (0...@column_count).include?(x) && (0...@row_count).include?(y)
    raise ArgumentError.new("Coordinates #{x.inspect}, #{y.inspect} are out of bounds #{@column_count - 1}, #{@row_count - 1}!") if
      report && !result
    return result
  end
  
  def at x, y = nil
    raise ArgumentError.new("Index #{x.inspect} isn't an Integer!") unless
      x.is_a?(Integer)
    unless y
      raise ArgumentError.new("Index #{x.inspect} is out of bounds #{@critters.size - 1}!") unless
        (0..@critters.size).include?(x.inspect)
    else
      raise ArgumentError.new("Index #{y.inspect} isn't an Integer!") unless
        y.is_a?(Integer)
      raise ArgumentError.new("Coordinates #{x.inspect}, #{y.inspect} are out of bounds #{@column_count - 1}, #{@row_count - 1}!") unless
        (0...@column_count).include?(x) && (0...@row_count).include?(y)
      return @critters[to_1d(x, y)]
    end
    return @critters[x]
  end
  
  def wrap x, y = nil
    raise ArgumentError.new("Index #{x.inspect} isn't an Integer!") unless
      x.is_a?(Integer)
    unless y
      x = x % @critters.size if x.abs > 0
      x = @critters.size - x if x < 0
      return x
    else
      raise ArgumentError.new("Coordinates #{x.inspect}, #{y.inspect} aren't both Integers!") unless
        y.is_a?(Integer)
      x = x % @column_count if x.abs > 0
      x = @column_count - x if x < 0
      y = y % @row_count if y.abs > 0
      y = @row_count - y if y < 0
      return [x, y]
    end
  end
  
  def wrap_at x, y = nil
    raise ArgumentError.new("Index #{x.inspect} isn't an Integer!") unless
      x.is_a?(Integer)
    unless y
      return @critters[wrap(x)]
    else
      raise ArgumentError.new("Index #{y.inspect} isn't an Integer!") unless
        y.is_a?(Integer)
      return at(*wrap(x, y))
    end
  end
  
  def to_1d x, y
    valid_2d? x, y, true
    return x + y * @column_count
  end
  
  def to_2d index
    valid_1d? index, true
    return [index.modulo(@column_count), index.div(@column_count)]
  end
  
  def translate index, x_offset, y_offset = 0
    raise ArgumentError.new("Offset coordinates #{x_offset.inspect}, #{y_offset.inspect} aren't both Integers!") unless
      [x_offset, y_offset].all?(Integer)
    # return wrap(index + x_offset + y_offset * @column_count)
    index = to_2d(index) if index.is_a?(Integer)
    if index.is_a?(Array)
      raise ArgumentError.new("Index #{index.inspect} isn't a pair!") unless index.size == 2
      raise ArgumentError.new("Coordinates #{index.first.inspect}, #{index.last.inspect} aren't both Integers!") unless
        [index.first, index.last].all?(Integer)
      return wrap(index.first + x_offset, index.last + y_offset)
    else raise ArgumentError.new("Index #{index.inspect} is neither Integer nor Array!") end
  end
  
  def predate
    lottery_entries = @critters.inject(0){|sum, critter| next (sum + critter.r + critter.g)}
    @predator_count.times do
      winning_ticket = rand(lottery_entries)
      @critters.each do |critter|
        winning_ticket -= critter.r + critter.g
        unless winning_ticket.positive?
          critter.replace
          break
        end
      end
    end
    return true
  end
  
  def reset
    initialize
    return true
  end
  
  def string
    buffer = String.new
    column = 0
    @critters.each do |critter|
      if column < @column_count
        buffer.concat critter.string
        column += 1
      else
        buffer.concat "\n"
        column = 0
        redo
      end
    end
    return buffer.concat("\n", Footer.string)
  end
  
  def print
    STDOUT.sync = false
    STDOUT.goto 0, 0
    STDOUT.write string
    STDOUT.flush
    STDOUT.sync = true
    return true
  end
end

Stdout_handle = get_std_handle WinBase_Handle_ID[:STD_OUTPUT_HANDLE]
Stdin_handle = get_std_handle WinBase_Handle_ID[:STD_INPUT_HANDLE]
The_field = Field.new
Sim_turn = Periodic.new Period
Old_console_mode = get_console_mode Stdin_handle
New_console_mode = (
  Old_console_mode |
  WinCon_Input_Mode[:ENABLE_WINDOW_INPUT] |
  WinCon_Input_Mode[:ENABLE_MOUSE_INPUT]
) & ~WinCon_Input_Mode[:ENABLE_QUICK_EDIT_MODE]

begin
  STDOUT.erase_screen 2
  set_console_mode Stdin_handle, New_console_mode
  set_console_cursor_info Stdout_handle, 25, false
  
  selection_index, selected = nil
  # ring = nil
  tick = 0
  Footer.tick_lambda = lambda{return tick}
  while Sim_turn.wait
    The_field.print
    The_field.predate
    unless get_number_of_console_input_events(Stdin_handle).zero?
      input = read_console_input Stdin_handle
      if input[:event_type] == :MOUSE_EVENT && WinCon_Mouse_Event_Flags[:MOUSE_MOVED]
        selection_index = input[:position] if The_field.valid_2d?(*input[:position])
      elsif input[:event_type] == :KEY_EVENT && input[:key_down]
        selection_index = 0 unless selection_index
        if input[:virtual_key_code][:int] == WinUser_Virtual_Key_Codes[:VK_ESCAPE]
          exit
        elsif input[:virtual_key_code][:string].utf_down == ?R
          The_field.reset
        elsif input[:virtual_key_code][:int] == WinUser_Virtual_Key_Codes[:VK_LEFT]
          selection_index = The_field.translate(selection_index, -1)
        elsif input[:virtual_key_code][:int] == WinUser_Virtual_Key_Codes[:VK_RIGHT]
          selection_index = The_field.translate(selection_index, +1)
        elsif input[:virtual_key_code][:int] == WinUser_Virtual_Key_Codes[:VK_UP]
          selection_index = The_field.translate(selection_index, 0, -1)
        elsif input[:virtual_key_code][:int] == WinUser_Virtual_Key_Codes[:VK_DOWN]
          selection_index = The_field.translate(selection_index, 0, +1)
        end
      end
      if selection_index
        if critter = The_field.wrap_at(*selection_index)
          selected.backlight = false if selected
          # ring.each{|critter| critter.backlight = false} if ring
          selected = critter
          # ring = selected.neighbors
          selected.backlight = true
          # ring.each{|critter| critter.backlight = true}
          Footer[:critter] = "r: %3i, g: %3i, b: %3i," % [selected.r, selected.g, selected.b]
        end
      else
        selected.backlight = false if selected
        # ring.each{|critter| critter.backlight = false} if ring
      end
    end
    tick += 1
  end
ensure
  STDOUT.goto 0, 0
  STDOUT.erase_screen 2
  Footer[:exception] = $!.full_message
  Footer.print
  set_console_cursor_info Stdout_handle, 25, true
  set_console_mode Stdin_handle, Old_console_mode
end
