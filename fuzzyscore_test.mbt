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
    let actual = fuzzy_match(pattern, text)
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
    let score = fuzzy_score(pattern, text)
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
    let match_result = fuzzy_match_ignore_case(pattern, text)
    let score = fuzzy_score_ignore_case(pattern, text)
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
    let match_result = fuzzy_match(pattern, text)
    let score = fuzzy_score(pattern, text)
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
    let score = fuzzy_score(pattern, text)
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
    let match_result = fuzzy_match(pattern, text)
    let score = fuzzy_score(pattern, text)
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
    let match_result = fuzzy_match(pattern, text)
    let score = fuzzy_score(pattern, text)
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
    let match_result = fuzzy_match(pattern, text)
    let score = fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  
  @json.inspect(results, content=([["swt","ss_ww_tt",true,23],["abc","aabbcc",true,14],["xyz","xxxyyyzzz",true,12],["ace","abcdef",true,14],["bdf","abcdef",true,2],["aef","abcdef",true,16],["aba","alabama",true,15],["ana","banana",true,8],["ele","element",true,23],["mem","remember",true,7],["fb","foo_bar",true,17],["fB","fooBar",true,12],["tF","testFile",true,11],["hW","hello_world",false,-1],["aa","aardvark",true,15],["ll","hello",true,3],["ss","success",true,12],["oo","good",true,3],["end","frontend",true,7],["end","backend",true,7],["end","append",true,8],["end","endian",true,24],["a.b.c","a.test.b.file.c",true,18],["h-t-m","hello-test-more",true,26],["s/w/t","src/web/test",true,18]]))
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
    let match_result = fuzzy_match(pattern, text)
    let score = fuzzy_score(pattern, text)
    (pattern, text, match_result, score)
  })
  
  @json.inspect(results, content=([["a","aaaaaaa",true,10],["aaa","aaaaaaa",true,23],["aaaa","aaa",false,-1],["abab","aabbab",true,17],["abcd","aabbccdd",true,14],["xyz","xxyyzz",true,14],["abc","axbxc",true,14],["abc","axxxbxxxc",true,12],["test","txexsxt",true,15],["github","github.com",true,56],["readme","README.md",false,-1],["config","config.json",true,56],["v1.2","version_1.2.3",true,23],["2023","file_2023_data",true,16],["js","script.js",true,1],["py","main.py",true,2],["","",true,0],["a","",false,-1],["","a",true,0],["x","x",true,100],["API","ApiController",false,-1],["SQL","sql_query",false,-1],["HTTP","HttpRequest",false,-1]]))
}
