defmodule When.Lexer.Test do
  use ExUnit.Case

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
      assert {:ok, tokens, _} = string |> to_charlist() |> :when_lexer.string()
      assert {tokens, index}
         == {@expected_example_results |> Enum.at(index), index}
    end)
  end
end
