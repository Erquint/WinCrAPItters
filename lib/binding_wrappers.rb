# ENCODING: UTF-8

require './lib/header.rb'
require_gem 'win32-api', 'win32/api'
include Win32

module WinAPI
  GetLastError = API.new('GetLastError')
  def get_last_error
    error = GetLastError.call
    return {
      int: error,
      hex: [error].pack(?L).binhex,
      message: WinError.key_by_value(error)
    }
  end
  
  GetStdHandle = API.new('GetStdHandle', ?I)
  def get_std_handle handle_ID
    raise('GetStdHandle → INVALID_HANDLE_VALUE!') if
      (std_handle = GetStdHandle.call(handle_ID)) == WinBase_Handle_ID[:INVALID_HANDLE_VALUE]
    return std_handle
  end
  
  GetConsoleMode = API.new('GetConsoleMode', 'IS')
  def get_console_mode handle
    console_mode = 0.chr * 4
    raise('GetConsoleMode → zero!', cause: Exception.new(get_last_error)) if
      GetConsoleMode.call(handle, console_mode).zero?
    return console_mode.unpack1('L')
  end
  
  SetConsoleMode = API.new('SetConsoleMode', 'II')
  def set_console_mode handle, mode
    raise('SetConsoleMode → zero!', cause: Exception.new(get_last_error)) if
      SetConsoleMode.call(handle, mode).zero?
  end
  
  Set_console_cursor_info = API.new('SetConsoleCursorInfo', 'IS')
  def set_console_cursor_info handle, size, visibility
    console_cursor_info = [size, visibility.to_i].pack('LC')
    raise('SetConsoleCursorInfo → zero!', cause: Exception.new(get_last_error)) if
      Set_console_cursor_info.call(Stdout_handle, console_cursor_info).zero?
  end
  
  ReadConsoleInput = API.new('ReadConsoleInput', 'ISIS')
  def read_console_input handle
    input_length = 1
    output_length = 0.chr * 4
    type_struct = 4
    keyboard_struct = [4, 16]
    mouse_struct = keyboard_struct
    struct = 0.chr * keyboard_struct.sum
    buffer = struct * input_length
    raise('ReadConsoleInput → zero!', cause: Exception.new(get_last_error)) if
      ReadConsoleInput.call(handle, buffer, input_length, output_length).zero?
    return {event_type: nil} if output_length.unpack1(?L).zero?
    event_type = buffer.bslice!(type_struct, ?L)
    if event_type == WinCon_EventType[:KEY_EVENT]
      bKeyDown = buffer.bslice!(4, ?L)
      wRepeatCount = buffer.bslice!(2, ?S)
      wVirtualKeyCode_b = buffer.slice!(0, 2)
      wVirtualKeyCode_i = wVirtualKeyCode_b.unpack1(?S)
      wVirtualKeyCode_h = wVirtualKeyCode_b.binhex(2)
      wVirtualKeyCode_s = WinUser_Virtual_Key_Codes.key_by_value wVirtualKeyCode_i
      wVirtualScanCode = buffer.binhex!(2)
      wUnicodeChar = buffer.slice!(0, 2)
      dwControlKeyState_b = buffer.slice!(0, 4)
      dwControlKeyState_i = dwControlKeyState_b.unpack1(?L)
      dwControlKeyState_s = dwControlKeyState_b.binbits(32)
      dwControlKeyState_a = WinCon_Control_Key_State.flagbits dwControlKeyState_i
      return {
        event_type: :KEY_EVENT,
        key_down: !bKeyDown.zero?,
        repeat_count: wRepeatCount,
        virtual_key_code: {
          hex: wVirtualKeyCode_h,
          string: wVirtualKeyCode_b,
          name: wVirtualKeyCode_s
        },
        virtual_scan_code: wVirtualScanCode,
        unicode_char: wUnicodeChar,
        control_key_state: {
          bits: dwControlKeyState_s,
          int: dwControlKeyState_i,
          flags: dwControlKeyState_a
        }
      }
    elsif event_type == WinCon_EventType[:MOUSE_EVENT]
      dwMousePosition = buffer.slice!(0, 4).unpack('s2')
      dwButtonState_b = buffer.slice!(0, 4)
      dwButtonState_i = dwButtonState_b.unpack1(?L)
      dwButtonState_s = dwButtonState_b.binbits(32)
      dwButtonState_a = WinCon_Mouse_Button_State.flagbits dwButtonState_i
      dwControlKeyState_b = buffer.slice!(0, 4)
      dwControlKeyState_i = dwControlKeyState_b.unpack1(?L)
      dwControlKeyState_s = dwControlKeyState_b.binbits(32)
      dwControlKeyState_a = WinCon_Control_Key_State.flagbits dwControlKeyState_i
      dwEventFlags_b = buffer.slice!(0, 4)
      dwEventFlags_i = dwEventFlags_b.unpack1(?L)
      dwEventFlags_s = dwEventFlags_b.binbits(32)
      dwEventFlags_a = WinCon_Mouse_Event_Flags.flagbits dwEventFlags_i
      scroll_direction = dwButtonState_b.slice(3, 4).unpack1(?C).positive?
      return {
        event_type: :MOUSE_EVENT,
        position: dwMousePosition,
        buttons: {
          bits: dwButtonState_s,
          flags: dwButtonState_a
        },
        control_key_state: {
          bits: dwControlKeyState_s,
          int: dwControlKeyState_i,
          flags: dwControlKeyState_a
        },
        event_flags: {
          bits: dwEventFlags_s,
          flags: dwEventFlags_a
        },
        scroll_direction: scroll_direction
      }
    elsif event_type == WinCon_EventType[:WINDOW_BUFFER_SIZE_EVENT]
      return {
        event_type: :WINDOW_BUFFER_SIZE_EVENT
      }
    elsif event_type == WinCon_EventType[:MENU_EVENT]
      return {
        event_type: :MENU_EVENT
      }
    elsif event_type == WinCon_EventType[:FOCUS_EVENT]
      return {
        event_type: :FOCUS_EVENT
      }
    end
  end
end
include WinAPI

__END__
Get_console_screen_buffer_info = API.new('GetConsoleScreenBufferInfo', 'IS')
console_screen_buffer_info = 0.chr * [4, 4, 2, 8, 4].sum
raise('GetConsoleScreenBufferInfo → zero!', cause: Exception.new(get_last_error)) if
  Get_console_screen_buffer_info.call(Stdout_handle, console_screen_buffer_info).zero?
console_screen_buffer_info = console_screen_buffer_info.unpack('a4a4Sa8a4')

Set_console_cursor_position = API.new('SetConsoleCursorPosition', 'IS')
raise('SetConsoleCursorPosition → zero!', cause: Exception.new(get_last_error)) if
  Set_console_cursor_position.call(Stdout_handle, dwCursorPosition).zero?

Get_console_cursor_info = API.new('GetConsoleCursorInfo', 'IS')
console_cursor_info = 0.chr * [4, 1].sum
raise('GetConsoleCursorInfo → zero!', cause: Exception.new(get_last_error)) if
  Get_console_cursor_info.call(Stdout_handle, console_cursor_info).zero?
console_cursor_info = console_cursor_info.unpack('LC')
puts dwSize = console_cursor_info[0]
puts bVisible = console_cursor_info[1]

