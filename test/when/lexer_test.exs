defmodule When.Lexer.Test do
  use ExUnit.Case

  alias  When.Lexer

  @test_examples [
    "true",
    "'true'",
    "('false')",
    "(FALSE) AND TAG != 'v1.*'",
    "branch = 'master' and tag =~ 'v1.*'",
    "(branch = 'master' and tag =~ 'v1.*') or result != 'passed'",
    "(branch = 'master' AND tag =~ 'v1.*') OR result_reason != 'stopped'",
    "((BRANCH !~ 'master') and tag =~ 'v1.*') OR (result_reason != 'stopped')",
  ]

  @expected_example_results [
    [{:boolean, 1, "true"}],
    [{:string, 1, "true"}],
    [{:'(',  1}, {:string, 1, "false"}, {:')',  1}],
    [
     {:'(',  1}, {:boolean, 1, "false"}, {:')',  1}, {:bool_operator, 1, "and"},
     {:keyword, 1, "tag"}, {:operator, 1, "!="}, {:string, 1, "v1.*"}
    ],
    [
     {:keyword, 1, "branch"}, {:operator, 1, "="}, {:string, 1, "master"},
     {:bool_operator, 1, "and"}, {:keyword, 1, "tag"}, {:operator, 1, "=~"},
     {:string, 1, "v1.*"}
    ],
    [
     {:'(',  1}, {:keyword, 1, "branch"}, {:operator, 1, "="}, {:string, 1, "master"},
     {:bool_operator, 1, "and"}, {:keyword, 1, "tag"}, {:operator, 1, "=~"},
     {:string, 1, "v1.*"}, {:')',  1}, {:bool_operator, 1, "or"}, {:keyword, 1, "result"},
     {:operator, 1, "!="}, {:string, 1, "passed"}
    ],
    [
     {:'(',  1}, {:keyword, 1, "branch"}, {:operator, 1, "="}, {:string, 1, "master"},
     {:bool_operator, 1, "and"}, {:keyword, 1, "tag"}, {:operator, 1, "=~"},
     {:string, 1, "v1.*"}, {:')',  1}, {:bool_operator, 1, "or"},
     {:keyword, 1, "result_reason"}, {:operator, 1, "!="}, {:string, 1, "stopped"}
    ],
    [
     {:'(',  1}, {:'(',  1}, {:keyword, 1, "branch"}, {:operator, 1, "!~"},
     {:string, 1, "master"}, {:')',  1}, {:bool_operator, 1, "and"},
     {:keyword, 1, "tag"}, {:operator, 1, "=~"}, {:string, 1, "v1.*"}, {:')',  1},
     {:bool_operator, 1, "or"}, {:'(',  1}, {:keyword, 1, "result_reason"},
     {:operator, 1, "!="}, {:string, 1, "stopped"}, {:')',  1}
    ]
  ]

  test "test lexer behavior for various string examples" do
    @test_examples
    |> Enum.with_index()
    |> Enum.map(fn {string, index} ->
      assert {:ok, tokens} = Lexer.tokenize(string)
      assert {tokens, index}
         == {@expected_example_results |> Enum.at(index), index}
    end)
  end

  @invald_strings [
    "bran",
    "branch ! = 'bad operator'",
    "branch = unquoted-string",
    "branch = unquoted string with whitespace",
    "Branch =~ 'not-same-case-of-letters'",
    "[branch = 'unsupported-brackets'] and true",
    "# branch = 'unsupported-characters'"
  ]

  @error_messages [
    "Illegal characters: 'bran'.",
    "Illegal characters: '! '.",
    "Illegal characters: 'u'.",
    "Illegal characters: 'u'.",
    "Illegal characters: 'Br'.",
    "Illegal characters: '['.",
    "Illegal characters: '#'.",
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
