import Calculator

/-! Entry point: hand the pure calculator to the trusted stdin/stdout interpreter. -/

def main : IO Unit := Calculator.calculator.execIO
