///|
/// Basic fuzzy search that checks if pattern is a subsequence of text
pub fn fuzzy_match(pattern : String, text : String) -> Bool {
  let pattern_len = pattern.length()
  let text_len = text.length()
  if pattern_len == 0 {
    return true
  }
  if pattern_len > text_len {
    return false
  }
  if pattern_len == text_len {
    return pattern == text
  }
  let mut pattern_idx = 0
  let mut text_idx = 0
  while pattern_idx < pattern_len && text_idx < text_len {
    let pattern_char = pattern[pattern_idx]
    let text_char = text[text_idx]
    if pattern_char == text_char {
      pattern_idx += 1
    }
    text_idx += 1
  }
  pattern_idx == pattern_len
}

///|
/// Advanced fuzzy scoring algorithm similar to VS Code's implementation
/// Returns a score (higher is better) or -1 if no match
pub fn fuzzy_score(pattern : String, text : String) -> Int {
  let pattern_len = pattern.length()
  let text_len = text.length()
  if pattern_len == 0 {
    return 0
  }
  if pattern_len > text_len {
    return -1
  }
  if pattern_len == text_len {
    return if pattern == text { 100 } else { -1 }
  }

  // Simple scoring: find all pattern characters in order
  let mut pattern_idx = 0
  let mut text_idx = 0
  let mut score = 0
  let mut consecutive_matches = 0
  let mut last_match_idx = -1
  while pattern_idx < pattern_len && text_idx < text_len {
    let pattern_char = pattern[pattern_idx]
    let text_char = text[text_idx]
    if pattern_char == text_char {
      // Base score for match
      score += 1

      // Bonus for consecutive matches
      if last_match_idx == text_idx - 1 {
        consecutive_matches += 1
        score += consecutive_matches * 2 // Increasing bonus for longer sequences
      } else {
        consecutive_matches = 0
      }

      // Bonus for match at start
      if text_idx == 0 {
        score += 10
      }

      // Bonus for match after separator (space, underscore, etc.)
      if text_idx > 0 {
        let prev_char = text[text_idx - 1]
        if prev_char == 32 || prev_char == 95 || prev_char == 45 { // space, underscore, dash
          score += 5
        }
      }
      last_match_idx = text_idx
      pattern_idx += 1
    }
    text_idx += 1
  }
  if pattern_idx == pattern_len {
    // Penalty for long text relative to pattern
    let length_penalty = (text_len - pattern_len) / 2
    score - length_penalty
  } else {
    -1
  }
}

///|
/// Case-insensitive fuzzy matching
pub fn fuzzy_match_ignore_case(pattern : String, text : String) -> Bool {
  fuzzy_match(pattern.to_lower(), text.to_lower())
}

///|
/// Case-insensitive fuzzy scoring
pub fn fuzzy_score_ignore_case(pattern : String, text : String) -> Int {
  fuzzy_score(pattern.to_lower(), text.to_lower())
}
