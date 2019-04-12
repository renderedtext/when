defmodule When.Interpreter.Test do
  use ExUnit.Case

  @test_ast_examples [
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

  @test_params_examples [
    %{"branch" => "master", "tag" => "v1.5", "result" => "passed", "result_reason" => "stopped"},
    %{"branch" => "dev", "tag" => "v1.5", "result" => "passed", "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v2.0", "result" => "passed", "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v1.5", "result" => "failed", "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v2.0", "result" => "passed", "result_reason" => "skipped"},
  ]

  @expected_results [
    [true, false, false, true, true, true, true],
    [true, false, false, false, false, false, true],
    [true, false, false, false, false, false, true],
    [true, false, false, true, true, true, false],
    [true, false, false, false, false, true, true],
  ]

  test "test interpreter behavior for various asts and parmas examples" do
    @test_params_examples
    |> Enum.with_index()
    |> Enum.map(fn {params, param_ind} ->
      @test_ast_examples
      |> Enum.with_index()
      |> Enum.map(fn {ast, ast_ind} ->
        result = When.Interpreter.evaluate(ast, params)
        expected = @expected_results |> Enum.at(param_ind) |> Enum.at(ast_ind)

        assert {param_ind, ast_ind, result} == {param_ind, ast_ind, expected}
      end)
    end)
  end
end
