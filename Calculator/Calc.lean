/-!
# The calculator

A Float calculator with `+`, `-` and parentheses.  The screen shows the
expression as it is typed, and `=` replaces it with the result.

Each input line is the id of a pressed button, or empty.  Each reply is a line
`<page> <width> <height>` followed by `width * height` RGB pixels.
-/

namespace Calculator

/-! ## Screen -/

def W := 320
def H := 240

/-- A 5×7 dot-matrix font: seven rows per character, each row five bits. -/
def glyph : Char → List Nat
  | '0' => [14, 17, 19, 21, 25, 17, 14] | '1' => [4, 12, 4, 4, 4, 4, 14]
  | '2' => [14, 17, 1, 2, 4, 8, 31]     | '3' => [31, 2, 4, 2, 1, 17, 14]
  | '4' => [2, 6, 10, 18, 31, 2, 2]     | '5' => [31, 16, 30, 1, 1, 17, 14]
  | '6' => [6, 8, 16, 30, 17, 17, 14]   | '7' => [31, 1, 2, 4, 8, 8, 8]
  | '8' => [14, 17, 17, 14, 17, 17, 14] | '9' => [14, 17, 17, 15, 1, 2, 12]
  | '+' => [0, 4, 4, 31, 4, 4, 0]       | '-' => [0, 0, 0, 31, 0, 0, 0]
  | '(' => [2, 4, 8, 8, 8, 4, 2]        | ')' => [8, 4, 2, 2, 2, 4, 8]
  | '.' => [0, 0, 0, 0, 0, 12, 12]      | 'E' => [31, 16, 16, 30, 16, 16, 31]
  | _ => []

/-- White text on black, right-aligned, as `W * H` RGB pixels.  Each font dot is 4×4 pixels. -/
def render (text : String) : ByteArray := Id.run do
  let mut pixels := ByteArray.mk (Array.replicate (W * H * 3) 0)
  let mut left := W - 16
  for c in text.toList.reverse.take 12 do
    left := left - 24
    let mut top := 106
    for bits in glyph c do
      for col in [0:5] do
        if (bits >>> (4 - col)) % 2 == 1 then
          for row in [top : top + 4] do
            let start := row * W + left + col * 4
            for i in [start * 3 : (start + 4) * 3] do
              pixels := pixels.set! i 255
      top := top + 4
  return pixels

/-! ## Arithmetic -/

inductive Token where
  | num (x : Float)
  | op (c : Char)

def isNumChar (c : Char) : Bool := c.isDigit || c == '.'

/-- `12` → 12, `0.5` → 0.5, anything malformed → NaN. -/
def number (s : String) : Float :=
  match s.splitOn "." with
  | [whole] => (whole.toNat?.getD 0).toFloat
  | [whole, frac] => Float.ofScientific ((whole ++ frac).toNat?.getD 0) true frac.length
  | _ => 0 / 0

/-- Split `11+1` into the number 11, the operator `+`, the number 1. -/
def tokenize (text : String) : List Token :=
  (text.toList.splitBy fun a b => isNumChar a && isNumChar b).map fun chunk =>
    if chunk.all isNumChar then .num (number (String.ofList chunk)) else .op (chunk.headD ' ')

/-- Evaluate left to right.  `total` is the sum so far inside the current
parentheses, `sign` is the sign waiting for the next value, and `outer` holds the
saved `(total, sign)` of every parenthesis still open.  `afterValue` says whether
the previous token was a number or `)`.  Anything out of place gives `none`:
a value must follow an operator or `(`, and every `)` must close an open `(`. -/
def evalTokens : List Token → Float → Float → List (Float × Float) → Bool → Option Float
  | [], total, _, [], true => some total
  | .num x :: rest, total, sign, outer, false => evalTokens rest (total + sign * x) 1 outer true
  | .op '+' :: rest, total, _, outer, true => evalTokens rest total 1 outer false
  | .op '-' :: rest, total, _, outer, true => evalTokens rest total (-1) outer false
  | .op '-' :: rest, total, sign, outer, false => evalTokens rest total (-sign) outer false
  | .op '(' :: rest, total, sign, outer, false => evalTokens rest 0 1 ((total, sign) :: outer) false
  | .op ')' :: rest, total, _, (outerTotal, outerSign) :: outer, true =>
    evalTokens rest (outerTotal + outerSign * total) 1 outer true
  | _, _, _, _, _ => none

def evaluate (text : String) : Option Float :=
  evalTokens (tokenize text) 0 1 [] false

/-- `12.000000` → `12`, `0.500000` → `0.5`. -/
def format (x : Float) : String :=
  String.ofList ((toString x).toList.reverse.dropWhile (· == '0') |>.dropWhile (· == '.') |>.reverse)

/-! ## State -/

/-- The state is the text on the screen, such as `11+1`.  `E` means error. -/
structure Calc where
  text : String := ""

def Calc.press (s : Calc) (key : String) : Calc :=
  let text := if s.text == "E" then "" else s.text
  match key with
  | "" => s
  | "clear" => {}
  | "=" =>
    match evaluate text with
    | some x => { text := if x.isFinite then format x else "E" }
    | none => { text := "E" }
  | key => { text := text ++ key }

/-- One tick: apply a button press (or none) and reply with the header and pixels. -/
def Calc.step (s : Calc) (key : String) : Calc × ByteArray :=
  let s := s.press key
  (s, s!"main {W} {H}\n".toUTF8 ++ render (if s.text.isEmpty then "0" else s.text))

end Calculator
