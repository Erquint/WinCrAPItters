# ENCODING: UTF-8

require './lib/helpers.rb'
require './lib/binding_wrappers.rb'
require_gem 'rainbow'

Sep = Rainbow(?→).yellow
S_sep = ' %s ' % Rainbow(?→).yellow
D_sep = Rainbow(?↓).yellow
P_beg = Rainbow(?().yellow
P_end = Rainbow(?)).yellow
Stdin_handle = get_std_handle WinBase_Handle_ID[:STD_INPUT_HANDLE]
Old_console_mode = get_console_mode Stdin_handle
New_console_mode = (
    Old_console_mode |
    WinCon_Input_Mode[:ENABLE_WINDOW_INPUT] |
    WinCon_Input_Mode[:ENABLE_MOUSE_INPUT]
  ) & ~WinCon_Input_Mode[:ENABLE_QUICK_EDIT_MODE]
puts "Console mode:",
  Old_console_mode.intbits(?S) + S_sep +
  WinCon_Input_Mode.flagbits(Old_console_mode).inspect,
  D_sep,
  New_console_mode.intbits(?S) + S_sep +
  WinCon_Input_Mode.flagbits(New_console_mode).inspect + ("\n" * 2)
set_console_mode Stdin_handle, New_console_mode

begin
  while true
    event = read_console_input Stdin_handle
    puts "Event type: #{event[:event_type].inspect}"
    if event[:event_type] == :KEY_EVENT
      key_name = event[:virtual_key_code][:name]
      puts "Key down: #{event[:key_down]}",
        "Repeat count: #{event[:repeat_count]}",
        "Virtual key code: #{event[:virtual_key_code][:hex]}" + S_sep +
          (key_name ? key_name.inspect : (?" + event[:virtual_key_code][:string] + ?")),
        "Virtual scan code: #{event[:virtual_scan_code]}",
        "Unicode char: \"#{event[:unicode_char]}\" " +
          P_beg + event[:unicode_char].inspect + P_end,
        "Control key state: #{event[:control_key_state][:bits]}" + S_sep +
          event[:control_key_state][:flags].inspect + ("\n" * 2)
    elsif event[:event_type] == :MOUSE_EVENT
      puts "Position: #{event[:position]}",
        "Buttons: #{event[:buttons][:bits]}" + S_sep +
        event[:buttons][:flags].inspect,
        "Control key state: #{event[:control_key_state][:bits]}" + S_sep +
          event[:control_key_state][:flags].inspect,
        "Event flags: #{event[:event_flags][:bits]}" + S_sep +
          event[:event_flags][:flags].inspect,
        "Scroll direction: #{event[:scroll_direction].inspect}" + ("\n" * 2)
    end
  end
ensure
  set_console_mode Stdin_handle, Old_console_mode
end
