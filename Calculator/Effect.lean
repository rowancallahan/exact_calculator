/-!
# Effect confinement

The backend is a `Machine`: a pure function from a state and one line of input
to a new state and the bytes to reply with.  `IO` appears nowhere in its type,
so a machine cannot open files, sockets or processes.  This is enforced by the
type checker, not by review.

The one trusted piece is `Machine.execIO`, which feeds stdin lines to the
machine and writes its replies to stdout.  Nothing else in the backend runs in
`IO`.
-/

namespace Calculator

structure Machine (σ : Type) where
  init : σ
  step : σ → String → σ × ByteArray

namespace Machine

/-! ## Model semantics -/

/-- Run a machine on a list of input lines, giving one reply per line. -/
def run (m : Machine σ) : σ → List String → List ByteArray
  | _, [] => []
  | s, line :: rest => (m.step s line).2 :: run m (m.step s line).1 rest

/-- Exactly one reply per input line. -/
theorem run_length (m : Machine σ) (s : σ) (lines : List String) :
    (run m s lines).length = lines.length := by
  induction lines generalizing s with
  | nil => rfl
  | cons line rest ih => simp [run, ih]

/-- **Causality.** The replies to the first lines do not depend on later lines. -/
theorem run_prefix (m : Machine σ) (s : σ) (lines later : List String) :
    (run m s (lines ++ later)).take lines.length = run m s lines := by
  induction lines generalizing s with
  | nil => simp [run]
  | cons line rest ih => simp [run, ih]

/-! ## The trusted interpreter -/

/-- The only place real I/O happens: read a line from stdin, write the reply to
stdout, repeat until stdin closes. -/
partial def loop (m : Machine σ) (stdin stdout : IO.FS.Stream) (s : σ) : IO Unit := do
  let line ← stdin.getLine
  if line.isEmpty then return
  let (s, reply) := m.step s line.trimAscii.toString
  stdout.write reply
  stdout.flush
  loop m stdin stdout s

def execIO (m : Machine σ) : IO Unit := do
  loop m (← IO.getStdin) (← IO.getStdout) m.init

end Machine
end Calculator
