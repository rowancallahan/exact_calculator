# Session summary — 2026-10-01

## What was done
- `git init` on `main`, remote `origin` = https://github.com/rowancallahan/exact_calculator.git (remote is empty; nothing committed yet).
- Two shims written:
  - **Interaction shim** `frontend/shim.py` (PyQt6, ~45 lines with docstring): reads `layout.json`, builds fixed-size window and buttons, spawns the backend, ticks at 60 Hz.
  - **Effect shim** `Main.lean` (18 lines): the only `IO` — a `for _ in [0:tickBudget]` loop (no `partial` anywhere in the backend) that reads a stdin line, calls the pure `Calc.step : Calc → String → Calc × ByteArray`, writes the reply to stdout, and breaks when stdin closes. `tickBudget` = 2^63 − 1, the largest `Nat` Lean keeps as a machine integer (≈ 4.9 billion years at 60 Hz). `Effect.lean`, the `Machine` structure and the theorems were removed on request (not needed yet); pattern to return to is `~/pdf_renderer/LeanSvg/Effect.lean`.
- Calculator `Calculator/Calc.lean` (140 lines, all pure, no `partial`): state is the screen text (e.g. `2*(3+4)-5`); keys append, `=` replaces it with the Float result or `E` on error, `clear` empties it. Shunting-yard evaluator for `+ - * /`, parentheses, unary minus, decimals. 5×7 dot-matrix font, last 12 characters shown, raw 320×240 RGB pixels.
- `layout.json`: 19 buttons (0-9, `.`, `+ − × ÷`, `( )`, `=`, `clear`), 32 px tall so Qt's macOS style draws native push buttons. `frontend/shim.py` and `Main.lean` unchanged by this.

- `README.md` (name + drawing only) and `docs/architecture.svg`.

## Protocol (once per tick)
- shim → backend: one line, a button id or empty.
- backend → shim: line `<page> <width> <height>`, then `width * height` raw RGB pixels. A full frame is sent every tick (0.13 ms per tick measured).

## State
- `lake build` passes on Lean 4.34.0 (pinned in `lean-toolchain`), no dependencies.
- Backend verified over a pipe with scripted keys (`1 1 + 1 =` shows 12, `clear` shows 0).
- PyQt6 6.10.2 installed for system python3. Shim verified end to end in Qt offscreen mode (`1 1 + 1 =` shows 12, `clear` shows 0); and launched by Rowan in a real window via `uv run --with PyQt6`.

## Run
```
lake build
python3 frontend/shim.py layout.json .lake/build/bin/backend
```

## Next steps
- Add multiply and divide back (needs precedence; a shunting-yard version existed briefly and was removed as too complicated for now).
- Replace the dot-matrix `render` with LeanSvg; it must hand back raw RGB pixels (pre-PNG-encoding), since the protocol is now pixels, not image files.
- Plotting package (emits SVG), float-library maths package.
- Blocking read in `tick()` freezes the UI if a step takes longer than a frame.
- Mouse input for graph dragging: feasible, would add pointer state to the per-tick input line (discussed, not built).
- Mac widget / Swift shim deferred.
