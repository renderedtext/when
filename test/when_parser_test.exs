defmodule When.WhenParser.Test do
  use ExUnit.Case

  @test_examples [
    "true",
    "'true'",
    "('false')",
    "(FALSE) AND TAG != 'v1.*'",
    "branch = 'master' and tag =~ 'v1.*'",
    "(branch = 'master' and tag =~ 'v1.*') or result != 'passed'",
    "branch = 'master' AND (tag =~ 'v1.*' OR result_reason != 'stopped')",
    "(branch = 'master' and result != 'failed') or
     (tag =~ 'v1.*' and result = 'passed' and result_reason != 'skipped')",
  ]

  @expected_tokens [
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
     {:keyword, 1, "branch"}, {:operator, 1, "="}, {:string, 1, "master"},
     {:bool_operator, 1, "and"}, {:'(',  1}, {:keyword, 1, "tag"}, {:operator, 1, "=~"},
     {:string, 1, "v1.*"}, {:bool_operator, 1, "or"}, {:keyword, 1, "result_reason"},
     {:operator, 1, "!="}, {:string, 1, "stopped"}, {:')',  1}
    ],
    [
     {:'(',  1}, {:keyword, 1, "branch"}, {:operator, 1, "="}, {:string, 1, "master"},
     {:bool_operator, 1, "and"}, {:keyword, 1, "result"}, {:operator, 1, "!="},
     {:string, 1, "failed"}, {:')',  1}, {:bool_operator, 1, "or"}, {:'(',  2},
     {:keyword, 2, "tag"}, {:operator, 2, "=~"}, {:string, 2, "v1.*"},
     {:bool_operator, 2, "and"}, {:keyword, 2, "result"}, {:operator, 2, "="},
     {:string, 2, "passed"}, {:bool_operator, 2, "and"}, {:keyword, 2, "result_reason"},
     {:operator, 2, "!="}, {:string, 2, "skipped"}, {:')',  2}
    ]
  ]

  @expected_parse_results [
    "true",
    "true",
    "false",
    {"and", "false", {"!=", "tag", "v1.*"}},
    {"and", {"=", "branch", "master"}, {"=~", "tag", "v1.*"}},
    {"or", {"and", {"=", "branch", "master"}, {"=~", "tag", "v1.*"}},
           {"!=", "result", "passed"}},
    {"and", {"=", "branch", "master"},
            {"or", {"=~", "tag", "v1.*"}, {"!=", "result_reason", "stopped"}}},
    {"or", {"and", {"=", "branch", "master"}, {"!=", "result", "failed"}},
           {"and", {"and", {"=~", "tag", "v1.*"}, {"=", "result", "passed"}},
                   {"!=", "result_reason", "skipped"}}}
  ]

    test "test parser behavior for various token examples" do
      @test_examples
      |> Enum.with_index()
      |> Enum.map(fn {string, index} ->
        assert {:ok, tokens, _} = string |> to_charlist() |> :when_lexer.string()
        assert {tokens, index}
           == {@expected_tokens |> Enum.at(index), index}
      end)

      @expected_tokens
      |> Enum.with_index()
      |> Enum.map(fn {tokens, index} ->
        assert {:ok, ast} = :when_parser.parse(tokens)
        assert {ast, index}
           == {@expected_parse_results |> Enum.at(index), index}
      end)
    end
end
