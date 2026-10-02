# Session summary — 2026-10-01

## What was done
- `git init` on `main`, remote `origin` = https://github.com/rowancallahan/exact_calculator.git (remote is empty; nothing committed yet).
- Two shims written:
  - **Interaction shim** `frontend/shim.py` (PyQt6, ~45 lines with docstring): reads `layout.json`, builds fixed-size window and buttons, spawns the backend, ticks at 60 Hz.
  - **Effect shim** `Calculator/Effect.lean`: `Machine σ` = pure `init` + `step : σ → String → σ × ByteArray`. Only `Machine.execIO` touches `IO` (stdin/stdout). Modelled on `~/pdf_renderer/LeanSvg/Effect.lean`. Theorems `run_length`, `run_prefix` (causality) kernel-checked.
- Stub calculator `Calculator/Calc.lean` (62 lines): Float adding machine, buttons `1`, `+`, `=`, `clear`, starts at 0, plus a seven-segment placeholder display drawn as raw 320×240 RGB pixels.

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
- Replace the seven-segment `render` with LeanSvg; it must hand back raw RGB pixels (pre-PNG-encoding), since the protocol is now pixels, not image files.
- Plotting package (emits SVG), float-library maths package.
- Blocking read in `tick()` freezes the UI if a step takes longer than a frame.
- Mac widget / Swift shim deferred.
