<!-- ENCODING: UTF-8 -->

`irb -I . -r ./main.rb`

```rb
print "\e[31m"
p event[:unicode_char]
print "\e[39m"
```

```rb
def to_1d x, y
  # […]
  # && (0...@critters.size).include?(index = x + y * @column_count)

if input[:event_type] == :MOUSE_EVENT && WinCon_Mouse_Event_Flags[:MOUSE_MOVED]
  if new_index = The_field.to_1d(*input[:position])
    # […]
  else selection_index = false end
```

```rb
class String
  def binhex size = self.size
    raise "size #{size.inspect} isn't an integer!" unless size.is_a? Integer
    bin = slice(0, size)
    return bin.unpack("H*").join.upcase.unpack("a2" * bin.size).join(' ')
  end
end
```

```rb
puts "#{input_records.size} / (#{output_length_i} * #{struct.size}) = " +
  "#{output_length_i.zero? ? 0 : input_records.size / (output_length_i * struct.size)}"
# p input_records.unpack1("a#{output_length_i * struct.size}")
trimmed_input_records = input_records.slice(0, output_length_i * struct.size)
puts binhex trimmed_input_records
# pretty_hex = input_records.unpack1("H#{output_length_i * struct.size * 2}")
```

```rb
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
```

Win32 API binding data type legend.
'I' (integer)
'L' (long)
'V' (void)
'P' (pointer)
'K' (callback)
'S' (string)

CHAR                 1 'a'
WCHAR                2 'a2'
WORD                u2 'S'
SHORT               s2 's'
DWORD               u4 'L'
UINT                u4 'L'
INT                 s4 'l'
COORD       s2 * 2 = 4 's2'
SMALL_RECT  s2 * 4 = 8 's4'

```cpp
BOOL WINAPI GetConsoleMode(
  _In_  HANDLE  hConsoleHandle,
  _Out_ LPDWORD lpMode
);

BOOL WINAPI SetConsoleMode(
  _In_ HANDLE hConsoleHandle,
  _In_ DWORD  dwMode
);

BOOL WINAPI ReadConsoleInput(
  _In_  HANDLE        hConsoleInput,
  _Out_ PINPUT_RECORD lpBuffer,
  _In_  DWORD         nLength,
  _Out_ LPDWORD       lpNumberOfEventsRead
);

BOOL WINAPI GetNumberOfConsoleInputEvents(
  _In_  HANDLE  hConsoleInput,
  _Out_ LPDWORD lpcNumberOfEvents
);

typedef struct _INPUT_RECORD {
  WORD  EventType;
  union {
    KEY_EVENT_RECORD          KeyEvent;
    MOUSE_EVENT_RECORD        MouseEvent;
    WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent;
    MENU_EVENT_RECORD         MenuEvent;
    FOCUS_EVENT_RECORD        FocusEvent;
  } Event;
} INPUT_RECORD;
u2 + 16 = 18

typedef struct _COORD {
  SHORT X;
  SHORT Y;
} COORD, *PCOORD;
s2 * 2 = 4

typedef struct _SMALL_RECT {
  SHORT Left;
  SHORT Top;
  SHORT Right;
  SHORT Bottom;
} SMALL_RECT,*PSMALL_RECT;
s2 * 4 = 8

typedef struct _KEY_EVENT_RECORD {
  WINBOOL bKeyDown;
  WORD wRepeatCount;
  WORD wVirtualKeyCode;
  WORD wVirtualScanCode;
  union {
    WCHAR UnicodeChar;
    CHAR AsciiChar;
  } uChar;
  DWORD dwControlKeyState;
} KEY_EVENT_RECORD,*PKEY_EVENT_RECORD;
4 + u2 * 3 + 2 + u4 = 16
```

bKeyDown    | wRepeatCount | wVirtualKeyCode | wVirtualScanCode | UnicodeChar | dwControlKeyState
-------------------------------------------------------------------------------------------------
01 00 00 00 | 01 00        | 57 00           |  11 00           | 77 00       | 00 00 00 00
01 00 00 00 | 01 00        | 49 00           |  17 00           | 69 00       | 00 00

```cpp
typedef struct _MOUSE_EVENT_RECORD {
  COORD dwMousePosition;
  DWORD dwButtonState;
  DWORD dwControlKeyState;
  DWORD dwEventFlags;
} MOUSE_EVENT_RECORD,*PMOUSE_EVENT_RECORD;
4 + u4 * 3 = 16

typedef struct _WINDOW_BUFFER_SIZE_RECORD {
  COORD dwSize;
} WINDOW_BUFFER_SIZE_RECORD,*PWINDOW_BUFFER_SIZE_RECORD;
4

typedef struct _MENU_EVENT_RECORD {
  UINT dwCommandId;
} MENU_EVENT_RECORD,*PMENU_EVENT_RECORD;
u4

typedef struct _FOCUS_EVENT_RECORD {
  WINBOOL bSetFocus;
} FOCUS_EVENT_RECORD,*PFOCUS_EVENT_RECORD;
4
```

# pack

Packs the contents of arr into a binary sequence according to
the directives in aTemplateString (see the table below) Directives
"A", "a", and "Z" may be followed by a count, which gives
the width of the resulting field. The remaining directives also
may take a count, indicating the number of array elements to
convert. If the count is an asterisk ("\*"), all remaining array
elements will be converted. Any of the directives "sSiIlL"
may be followed by an underscore ("\_") or exclamation mark
("!") to use the underlying platform's native size for the
specified type; otherwise, they use a platform-independent size.
Spaces are ignored in the template string.

Integer       | Array   |
Directive     | Element | Meaning
----------------------------------------------------------------------------
C             | Integer | 8-bit unsigned (unsigned char)
S             | Integer | 16-bit unsigned, native endian (uint16_t)
L             | Integer | 32-bit unsigned, native endian (uint32_t)
Q             | Integer | 64-bit unsigned, native endian (uint64_t)
J             | Integer | pointer width unsigned, native endian (uintptr_t)
              |         | (J is available since Ruby 2.3.)
              |         |
c             | Integer | 8-bit signed (signed char)
s             | Integer | 16-bit signed, native endian (int16_t)
l             | Integer | 32-bit signed, native endian (int32_t)
q             | Integer | 64-bit signed, native endian (int64_t)
j             | Integer | pointer width signed, native endian (intptr_t)
              |         | (j is available since Ruby 2.3.)
              |         |
S_ S!         | Integer | unsigned short, native endian
I I_ I!       | Integer | unsigned int, native endian
L_ L!         | Integer | unsigned long, native endian
Q_ Q!         | Integer | unsigned long long, native endian (ArgumentError
              |         | if the platform has no long long type.)
              |         | (Q_ and Q! is available since Ruby 2.1.)
J!            | Integer | uintptr_t, native endian (same with J)
              |         | (J! is available since Ruby 2.3.)
              |         |
s_ s!         | Integer | signed short, native endian
i i_ i!       | Integer | signed int, native endian
l_ l!         | Integer | signed long, native endian
q_ q!         | Integer | signed long long, native endian (ArgumentError
              |         | if the platform has no long long type.)
              |         | (q_ and q! is available since Ruby 2.1.)
j!            | Integer | intptr_t, native endian (same with j)
              |         | (j! is available since Ruby 2.3.)
              |         |
S> s> S!> s!> | Integer | same as the directives without ">" except
L> l> L!> l!> |         | big endian
I!> i!>       |         | (available since Ruby 1.9.3)
Q> q> Q!> q!> |         | "S>" is the same as "n"
J> j> J!> j!> |         | "L>" is the same as "N"
              |         |
S< s< S!< s!< | Integer | same as the directives without "<" except
L< l< L!< l!< |         | little endian
I!< i!<       |         | (available since Ruby 1.9.3)
Q< q< Q!< q!< |         | "S<" is the same as "v"
J< j< J!< j!< |         | "L<" is the same as "V"
              |         |
n             | Integer | 16-bit unsigned, network (big-endian) byte order
N             | Integer | 32-bit unsigned, network (big-endian) byte order
v             | Integer | 16-bit unsigned, VAX (little-endian) byte order
V             | Integer | 32-bit unsigned, VAX (little-endian) byte order
              |         |
U             | Integer | UTF-8 character
w             | Integer | BER-compressed integer

Float        | Array   |
Directive    | Element | Meaning
---------------------------------------------------------------------------
D d          | Float   | double-precision, native format
F f          | Float   | single-precision, native format
E            | Float   | double-precision, little-endian byte order
e            | Float   | single-precision, little-endian byte order
G            | Float   | double-precision, network (big-endian) byte order
g            | Float   | single-precision, network (big-endian) byte order

String       | Array   |
Directive    | Element | Meaning
---------------------------------------------------------------------------
A            | String  | arbitrary binary string (space padded, count is width)
a            | String  | arbitrary binary string (null padded, count is width)
Z            | String  | same as "a", except that null is added with *
B            | String  | bit string (MSB first)
b            | String  | bit string (LSB first)
H            | String  | hex string (high nibble first)
h            | String  | hex string (low nibble first)
u            | String  | UU-encoded string
M            | String  | quoted printable, MIME encoding (see also RFC2045)
             |         | (text mode but input must use LF and output LF)
m            | String  | base64 encoded string (see RFC 2045)
             |         | (if count is 0, no line feed are added, see RFC 4648)
             |         | (count specifies input bytes between each LF,
             |         | rounded down to nearest multiple of 3)
P            | String  | pointer to a structure (fixed-length string)
p            | String  | pointer to a null-terminated string

Misc.        | Array   |
Directive    | Element | Meaning
---------------------------------------------------------------------------
@            | ---     | moves to absolute position
X            | ---     | back up a byte
x            | ---     | null byte


# unpack, unpack1

Decodes str (which may contain binary data) according to the
format string, returning an array of each value extracted. The
format string consists of a sequence of single-character directives,
summarized in the table at the end of this entry. Each directive
may be followed by a number, indicating the number of times
to repeat with this directive. An asterisk ("\*") will use up
all remaining elements. The directives sSiIlL may each be followed
by an underscore ("\_") or exclamation mark ("!") to use the
underlying platform's native size for the specified type; otherwise,
it uses a platform-independent consistent size. Spaces are ignored
in the format string.

Integer       |         |
Directive     | Returns | Meaning
------------------------------------------------------------------
C             | Integer | 8-bit unsigned (unsigned char)
S             | Integer | 16-bit unsigned, native endian (uint16_t)
L             | Integer | 32-bit unsigned, native endian (uint32_t)
Q             | Integer | 64-bit unsigned, native endian (uint64_t)
J             | Integer | pointer width unsigned, native endian (uintptr_t)
              |         |
c             | Integer | 8-bit signed (signed char)
s             | Integer | 16-bit signed, native endian (int16_t)
l             | Integer | 32-bit signed, native endian (int32_t)
q             | Integer | 64-bit signed, native endian (int64_t)
j             | Integer | pointer width signed, native endian (intptr_t)
              |         |
S_ S!         | Integer | unsigned short, native endian
I I_ I!       | Integer | unsigned int, native endian
L_ L!         | Integer | unsigned long, native endian
Q_ Q!         | Integer | unsigned long long, native endian (ArgumentError
              |         | if the platform has no long long type.)
J!            | Integer | uintptr_t, native endian (same with J)
              |         |
s_ s!         | Integer | signed short, native endian
i i_ i!       | Integer | signed int, native endian
l_ l!         | Integer | signed long, native endian
q_ q!         | Integer | signed long long, native endian (ArgumentError
              |         | if the platform has no long long type.)
j!            | Integer | intptr_t, native endian (same with j)
              |         |
S> s> S!> s!> | Integer | same as the directives without ">" except
L> l> L!> l!> |         | big endian
I!> i!>       |         |
Q> q> Q!> q!> |         | "S>" is the same as "n"
J> j> J!> j!> |         | "L>" is the same as "N"
              |         |
S< s< S!< s!< | Integer | same as the directives without "<" except
L< l< L!< l!< |         | little endian
I!< i!<       |         |
Q< q< Q!< q!< |         | "S<" is the same as "v"
J< j< J!< j!< |         | "L<" is the same as "V"
              |         |
n             | Integer | 16-bit unsigned, network (big-endian) byte order
N             | Integer | 32-bit unsigned, network (big-endian) byte order
v             | Integer | 16-bit unsigned, VAX (little-endian) byte order
V             | Integer | 32-bit unsigned, VAX (little-endian) byte order
              |         |
U             | Integer | UTF-8 character
w             | Integer | BER-compressed integer (see Array#pack)

Float        |         |
Directive    | Returns | Meaning
-----------------------------------------------------------------
D d          | Float   | double-precision, native format
F f          | Float   | single-precision, native format
E            | Float   | double-precision, little-endian byte order
e            | Float   | single-precision, little-endian byte order
G            | Float   | double-precision, network (big-endian) byte order
g            | Float   | single-precision, network (big-endian) byte order

String       |         |
Directive    | Returns | Meaning
-----------------------------------------------------------------
A            | String  | arbitrary binary string (remove trailing nulls and ASCII spaces)
a            | String  | arbitrary binary string
Z            | String  | null-terminated string
B            | String  | bit string (MSB first)
b            | String  | bit string (LSB first)
H            | String  | hex string (high nibble first)
h            | String  | hex string (low nibble first)
u            | String  | UU-encoded string
M            | String  | quoted-printable, MIME encoding (see RFC2045)
m            | String  | base64 encoded string (RFC 2045) (default)
             |         | base64 encoded string (RFC 4648) if followed by 0
P            | String  | pointer to a structure (fixed-length string)
p            | String  | pointer to a null-terminated string

Misc.        |         |
Directive    | Returns | Meaning
-----------------------------------------------------------------
@            | ---     | skip to the offset given by the length argument
X            | ---     | skip backward one byte
x            | ---     | skip forward one byte
