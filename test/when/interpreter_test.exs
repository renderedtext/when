defmodule When.Interpreter.Test do
  use ExUnit.Case

  alias When.Interpreter

  setup do
    Application.put_env(:when, :test_fun_0, {__MODULE__, :test_fun_0, 0})
    Application.put_env(:when, :test_fun_1, {__MODULE__, :test_fun_1, 1})
    Application.put_env(:when, :test_fun_2, {__MODULE__, :test_fun_2, 2})

    :ok
  end

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
    {"and", {:fun, :test_fun_0, []}, {"=", {:fun, :test_fun_1, ["master"]},
                                           {:fun, :test_fun_2, ["master", 0]}}}
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
    [true, false, false, true, true, true, true, true, false],
    [true, false, false, false, false, false, true, true, true],
    [true, false, false, false, false, false, true, true, false],
    [true, false, false, true, true, true, false, false, false],
    [true, false, false, false, false, true, true, false, false],
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

  test "various error when calling functions" do
    examples =
      [{:fun, :invalid_fun_name, []},
       {:fun, :test_fun_1, ["two, instead of", "one parameter"]},
       {:fun, :test_fun_2, ["function returns :error tuple", false]}]

    errors =
      ["Function with name 'invalid_fun_name' is not found.",
       "Function 'test_fun_1' accepts 1 parameter(s) and was provided with 2.",
       "Function 'test_fun_2' returned error: Second parameter must be integer."]

    examples
    |> Enum.with_index()
    |> Enum.map(fn {ast, index} ->
      assert {:error, message} = Interpreter.evaluate(ast, %{})
      assert message == errors |> Enum.at(index)
    end)
  end

  def test_fun_0(_params), do: {:ok, true}

  def test_fun_1(branch, params) do
    {:ok, params["branch"] == branch}
  end

  def test_fun_2(branch, int, params) when is_integer(int) do
    {:ok, params["branch"] == branch and int > 1}
  end

  def test_fun_2(_branch, _int, _params), do: {:error, "Second parameter must be integer."}
end
