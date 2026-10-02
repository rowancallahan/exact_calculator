import Calculator

/-! Entry point and the only IO: read a line from stdin, write the reply to stdout. -/

/-- The backend stops after this many ticks, so the loop provably ends.  This is the
largest count Lean keeps as a plain machine integer (about 4.9 billion years at 60 Hz). -/
def tickBudget := 2^63 - 1

def main : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  let mut s : Calculator.Calc := {}
  for _ in [0:tickBudget] do
    let line ← stdin.getLine
    if line.isEmpty then break  -- the frontend closed the pipe
    let (next, reply) := s.step line.trimAscii.toString
    s := next
    stdout.write reply
    stdout.flush
