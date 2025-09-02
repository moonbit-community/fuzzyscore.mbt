///|
fn main {
  // Demo of fuzzy search functionality
  let pattern = "cat"
  let text = "concatenate"
  println("=== Simple Fuzzy Search Demo ===")
  println("Pattern: \{pattern}")
  println("Text: \{text}")
  println("Match: \{@lib.fuzzy_match(pattern, text)}")
  println("Score: \{@lib.fuzzy_score(pattern, text)}")

  // Test case-insensitive matching
  let pattern2 = "MOON"
  let text2 = "MoonBit"
  println("")
  println("=== Case-insensitive Demo ===")
  println("Pattern: \{pattern2}")
  println("Text: \{text2}")
  println("Match: \{@lib.fuzzy_match_ignore_case(pattern2, text2)}")
  println("Score: \{@lib.fuzzy_score_ignore_case(pattern2, text2)}")

  // Demo VS Code algorithm
  println("")
  println("=== VS Code Algorithm Demo ===")
  let (score3, positions3) = @lib.vscode_fuzzy_score(pattern, text, true)
  println("Pattern: \{pattern}")
  println("Text: \{text}")
  println("VS Code Score: \{score3}")
  println("Match Positions: \{positions3}")

  // Test your specific example
  println("")
  println("=== Your Example: 'swt' vs 'ss_ww_tt' ===")
  let pattern4 = "swt"
  let text4 = "ss_ww_tt"
  let (score4, positions4) = @lib.vscode_fuzzy_score(pattern4, text4, true)
  println("Pattern: \{pattern4}")
  println("Text: \{text4}")
  println("Simple Score: \{@lib.fuzzy_score(pattern4, text4)}")
  println("VS Code Score: \{score4}")
  println("Match Positions: \{positions4}")
}
