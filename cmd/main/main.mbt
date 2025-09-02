///|
fn main {
  // Demo of fuzzy search functionality
  let pattern = "cat"
  let text = "concatenate"
  println("Fuzzy search demo:")
  println("Pattern: \{pattern}")
  println("Text: \{text}")
  println("Match: \{@lib.fuzzy_match(pattern, text)}")
  println("Score: \{@lib.fuzzy_score(pattern, text)}")

  // Test case-insensitive matching
  let pattern2 = "MOON"
  let text2 = "MoonBit"
  println("")
  println("Case-insensitive demo:")
  println("Pattern: \{pattern2}")
  println("Text: \{text2}")
  println("Match: \{@lib.fuzzy_match_ignore_case(pattern2, text2)}")
  println("Score: \{@lib.fuzzy_score_ignore_case(pattern2, text2)}")
}
