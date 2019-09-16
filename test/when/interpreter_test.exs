defmodule When.Interpreter.Test do
  use ExUnit.Case

  alias When.Interpreter

  @test_ast_examples [
    true,
    false,
    {"and", false, {"!=", {:keyword, "tag"}, "v1.*"}},
    {"and", {"=", {:keyword, "branch"}, "master"}, {"=~", {:keyword, "tag"}, "v1.*"}},
    {"or", {"and", {"=", {:keyword, "branch"}, "master"}, {"=~", {:keyword, "tag"}, "v1.*"}},
           {"!=", {:keyword, "result"}, "passed"}},
    {"and", {"=", {:keyword, "branch"}, "master"},
            {"or", {"=~", {:keyword, "tag"}, "v1.*"}, {"!=", {:keyword, "result_reason"}, "stopped"}}},
    {"or", {"and", {"=", {:keyword, "branch"}, "master"}, {"!=", {:keyword, "result"}, "failed"}},
           {"and", {"and", {"=~", {:keyword, "tag"}, "v1.*"}, {"=", {:keyword, "result"}, "passed"}},
                   {"!=", {:keyword, "result_reason"}, "skipped"}}},
    {"and", {"=~", {:keyword, "pull_request"}, ".*"}, {"=", {:keyword, "result"}, "passed"}},
  ]

  @test_params_examples [
    %{"branch" => "master", "tag" => "v1.5", "result" => "passed", "pull_request" => "123",
     "result_reason" => "stopped"},
    %{"branch" => "dev", "tag" => "v1.5", "result" => "passed", "pull_request" => "123",
      "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v2.0", "result" => "passed", "pull_request" => "123",
      "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v1.5", "result" => "failed", "pull_request" => "123",
      "result_reason" => "stopped"},
    %{"branch" => "master", "tag" => "v2.0", "result" => "passed", "pull_request" => "",
      "result_reason" => "skipped"},
  ]

  @expected_results [
    [true, false, false, true, true, true, true, true],
    [true, false, false, false, false, false, true, true],
    [true, false, false, false, false, false, true, true],
    [true, false, false, true, true, true, false, false],
    [true, false, false, false, false, true, true, false],
  ]

  test "test interpreter behavior for various asts and parmas examples" do
    @test_params_examples
    |> Enum.with_index()
    |> Enum.map(fn {params, param_ind} ->
      @test_ast_examples
      |> Enum.with_index()
      |> Enum.map(fn {ast, ast_ind} ->
        result = Interpreter.evaluate(ast, params)
        expected = @expected_results |> Enum.at(param_ind) |> Enum.at(ast_ind)

        assert {param_ind, ast_ind, result} == {param_ind, ast_ind, expected}
      end)
    end)
  end

  test "return error when abstract syntax tree has unsupported operations" do
    invalid_op = {"invalid_op", "true", "false"}
    assert {:error, message} = Interpreter.evaluate(invalid_op, %{})
    assert message == "Unsupported value found while interpreting expression: '#{inspect invalid_op}'"
  end

  test "if value of keyword parameter isn't given all expression with it will return internal error" do
    [
     {"=", {:keyword, "branch"}, "master"}, {"!=", {:keyword, "branch"}, "master"},
     {"=~", {:keyword, "branch"}, "master"}, {"!~", {:keyword, "branch"}, "master"},
     {"and", {"=", {:keyword, "branch"}, "master"}, "false"}, {"and", "false", {"=", {:keyword, "branch"}, "master"}},
     {"or", {"=", {:keyword, "branch"}, "master"}, "false"}, {"or", "false", {"=", {:keyword, "branch"}, "master"}},
    ]
    |> Enum.map(fn ast ->
      assert {:error, message} = Interpreter.evaluate(ast, %{})
      assert message == "Missing value of keyword parameter 'branch'."
    end)
  end
end
