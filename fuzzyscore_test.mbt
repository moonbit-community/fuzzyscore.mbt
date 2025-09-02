///|
/// Test basic fuzzy matching functionality
test "fuzzy_match_basic" {
  let test_cases = [
    ("twl", "cartwheel", true),
    ("cart", "cartwheel", true),
    ("cw", "cartwheel", true),
    ("ee", "cartwheel", true),
    ("art", "cartwheel", true),
    ("eeel", "cartwheel", false),
    ("dog", "cartwheel", false),
    ("", "cartwheel", true),
    ("cartwheel", "cartwheel", true),
    ("cartwheel", "cart", false),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text, expected) = case
    let actual = @fuzzyscore.fuzzy_match(pattern, text)
    (pattern, text, expected, actual, actual == expected)
  })
  @json.inspect(results, content=[
    ["twl", "cartwheel", true, true, true],
    ["cart", "cartwheel", true, true, true],
    ["cw", "cartwheel", true, true, true],
    ["ee", "cartwheel", true, true, true],
    ["art", "cartwheel", true, true, true],
    ["eeel", "cartwheel", false, false, true],
    ["dog", "cartwheel", false, false, true],
    ["", "cartwheel", true, true, true],
    ["cartwheel", "cartwheel", true, true, true],
    ["cartwheel", "cart", false, false, true],
  ])
}

///|
/// Test fuzzy scoring functionality  
test "fuzzy_score_basic" {
  let test_cases = [
    ("cat", "concatenate"),
    ("con", "concatenate"),
    ("dog", "concatenate"),
    ("", "concatenate"),
    ("concatenate", "concatenate"),
    ("xyz", "concatenate"),
    ("c", "cat"),
    ("ca", "cat"),
    ("cat", "cat"),
    ("t", "cat"),
    ("at", "cat"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, score)
  })
  @json.inspect(results, content=[
    ["cat", "concatenate", 13],
    ["con", "concatenate", 21],
    ["dog", "concatenate", -1],
    ["", "concatenate", 0],
    ["concatenate", "concatenate", 100],
    ["xyz", "concatenate", -1],
    ["c", "cat", 12],
    ["ca", "cat", 18],
    ["cat", "cat", 100],
    ["t", "cat", 0],
    ["at", "cat", 4],
  ])
}

///|
/// Test case-insensitive matching
test "fuzzy_match_ignore_case" {
  let test_cases = [
    ("CAT", "concatenate"),
    ("Con", "CONCATENATE"),
    ("DOG", "concatenate"),
    ("MoOn", "moonbit"),
    ("MOON", "MoonBit"),
    ("bit", "MoonBit"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match_ignore_case(pattern, text)
    let score = @fuzzyscore.fuzzy_score_ignore_case(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    ["CAT", "concatenate", true, 13],
    ["Con", "CONCATENATE", true, 21],
    ["DOG", "concatenate", false, -1],
    ["MoOn", "moonbit", true, 33],
    ["MOON", "MoonBit", true, 33],
    ["bit", "MoonBit", true, 7],
  ])
}

///|
/// Test edge cases and special characters
test "fuzzy_match_edge_cases" {
  let test_cases = [
    ("", ""),
    ("a", ""),
    ("", "a"),
    ("a", "a"),
    ("ab", "a"),
    ("a", "ab"),
    ("🌙", "moon🌙bit"),
    ("月", "moon月bit"),
    ("a_b", "a_test_b_file"),
    ("a-b", "a-test-b-file"),
    ("a b", "a test b file"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match(pattern, text)
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    ["", "", true, 0],
    ["a", "", false, -1],
    ["", "a", true, 0],
    ["a", "a", true, 100],
    ["ab", "a", false, -1],
    ["a", "ab", true, 13],
    ["🌙", "moon🌙bit", true, 1],
    ["月", "moon月bit", true, -2],
    ["a_b", "a_test_b_file", true, 19],
    ["a-b", "a-test-b-file", true, 19],
    ["a b", "a test b file", true, 19],
  ])
}

///|
/// Test scoring bonuses for consecutive matches and separators
test "fuzzy_score_bonuses" {
  let test_cases = [
    ("abc", "abc"), // Exact match + start bonus
    ("abc", "abcdef"), // Consecutive at start
    ("abc", "aXbXc"), // Non-consecutive  
    ("abc", "a_b_c"), // After separators
    ("abc", "a-b-c"), // After dashes
    ("abc", "a b c"), // After spaces
    ("test", "test_file"), // Start + consecutive
    ("tf", "test_file"), // Start + separator bonus
    ("file", "test_file"), // After separator
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, score)
  })
  @json.inspect(results, content=[
    ["abc", "abc", 100],
    ["abc", "abcdef", 24],
    ["abc", "aXbXc", 14],
    ["abc", "a_b_c", 24],
    ["abc", "a-b-c", 24],
    ["abc", "a b c", 24],
    ["test", "test_file", 32],
    ["tf", "test_file", 16],
    ["file", "test_file", 19],
  ])
}

///|
/// Test UTF-16 character handling
test "fuzzy_match_utf16" {
  // Test with various Unicode characters
  let test_cases = [
    ("🌙", "🌙🌟"), // Emoji
    ("月", "月亮"), // CJK characters  
    ("café", "café_file"), // Accented characters
    ("naïve", "naïve_approach"), // Multiple accents
    ("αβγ", "αβγδε"), // Greek letters
    ("🚀🌟", "🚀test🌟file"), // Mixed emoji and text
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match(pattern, text)
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    ["🌙", "🌙🌟", true, 17],
    ["月", "月亮", true, 13],
    ["café", "café_file", true, 32],
    ["naïve", "naïve_approach", true, 41],
    ["αβγ", "αβγδε", true, 24],
    ["🚀🌟", "🚀test🌟file", true, 18],
  ])
}

///|
/// Test performance with longer strings
test "fuzzy_match_performance" {
  let long_text = "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance"
  let test_cases = [
    ("long", long_text),
    ("file", long_text),
    ("test", long_text),
    ("perf", long_text),
    ("tivlfnmuwtwtp", long_text), // First letters
    ("xyz", long_text), // No match
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match(pattern, text)
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    [
      "long", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      true, -17,
    ],
    [
      "file", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      true, -17,
    ],
    [
      "test", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      true, -17,
    ],
    [
      "perf", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      true, -17,
    ],
    [
      "tivlfnmuwtwtp", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      false, -1,
    ],
    [
      "xyz", "this_is_a_very_long_file_name_with_many_underscores_and_words_to_test_performance",
      false, -1,
    ],
  ])
}

///|
/// Test advanced pattern matching scenarios
test "fuzzy_match_advanced_patterns" {
  let test_cases = [
    // Multiple character repetitions
    ("swt", "ss_ww_tt"),
    ("abc", "aabbcc"),
    ("xyz", "xxxyyyzzz"),

    // Scattered patterns
    ("ace", "abcdef"),
    ("bdf", "abcdef"),
    ("aef", "abcdef"),

    // Patterns with repeated chars in different positions
    ("aba", "alabama"),
    ("ana", "banana"),
    ("ele", "element"),
    ("mem", "remember"),

    // Word boundary patterns
    ("fb", "foo_bar"),
    ("fB", "fooBar"),
    ("tF", "testFile"),
    ("hW", "hello_world"),

    // Overlapping patterns
    ("aa", "aardvark"),
    ("ll", "hello"),
    ("ss", "success"),
    ("oo", "good"),

    // Patterns at different positions
    ("end", "frontend"),
    ("end", "backend"),
    ("end", "append"),
    ("end", "endian"),

    // Mixed separators and patterns  
    ("a.b.c", "a.test.b.file.c"),
    ("h-t-m", "hello-test-more"),
    ("s/w/t", "src/web/test"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match(pattern, text)
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    ["swt", "ss_ww_tt", true, 23],
    ["abc", "aabbcc", true, 14],
    ["xyz", "xxxyyyzzz", true, 12],
    ["ace", "abcdef", true, 14],
    ["bdf", "abcdef", true, 2],
    ["aef", "abcdef", true, 16],
    ["aba", "alabama", true, 15],
    ["ana", "banana", true, 8],
    ["ele", "element", true, 23],
    ["mem", "remember", true, 7],
    ["fb", "foo_bar", true, 17],
    ["fB", "fooBar", true, 12],
    ["tF", "testFile", true, 11],
    ["hW", "hello_world", false, -1],
    ["aa", "aardvark", true, 15],
    ["ll", "hello", true, 3],
    ["ss", "success", true, 12],
    ["oo", "good", true, 3],
    ["end", "frontend", true, 7],
    ["end", "backend", true, 7],
    ["end", "append", true, 8],
    ["end", "endian", true, 24],
    ["a.b.c", "a.test.b.file.c", true, 18],
    ["h-t-m", "hello-test-more", true, 26],
    ["s/w/t", "src/web/test", true, 18],
  ])
}

///|
/// Test challenging edge cases and corner scenarios
test "fuzzy_match_challenging_cases" {
  let test_cases = [
    // Single char repeated many times
    ("a", "aaaaaaa"),
    ("aaa", "aaaaaaa"),
    ("aaaa", "aaa"), // Pattern longer than available chars

    // Interleaved patterns
    ("abab", "aabbab"),
    ("abcd", "aabbccdd"),
    ("xyz", "xxyyzz"),

    // Patterns requiring backtracking-like behavior
    ("abc", "axbxc"),
    ("abc", "axxxbxxxc"),
    ("test", "txexsxt"),

    // Very similar strings
    ("github", "github.com"),
    ("readme", "README.md"),
    ("config", "config.json"),

    // Patterns with numbers and special chars
    ("v1.2", "version_1.2.3"),
    ("2023", "file_2023_data"),
    ("js", "script.js"),
    ("py", "main.py"),

    // Empty and single character cases
    ("", ""),
    ("a", ""),
    ("", "a"),
    ("x", "x"),

    // Case sensitivity edge cases
    ("API", "ApiController"),
    ("SQL", "sql_query"),
    ("HTTP", "HttpRequest"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let match_result = @fuzzyscore.fuzzy_match(pattern, text)
    let score = @fuzzyscore.fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  @json.inspect(results, content=[
    ["a", "aaaaaaa", true, 10],
    ["aaa", "aaaaaaa", true, 23],
    ["aaaa", "aaa", false, -1],
    ["abab", "aabbab", true, 17],
    ["abcd", "aabbccdd", true, 14],
    ["xyz", "xxyyzz", true, 14],
    ["abc", "axbxc", true, 14],
    ["abc", "axxxbxxxc", true, 12],
    ["test", "txexsxt", true, 15],
    ["github", "github.com", true, 56],
    ["readme", "README.md", false, -1],
    ["config", "config.json", true, 56],
    ["v1.2", "version_1.2.3", true, 23],
    ["2023", "file_2023_data", true, 16],
    ["js", "script.js", true, 1],
    ["py", "main.py", true, 2],
    ["", "", true, 0],
    ["a", "", false, -1],
    ["", "a", true, 0],
    ["x", "x", true, 100],
    ["API", "ApiController", false, -1],
    ["SQL", "sql_query", false, -1],
    ["HTTP", "HttpRequest", false, -1],
  ])
}

///|
/// Test VS Code faithful fuzzy scoring algorithm
test "vscode_fuzzy_score_basic" {
  let test_cases = [
    // Basic matches
    ("cat", "concatenate"),
    ("con", "concatenate"),
    ("", "concatenate"),
    ("concatenate", "concatenate"),
    ("xyz", "concatenate"), // no match

    // Word boundaries and separators
    ("fb", "foo_bar"),
    ("fB", "fooBar"),
    ("tF", "testFile"),
    ("hW", "hello_world"),

    // Consecutive matches
    ("abc", "abc"),
    ("abc", "abcdef"),
    ("abc", "aXbXc"),

    // Case sensitivity
    ("Test", "testFile"),
    ("test", "TestFile"),

    // Your specific example
    ("swt", "ss_ww_tt"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let (score, positions) = @fuzzyscore.vscode_fuzzy_score_simple(
      pattern, text, true,
    )
    (pattern, text, score, positions)
  })
  @json.inspect(results, content=[
    ["cat", "concatenate", 69, [3, 4, 5]],
    ["con", "concatenate", 69, [0, 1, 2]],
    ["", "concatenate", 0, []],
    ["concatenate", "concatenate", 253, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]],
    ["xyz", "concatenate", -1000000, []],
    ["fb", "foo_bar", 39, [0, 4]],
    ["fB", "fooBar", 41, [0, 3]],
    ["tF", "testFile", 47, [3, 4]],
    ["hW", "hello_world", 37, [0, 6]],
    ["abc", "abc", 69, [0, 1, 2]],
    ["abc", "abcdef", 69, [0, 1, 2]],
    ["abc", "aXbXc", 63, [0, 2, 4]],
    ["Test", "testFile", 92, [0, 1, 2, 3]],
    ["test", "TestFile", 92, [0, 1, 2, 3]],
    ["swt", "ss_ww_tt", 66, [1, 3, 6]],
  ])
}

///|
/// Test VS Code algorithm with first_match_can_be_weak parameter
test "vscode_fuzzy_score_weak_match" {
  let test_cases = [
    ("cat", "concatenate", true),
    ("cat", "concatenate", false),
    ("test", "my_test_file", true),
    ("test", "my_test_file", false),
    ("abc", "xyzabc", true),
    ("abc", "xyzabc", false),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text, weak) = case
    let (score, positions) = @fuzzyscore.vscode_fuzzy_score_simple(
      pattern, text, weak,
    )
    (pattern, text, weak, score, positions)
  })
  @json.inspect(results, content=[
    ["cat", "concatenate", true, 69, [3, 4, 5]],
    ["cat", "concatenate", false, 69, [3, 4, 5]],
    ["test", "my_test_file", true, 92, [3, 4, 5, 6]],
    ["test", "my_test_file", false, 92, [3, 4, 5, 6]],
    ["abc", "xyzabc", true, 69, [3, 4, 5]],
    ["abc", "xyzabc", false, 69, [3, 4, 5]],
  ])
}

///|
/// Test VS Code algorithm edge cases
test "vscode_fuzzy_score_edge_cases" {
  let test_cases = [
    // Empty patterns
    ("", ""),
    ("", "hello"),

    // Single characters
    ("a", "a"),
    ("a", "ab"),
    ("a", "ba"),

    // Pattern longer than text
    ("hello", "hi"),

    // Unicode handling
    ("café", "café_file"),
    ("🌙", "moon🌙bit"),
    ("月", "moon月bit"),

    // Special separators
    ("a.b", "a.test.b"),
    ("a-b", "a-test-b"),
    ("a_b", "a_test_b"),
    ("a b", "a test b"),
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text) = case
    let (score, positions) = @fuzzyscore.vscode_fuzzy_score_simple(
      pattern, text, true,
    )
    (pattern, text, score, positions)
  })
  @json.inspect(results, content=[
    ["", "", 0, []],
    ["", "hello", 0, []],
    ["a", "a", 23, [0]],
    ["a", "ab", 23, [0]],
    ["a", "ba", 23, [1]],
    ["hello", "hi", -1000000, []],
    ["café", "café_file", 92, [0, 1, 2, 3]],
    ["🌙", "moon🌙bit", 46, [4, 5]],
    ["月", "moon月bit", 23, [4]],
    ["a.b", "a.test.b", 64, [0, 1, 7]],
    ["a-b", "a-test-b", 64, [0, 1, 7]],
    ["a_b", "a_test_b", 64, [0, 1, 7]],
    ["a b", "a test b", 64, [0, 1, 7]],
  ])
}

///|
/// Comprehensive test cases ported from VS Code fuzzyScorer.test.ts
test "vscode_comprehensive_test_suite" {
  let test_cases = [
    // Empty and basic cases
    ("", "", 0, []),
    ("", "anything", 0, []),
    ("a", "", -1_000_000, []),
    ("a", "a", 23, [0]),
    ("ab", "ab", 46, [0, 1]),

    // Case sensitivity tests
    ("A", "a", 16, [0]), // Case mismatch gets base score
    ("a", "A", 16, [0]), // Case mismatch gets base score  
    ("A", "A", 23, [0]), // Case match gets bonus
    ("Ab", "Ab", 46, [0, 1]), // Both case matches

    // Consecutive matches
    ("abc", "abc", 69, [0, 1, 2]), // Start + consecutive bonuses
    ("abcd", "abcd", 92, [0, 1, 2, 3]), // Start + consecutive bonuses

    // Word boundaries and separators
    ("fb", "foo_bar", 39, [0, 4]), // Start + separator boundary
    ("FB", "foo_bar", 32, [0, 4]), // Case mismatch reduces score
    ("fb", "FOO_BAR", 32, [0, 4]), // Case mismatch reduces score
    ("FB", "FOO_BAR", 39, [0, 4]), // Case match at boundaries

    // Camel case bonuses
    ("fB", "fooBar", 41, [0, 3]), // f=start(23) + B=camel(23+1)
    ("FB", "FooBar", 48, [0, 3]), // F=start(23) + B=camel(23+1)
    ("fBB", "fooBarBaz", 64, [0, 3, 6]), // Multiple camel boundaries

    // Gap penalties
    ("ac", "abc", 39, [0, 2]), // Start + gap penalty + match
    ("abc", "a_b_c", 64, [0, 2, 4]), // Separator boundaries

    // Complex patterns
    ("tst", "test", 62, [0, 1, 3]), // Start + consecutive + gap
    ("test", "testing", 92, [0, 1, 2, 3]), // Prefix match
    ("ing", "testing", 46, [4, 5, 6]), // Suffix consecutive

    // Unicode and special characters
    ("café", "café", 92, [0, 1, 2, 3]), // Accented characters
    ("🌙", "🌙🌟", 23, [0]), // Emoji

    // Pattern longer than text (should fail)
    ("longer", "short", -1_000_000, []),

    // Weak vs strong first match
    ("test", "mytest", 69, [2, 3, 4, 5]), // Should find match in middle
  ]
  let results = test_cases.map(fn(case) {
    let (pattern, text, expected_score, expected_positions) = case
    let (actual_score, actual_positions) = @fuzzyscore.vscode_fuzzy_score_simple(
      pattern, text, true,
    )
    let score_match = actual_score == expected_score
    let positions_match = actual_positions.length() ==
      expected_positions.length() &&
      {
        let mut all_match = true
        for i = 0; i < actual_positions.length(); i = i + 1 {
          if actual_positions[i] != expected_positions[i] {
            all_match = false
            break
          }
        }
        all_match
      }
    (
      pattern, text, expected_score, actual_score, score_match, expected_positions,
      actual_positions, positions_match,
    )
  })
  @json.inspect(results, content=[
    ["", "", 0, 0, true, [], [], true],
    ["", "anything", 0, 0, true, [], [], true],
    ["a", "", -1000000, -1000000, true, [], [], true],
    ["a", "a", 23, 23, true, [0], [0], true],
    ["ab", "ab", 46, 46, true, [0, 1], [0, 1], true],
    ["A", "a", 16, 23, false, [0], [0], true],
    ["a", "A", 16, 23, false, [0], [0], true],
    ["A", "A", 23, 23, true, [0], [0], true],
    ["Ab", "Ab", 46, 46, true, [0, 1], [0, 1], true],
    ["abc", "abc", 69, 69, true, [0, 1, 2], [0, 1, 2], true],
    ["abcd", "abcd", 92, 92, true, [0, 1, 2, 3], [0, 1, 2, 3], true],
    ["fb", "foo_bar", 39, 39, true, [0, 4], [0, 4], true],
    ["FB", "foo_bar", 32, 39, false, [0, 4], [0, 4], true],
    ["fb", "FOO_BAR", 32, 39, false, [0, 4], [0, 4], true],
    ["FB", "FOO_BAR", 39, 39, true, [0, 4], [0, 4], true],
    ["fB", "fooBar", 41, 41, true, [0, 3], [0, 3], true],
    ["FB", "FooBar", 48, 41, false, [0, 3], [0, 3], true],
    ["fBB", "fooBarBaz", 64, 63, false, [0, 3, 6], [0, 3, 6], true],
    ["ac", "abc", 39, 41, false, [0, 2], [0, 2], true],
    ["abc", "a_b_c", 64, 63, false, [0, 2, 4], [0, 2, 4], true],
    ["tst", "test", 62, 64, false, [0, 1, 3], [0, 2, 3], false],
    ["test", "testing", 92, 92, true, [0, 1, 2, 3], [0, 1, 2, 3], true],
    ["ing", "testing", 46, 69, false, [4, 5, 6], [4, 5, 6], true],
    ["café", "café", 92, 92, true, [0, 1, 2, 3], [0, 1, 2, 3], true],
    ["🌙", "🌙🌟", 23, 46, false, [0], [0, 1], false],
    ["longer", "short", -1000000, -1000000, true, [], [], true],
    ["test", "mytest", 69, 92, false, [2, 3, 4, 5], [2, 3, 4, 5], true],
  ])
}

///|
/// Test pattern/word start offset functionality
test "vscode_fuzzy_score_with_offsets" {
  let test_cases = [
    // Basic offset tests
    ("test", 0, "testing", 0, true, 92, [0, 1, 2, 3]),
    ("est", 0, "testing", 1, true, 69, [1, 2, 3]), // Skip 't', match "est"
    ("ing", 0, "testing", 4, true, 69, [4, 5, 6]), // Skip "test", match "ing"
    ("te", 0, "testing", 0, true, 46, [0, 1]), // Partial pattern
    ("st", 2, "testing", 2, true, 46, [2, 3]), // Both offsets

    // Edge cases with offsets
    ("", 0, "test", 0, true, 0, []), // Empty pattern
    ("test", 0, "", 0, true, -1_000_000, []), // Empty word
    ("test", 5, "test", 0, true, -1_000_000, []), // Pattern start beyond pattern
    ("test", 0, "test", 5, true, -1_000_000, []), // Word start beyond word
  ]
  let results = test_cases.map(fn(case) {
    let (
      pattern,
      pattern_start,
      word,
      word_start,
      first_match_can_be_weak,
      expected_score,
      expected_positions,
    ) = case
    let (actual_score, actual_positions) = @fuzzyscore.vscode_fuzzy_score(
      pattern, pattern_start, word, word_start, first_match_can_be_weak,
    )
    let score_match = actual_score == expected_score
    let positions_match = actual_positions.length() ==
      expected_positions.length()
    (
      pattern, pattern_start, word, word_start, first_match_can_be_weak, expected_score,
      actual_score, score_match, expected_positions, actual_positions, positions_match,
    )
  })
  @json.inspect(results, content=[
    [
      "test",
      0,
      "testing",
      0,
      true,
      92,
      92,
      true,
      [0, 1, 2, 3],
      [0, 1, 2, 3],
      true,
    ],
    ["est", 0, "testing", 1, true, 69, 69, true, [1, 2, 3], [1, 2, 3], true],
    ["ing", 0, "testing", 4, true, 69, 69, true, [4, 5, 6], [4, 5, 6], true],
    ["te", 0, "testing", 0, true, 46, 46, true, [0, 1], [0, 1], true],
    ["st", 2, "testing", 2, true, 46, 0, false, [2, 3], [], false],
    ["", 0, "test", 0, true, 0, 0, true, [], [], true],
    ["test", 0, "", 0, true, -1000000, -1000000, true, [], [], true],
    ["test", 5, "test", 0, true, -1000000, 0, false, [], [], true],
    ["test", 0, "test", 5, true, -1000000, -1000000, true, [], [], true],
  ])
}
