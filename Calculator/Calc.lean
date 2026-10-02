import Calculator.Effect

/-!
# The calculator

A Float adding machine.  Each input line is the id of a pressed button, or
empty.  Each reply is a line `<page> <width> <height>` followed by
`width * height` RGB pixels.
-/

namespace Calculator

def W := 320
def H := 240

/-- Seven segments `a`–`g` and a decimal point `h`, as `(x, y, w, h)` in a 24×48 cell. -/
def segments : List (Nat × Nat × Nat × Nat) :=
  [(0, 0, 24, 4), (20, 0, 4, 24), (20, 24, 4, 24), (0, 44, 24, 4),
   (0, 24, 4, 24), (0, 0, 4, 24), (0, 22, 24, 4), (10, 44, 4, 4)]

def glyph : Char → String
  | '0' => "abcdef"  | '1' => "bc"     | '2' => "abged"  | '3' => "abgcd"
  | '4' => "fgbc"    | '5' => "afgcd"  | '6' => "afgedc" | '7' => "abc"
  | '8' => "abcdefg" | '9' => "abcdfg" | '-' => "g"      | '.' => "h"
  | _ => ""

/-- White text on black, right-aligned, as `W * H` RGB pixels. -/
def render (text : String) : ByteArray := Id.run do
  let mut pixels := ByteArray.mk (Array.replicate (W * H * 3) 0)
  let mut left := W - 16
  for c in text.toList.reverse.take 8 do
    left := left - 36
    for s in (glyph c).toList do
      let (x, y, w, h) := segments[s.toNat - 'a'.toNat]!
      for row in [96 + y : 96 + y + h] do
        for i in [(row * W + left + x) * 3 : (row * W + left + x + w) * 3] do
          pixels := pixels.set! i 255
  return pixels

/-- `12.000000` → `12`, `0.500000` → `0.5`. -/
def format (x : Float) : String :=
  String.ofList ((toString x).toList.reverse.dropWhile (· == '0') |>.dropWhile (· == '.') |>.reverse)

structure Calc where
  total : Float := 0
  entry : Float := 0

def Calc.press (s : Calc) : String → Calc
  | "clear" => {}
  | "+" | "=" => { total := s.total + s.entry }
  | key => match key.toNat? with
    | some digit => { s with entry := s.entry * 10 + digit.toFloat }
    | none => s

def calculator : Machine Calc where
  init := {}
  step s key :=
    let s := s.press key
    let shown := if s.entry != 0 then s.entry else s.total
    (s, s!"main {W} {H}\n".toUTF8 ++ render (format shown))

end Calculator
