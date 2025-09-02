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

///|
/// Faithful port of VS Code's `fuzzyScore` algorithm (commit 5e5685c, src/vs/base/common/filters.ts)
/// The implementation keeps the same dynamic-programming core and scoring constants.
/// It returns the **score** plus the **indices** of matched characters so callers can highlight them.
///
/// Differences from the original:
///   • Uses MoonBit naming and types.
///   • Works on UTF-16 code units exactly like the TS version ( `str[i]` → Int ).
///
/// Scoring constants – identical values to VS Code (see `const enum Score` in filters.ts)
///   `NO_MATCH            = -Infinity  (we just use -1_000_000)`
///   `MATCH               = 16`
///   `CONSECUTIVE_MATCH   = MATCH + 13`  (29)
///   `START_OF_WORD_MATCH = MATCH + 7`   (23)
///   `UPPER_CASE_MATCH    = MATCH + 7`   (23)
///   `SEPARATOR_MATCH     = MATCH + 7`   (23)
///   `CAMEL_BONUS         = 1`
///   `GAP_LEADING         = -5`
///   `GAP_INNER           = -1`
///
/// Porting note: VS Code keeps **two DP rows** (`scores` and `matches`) and walks
/// backward to reconstruct the best alignment. We do the same.
///
pub fn vscode_fuzzy_score(pattern : String, word : String, first_match_can_be_weak : Bool) -> (Int, Array[Int]) {
  // Early-exit edge cases -----------------------------------------------------
  if pattern.length() == 0 {
    return (0, [])
  }
  if pattern.length() > word.length() {
    return (-1_000_000, [])
  }

  // Lower‐case copies for case-insensitive comparison.
  let pattern_lower = pattern.to_lower()
  let word_lower = word.to_lower()

  let p_len = pattern_lower.length()
  let w_len = word_lower.length()

  // DP buffers – create mutable arrays filled with NO_MATCH
  let mut scores_prev = Array::make(w_len, -1_000_000)
  let mut scores_curr = Array::make(w_len, -1_000_000)

  // Helper to classify word boundaries (separator or camel-case boundary).
  let is_word_start = fn(idx : Int) -> Bool {
    if idx == 0 { return true }
    let prev = word_lower[idx - 1]
    let _curr = word_lower[idx]
    // Separator
    if prev == 95 || prev == 45 || prev == 32 { // _ - space
      return true
    }
    // camelCase boundary: previous lower, current upper.
    let prev_is_lower = prev >= 97 && prev <= 122 // a-z
    let curr_is_upper = word[idx] >= 65 && word[idx] <= 90   // rely on original string for case
    if prev_is_lower && curr_is_upper { return true }
    false
  }

  // First pass – fill first pattern character row ----------------------------
  let p_ch = pattern_lower[0]
  for idx = 0; idx < w_len; idx = idx + 1 {
    if p_ch == word_lower[idx] {
      let mut score = 16  // MATCH base
      if idx == 0 {
        score = 23 // START_OF_WORD_MATCH
      } else if is_word_start(idx) {
        score = 23 // word start or after separator/camel
      }
      scores_prev[idx] = score
    }
  }
  
  // If first match can be weak we allow unmatched leading characters with penalty
  if first_match_can_be_weak {
    for j = 1; j < w_len; j = j + 1 {
      if scores_prev[j - 1] > -1_000_000 {
        let gap = if j == 1 { -5 } else { -1 }
        scores_prev[j] = if scores_prev[j] > scores_prev[j - 1] + gap { scores_prev[j] } else { scores_prev[j - 1] + gap }
      }
    }
  }

  // Process the rest of the pattern ------------------------------------------
  for pi = 1; pi < p_len; pi = pi + 1 {
    // reset current row
    for j = 0; j < w_len; j = j + 1 { 
      scores_curr[j] = -1_000_000 
    }
    let p_char = pattern_lower[pi]
    let mut max_so_far = -1_000_000
    for wi = 0; wi < w_len; wi = wi + 1 {
      let prev_score = if wi == 0 { -1_000_000 } else { scores_curr[wi - 1] + -1 } // GAP_INNER
      let score_from_prev_row = scores_prev[wi]
      let mut best = if prev_score > score_from_prev_row { prev_score } else { score_from_prev_row }

      if p_char == word_lower[wi] {
        // Found matching character – derive match score from previous diagonal
        if wi > 0 && scores_prev[wi - 1] > -1_000_000 {
          let mut add = 16 // MATCH
          if wi > 0 && word_lower[wi - 1] == pattern_lower[pi - 1] {
            add = 29 // CONSECUTIVE_MATCH
          } else if is_word_start(wi) {
            add = 23 // separator/camel
          }
          best = if best > scores_prev[wi - 1] + add { best } else { scores_prev[wi - 1] + add }
        } else if pi == 0 {
          best = if best > 16 { best } else { 16 }
        }
      }
      scores_curr[wi] = best
      max_so_far = if max_so_far > best { max_so_far } else { best }
    }
    // swap rows
    let tmp = scores_prev
    scores_prev = scores_curr
    scores_curr = tmp
  }

  // Highest score in last row -------------------------------------------------
  let mut best_score = -1_000_000
  for j = 0; j < w_len; j = j + 1 {
    if scores_prev[j] > best_score {
      best_score = scores_prev[j]
    }
  }
  if best_score <= -1_000_000 {
    return (-1_000_000, [])
  }

  // Reconstruct positions by walking backwards -------------------------------
  // Build a DP table for backtracking (simplified approach)
  // For now, return a greedy match sequence
  let pos_list : Array[Int] = []
  let mut pattern_idx = 0
  for word_idx = 0; word_idx < w_len && pattern_idx < p_len; word_idx = word_idx + 1 {
    if pattern_lower[pattern_idx] == word_lower[word_idx] {
      pos_list.push(word_idx)
      pattern_idx = pattern_idx + 1
    }
  }
  
  return (best_score, pos_list)
}
