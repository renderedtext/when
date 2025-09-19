defmodule When.Lexer.Test do
  use ExUnit.Case

  alias When.Lexer

  @test_examples [
    "true",
    "'true'",
    "('false')",
    "(FALSE) AND TAG != 'v1.*'",
    "branch = 'master' and tag =~ 'v1.*'",
    "(branch = 'master' and tag =~ 'v1.*') or result != 'passed'",
    "(branch = 'master' AND tag =~ 'v1.*') OR result_reason != 'stopped'",
    "((BRANCH !~ 'master') and tag =~ 'v1.*') OR (result_reason != 'stopped')",
    "(pull_request =~ '.*' and result = 'passed') or PULL_REQUEST !~ '.*'",
    "some_fun('abc', 123, 45.67, true) or false",
    "some_fun([123, 45.67]) or [false] and []",
    "some_fun('a', {b: 123}, [false]) or {}",
    "'hello' = 'world'",
    "'test' != 'example'",
    "'pattern' =~ 'test.*'",
    "'text' !~ 'number.*'"
  ]

  @expected_example_results [
    [{:boolean, 1, true}],
    [{:string, 1, "true"}],
    [{:"(", 1}, {:string, 1, "false"}, {:")", 1}],
    [
      {:"(", 1},
      {:boolean, 1, false},
      {:")", 1},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "tag"},
      {:operator, 1, "!="},
      {:string, 1, "v1.*"}
    ],
    [
      {:keyword, 1, "branch"},
      {:operator, 1, "="},
      {:string, 1, "master"},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "tag"},
      {:operator, 1, "=~"},
      {:string, 1, "v1.*"}
    ],
    [
      {:"(", 1},
      {:keyword, 1, "branch"},
      {:operator, 1, "="},
      {:string, 1, "master"},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "tag"},
      {:operator, 1, "=~"},
      {:string, 1, "v1.*"},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:keyword, 1, "result"},
      {:operator, 1, "!="},
      {:string, 1, "passed"}
    ],
    [
      {:"(", 1},
      {:keyword, 1, "branch"},
      {:operator, 1, "="},
      {:string, 1, "master"},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "tag"},
      {:operator, 1, "=~"},
      {:string, 1, "v1.*"},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:keyword, 1, "result_reason"},
      {:operator, 1, "!="},
      {:string, 1, "stopped"}
    ],
    [
      {:"(", 1},
      {:"(", 1},
      {:keyword, 1, "branch"},
      {:operator, 1, "!~"},
      {:string, 1, "master"},
      {:")", 1},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "tag"},
      {:operator, 1, "=~"},
      {:string, 1, "v1.*"},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:"(", 1},
      {:keyword, 1, "result_reason"},
      {:operator, 1, "!="},
      {:string, 1, "stopped"},
      {:")", 1}
    ],
    [
      {:"(", 1},
      {:keyword, 1, "pull_request"},
      {:operator, 1, "=~"},
      {:string, 1, ".*"},
      {:bool_operator, 1, "and"},
      {:keyword, 1, "result"},
      {:operator, 1, "="},
      {:string, 1, "passed"},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:keyword, 1, "pull_request"},
      {:operator, 1, "!~"},
      {:string, 1, ".*"}
    ],
    [
      {:identifier, 1, :some_fun},
      {:"(", 1},
      {:string, 1, "abc"},
      {:",", 1},
      {:integer, 1, 123},
      {:",", 1},
      {:float, 1, 45.67},
      {:",", 1},
      {:boolean, 1, true},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:boolean, 1, false}
    ],
    [
      {:identifier, 1, :some_fun},
      {:"(", 1},
      {:"[", 1},
      {:integer, 1, 123},
      {:",", 1},
      {:float, 1, 45.67},
      {:"]", 1},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:"[", 1},
      {:boolean, 1, false},
      {:"]", 1},
      {:bool_operator, 1, "and"},
      {:"[", 1},
      {:"]", 1}
    ],
    [
      {:identifier, 1, :some_fun},
      {:"(", 1},
      {:string, 1, "a"},
      {:",", 1},
      {:"{", 1},
      {:map_key, 1, :b},
      {:integer, 1, 123},
      {:"}", 1},
      {:",", 1},
      {:"[", 1},
      {:boolean, 1, false},
      {:"]", 1},
      {:")", 1},
      {:bool_operator, 1, "or"},
      {:"{", 1},
      {:"}", 1}
    ],
    [
      {:string, 1, "hello"},
      {:operator, 1, "="},
      {:string, 1, "world"}
    ],
    [
      {:string, 1, "test"},
      {:operator, 1, "!="},
      {:string, 1, "example"}
    ],
    [
      {:string, 1, "pattern"},
      {:operator, 1, "=~"},
      {:string, 1, "test.*"}
    ],
    [
      {:string, 1, "text"},
      {:operator, 1, "!~"},
      {:string, 1, "number.*"}
    ]
  ]

  test "test lexer behavior for various string examples" do
    @test_examples
    |> Enum.with_index()
    |> Enum.map(fn {string, index} ->
      assert {:ok, tokens} = Lexer.tokenize(string)

      assert {tokens, index} ==
               {@expected_example_results |> Enum.at(index), index}
    end)
  end

  @invald_strings [
    "branch ! = 'bad operator'",
    "# branch = 'unsupported-characters'",
    "_identifier_needs_to_start_with_lettter(123)",
    "cant_contain_&^('identifier only accepts alfa-numerics, uderscores and dashes')",
    "fun(123.0) and invalid_number(123.456.2323)",
    "{_map_key_needs_to_start_with_lettter: 123}",
    "{map_key_cant_contain_&^: 'it only accepts alfa-numerics, uderscores and dashes'}"
  ]

  @error_messages [
    "Illegal characters: '! '.",
    "Illegal characters: '#'.",
    "Illegal characters: '_'.",
    "Illegal characters: '&'.",
    "Illegal characters: '.'.",
    "Illegal characters: '_'.",
    "Illegal characters: '&'."
  ]

  test "lexer returns error when invalid string is given" do
    @invald_strings
    |> Enum.with_index()
    |> Enum.map(fn {string, index} ->
      assert {:error, message} = Lexer.tokenize(string)
      specific_error = @error_messages |> Enum.at(index)

      assert {message, index} ==
               {"Lexical error on line 1. - " <> specific_error, index}
    end)
  end
end
