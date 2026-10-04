## Lossless JSON wire numbers. Keep std/json raw numeric tokens, never turn
## unbounded canonical integers or opaque decimal numbers into machine floats.
import std/[json, strutils, re, algorithm]


proc requireStrictJson(text: string) =
  # std/json intentionally accepts JavaScript-like numeric spelling. Validate
  # strict JSON syntax first, before it can normalize and erase invalid tokens.
  var position = 0
  while position < text.len:
    let first = ord(text[position])
    var width = 1
    if first <= 0x7F: discard
    elif first in 0xC2..0xDF: width = 2
    elif first in 0xE0..0xEF: width = 3
    elif first in 0xF0..0xF4: width = 4
    else: raise newException(ValueError, "invalid UTF-8 leading byte")
    if position + width > text.len: raise newException(ValueError, "truncated UTF-8")
    for offset in 1..<width:
      if ord(text[position + offset]) notin 0x80..0xBF: raise newException(ValueError, "invalid UTF-8 continuation")
    if width > 1:
      let second = ord(text[position + 1])
      if (first == 0xE0 and second < 0xA0) or (first == 0xED and second > 0x9F) or
         (first == 0xF0 and second < 0x90) or (first == 0xF4 and second > 0x8F):
        raise newException(ValueError, "invalid UTF-8 scalar")
    position += width
  var index = 0
  proc bad() = raise newException(ValueError, "invalid JSON at byte " & $index)
  proc spaces() =
    while index < text.len and text[index] in {' ', '\t', '\r', '\n'}: inc index
  proc take(c: char) =
    if index >= text.len or text[index] != c: bad()
    inc index
  proc hex4(): int =
    if index + 4 > text.len: bad()
    for unused in 0..<4:
      let c = text[index]; inc index
      let digit = if c in {'0'..'9'}: ord(c)-ord('0') elif c in {'a'..'f'}: ord(c)-ord('a')+10 elif c in {'A'..'F'}: ord(c)-ord('A')+10 else: -1
      if digit < 0: bad()
      result = result * 16 + digit
  proc stringToken() =
    take('"')
    while index < text.len:
      let c = text[index]; inc index
      if c == '"': return
      if ord(c) < 32: bad()
      if c == '\\':
        if index >= text.len: bad()
        let escape = text[index]; inc index
        if escape == 'u':
          let code = hex4()
          if code in 0xD800..0xDBFF:
            take('\\'); take('u')
            if hex4() notin 0xDC00..0xDFFF: bad()
          elif code in 0xDC00..0xDFFF: bad()
        elif escape notin {'"', '\\', '/', 'b', 'f', 'n', 'r', 't'}: bad()
    bad()
  proc value(depth: int) =
    if depth > 1000: bad()
    spaces()
    if index >= text.len: bad()
    case text[index]
    of '"': stringToken()
    of '{':
      inc index; spaces()
      if index < text.len and text[index] == '}': inc index; return
      while true:
        spaces(); stringToken(); spaces(); take(':'); value(depth + 1); spaces()
        if index < text.len and text[index] == '}': inc index; return
        take(',')
    of '[':
      inc index; spaces()
      if index < text.len and text[index] == ']': inc index; return
      while true:
        value(depth + 1); spaces()
        if index < text.len and text[index] == ']': inc index; return
        take(',')
    of 't', 'f', 'n':
      let literal = if text[index] == 't': "true" elif text[index] == 'f': "false" else: "null"
      for c in literal: take(c)
    else:
      let start = index
      while index < text.len and text[index] notin {' ', '\t', '\r', '\n', ',', ']', '}'}: inc index
      if index == start or not text[start..<index].match(re"^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$"): bad()
  value(0); spaces()
  if index != text.len: bad()

proc parseWireJson*(text: string): JsonNode =
  requireStrictJson(text)
  parseJson(text, rawIntegers = true, rawFloats = true)
proc stringifyWireJson*(value: JsonNode): string = $value

proc rawNumber(value: JsonNode): bool =
  value.kind == JString and not ($value).startsWith("\"")
proc isJsonString*(value: JsonNode): bool = value.kind == JString and not rawNumber(value)
proc isJsonNumber*(value: JsonNode): bool =
  if value.kind == JInt: return true
  if value.kind == JFloat: return ($value).match(re"^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$")
  rawNumber(value) and value.getStr.match(re"^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$")

proc unsigned(text: string): string =
  result = text.strip(leading = true, trailing = false, chars = {'0'})
  if result.len == 0: result = "0"
proc normal(text: string): string =
  let negative = text.startsWith("-")
  let digits = if text[0] in {'-', '+'}: unsigned(text[1..^1]) else: unsigned(text)
  if negative and digits != "0": "-" & digits else: digits
proc magnitude(a, b: string): int =
  result = cmp(a.len, b.len)
  if result == 0: result = cmp(a, b)
proc compareSigned(a, b: string): int =
  let x = normal(a); let y = normal(b)
  let xn = x.startsWith("-"); let yn = y.startsWith("-")
  if xn != yn: return if xn: -1 else: 1
  result = magnitude(if xn: x[1..^1] else: x, if yn: y[1..^1] else: y)
  if xn: result = -result
proc addUnsigned(a, b: string): string =
  var i = a.high; var j = b.high; var carry = 0
  while i >= 0 or j >= 0 or carry != 0:
    var digit = carry
    if i >= 0: digit += ord(a[i]) - ord('0'); dec i
    if j >= 0: digit += ord(b[j]) - ord('0'); dec j
    result.add(chr(ord('0') + digit mod 10))
    carry = digit div 10
  result.reverse()
proc subtractUnsigned(a, b: string): string =
  var j = b.high; var borrow = 0
  for i in countdown(a.high, 0):
    var digit = ord(a[i]) - ord('0') - borrow
    if j >= 0: digit -= ord(b[j]) - ord('0'); dec j
    borrow = if digit < 0: 1 else: 0
    if digit < 0: digit += 10
    result.add(chr(ord('0') + digit))
  result.reverse()
  result = unsigned(result)
proc addSigned(a, b: string): string =
  let x = normal(a); let y = normal(b)
  let xn = x.startsWith("-"); let yn = y.startsWith("-")
  let xd = if xn: x[1..^1] else: x
  let yd = if yn: y[1..^1] else: y
  if xn == yn: return normal((if xn: "-" else: "") & addUnsigned(xd, yd))
  if magnitude(xd, yd) >= 0:
    normal((if xn: "-" else: "") & subtractUnsigned(xd, yd))
  else: normal((if yn: "-" else: "") & subtractUnsigned(yd, xd))

type ExactNumber = object
  negative: bool
  digits, power: string
proc exact(text: string): ExactNumber =
  let pieces = text.toLowerAscii.split('e')
  var mantissa = pieces[0]
  result.negative = mantissa.startsWith("-")
  if result.negative: mantissa = mantissa[1..^1]
  let point = mantissa.find('.')
  let scale = if point < 0: 0 else: mantissa.len - point - 1
  result.digits = unsigned(mantissa.replace(".", ""))
  result.power = addSigned(if pieces.len == 2: pieces[1] else: "0", $(-scale))
  if result.digits == "0":
    result.negative = false; result.power = "0"; return
  var trailing = 0
  while result.digits.len > 1 and result.digits[^1] == '0':
    result.digits.setLen(result.digits.len - 1); inc trailing
  result.power = addSigned(result.power, $trailing)
proc numberText(value: JsonNode): string =
  if rawNumber(value): value.getStr else: $value
proc isJsonInteger*(value: JsonNode): bool =
  if not isJsonNumber(value): return false
  let parsed = exact(numberText(value))
  parsed.digits == "0" or compareSigned(parsed.power, "0") >= 0
proc compareJsonNumbers*(a, b: JsonNode): int =
  ## Exact order without expanding exponent-sized strings, including unbounded
  ## exponent tokens. Memory depends on input digits, not exponent magnitude.
  if not isJsonNumber(a) or not isJsonNumber(b):
    raise newException(ValueError, "expected JSON numbers")
  let x = exact(numberText(a)); let y = exact(numberText(b))
  if x.negative != y.negative: return if x.negative: -1 else: 1
  if x.digits == "0" or y.digits == "0":
    result = if x.digits == y.digits: 0 elif x.digits == "0": -1 else: 1
  else:
    result = compareSigned(addSigned(x.power, $x.digits.len), addSigned(y.power, $y.digits.len))
    if result == 0:
      let width = max(x.digits.len, y.digits.len)
      result = cmp(x.digits.alignLeft(width, '0'), y.digits.alignLeft(width, '0'))
  if x.negative: result = -result
