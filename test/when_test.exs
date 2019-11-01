defmodule When.Test do
  use ExUnit.Case

  setup do
    Application.put_env(:when, :test_fun_0, {__MODULE__, :test_fun_0, 0})
    Application.put_env(:when, :test_fun_1, {__MODULE__, :test_fun_1, 1})
    Application.put_env(:when, :test_fun_2, {__MODULE__, :test_fun_2, 2})
    Application.put_env(:when, :failing_fun, {__MODULE__, :failing_fun, 1})
    Application.put_env(:when, :test_fun_3, {__MODULE__, :test_fun_3, 2})

    :ok
  end

  @valid_examples [
    "true",
    "('false')",
    "(FALSE) AND TAG != 'v1.*'",
    "branch = 'master' and tag =~ 'v1.*'",
    "(branch = 'master' and tag =~ 'v1.*') or result != 'passed'",
    "branch = 'master' AND (tag =~ 'v1.*' OR result_reason != 'stopped')",
    "(branch = 'master' and result != 'failed') or
     (tag =~ 'v1.*' and result = 'passed' and result_reason != 'skipped')",
    "pull_request =~ '.*' and result = 'passed'",
    "test_fun_0() and (test_fun_1('master') = test_fun_2('master', 0))",
    "(test_fun_3([1, 2], [['a', 'b'], []]) or branch = 'master') and [1.0, 'uiop']",
  ]

  @valid_params_examples [
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
      [true, false, false, true, true, true, true, true, false, true],
      [true, false, false, false, false, false, true, true, true, false],
      [true, false, false, false, false, false, true, true, false, true],
      [true, false, false, true, true, true, false, false, false, true],
      [true, false, false, false, false, true, true, false, false, true],
    ]

  test "test module top level behavior for various string and pramas combination" do
    @valid_params_examples
    |> Enum.with_index()
    |> Enum.map(fn {params, param_ind} ->
      @valid_examples
      |> Enum.with_index()
      |> Enum.map(fn {string, str_ind} ->
        assert {:ok, result} = When.evaluate(string, params)
        expected = @expected_results |> Enum.at(param_ind) |> Enum.at(str_ind)

        assert {param_ind, str_ind, result} == {param_ind, str_ind, expected}
      end)
    end)
  end

  test "empty string value of keyword parameter does not match '.*' regex" do
    params = %{"branch" => "master", "tag" => "", "pull_request" => "123"}

    assert {:ok, false} = When.evaluate("tag =~ '.*'", params)
    assert {:ok, true}  = When.evaluate("tag !~ '.*'", params)

    assert {:ok, true}  = When.evaluate("branch =~ '.*'", params)
    assert {:ok, false} = When.evaluate("branch !~ '.*'", params)

    assert {:ok, true} = When.evaluate("pull_request =~ '.*'", params)
    assert {:ok, false}  = When.evaluate("pull_request !~ '.*'", params)
  end

  @invald_strings_parser [
    "(true and false) = 'master'",
    "'master' != (true and false)",
    "and branch != 'master'",
    " =~ 'master'",
    "branch !~",
    "'true' or",
    "=",
    "(branch = 'master'",
    "true or false)"
  ]

  @error_messages_parser [
    "Invalid expression on the left of '=' operator.",
    "Invalid expression on the left of '('.",
    "Invalid expression on the left of 'and' operator.",
    "Invalid expression on the left of '=~' operator.",
    "Invalid or incomplete expression at the end of the line.",
    "Invalid or incomplete expression at the end of the line.",
    "Invalid expression on the left of '=' operator.",
    "Invalid or incomplete expression at the end of the line.",
    "Invalid expression on the left of ')'."
  ]

  test "returns syntax error when given string with invalid syntax" do
    params = @valid_params_examples |> Enum.at(0)

    @invald_strings_parser
    |> Enum.with_index()
    |> Enum.map(fn {string, index} ->
      assert {:error, message} = When.evaluate(string, params)
      specific_error = @error_messages_parser |> Enum.at(index)
      assert {message, index} ==
        {"Syntax error on line 1. - " <> specific_error, index}
    end)
  end

  @invald_strings_lexer [
    "branch ! = 'bad operator'",
    "{branch = 'unsupported-brackets'} and true",
    "# branch = 'unsupported-characters'",
    "_identifier_needs_to_start_with_lettter(123)",
    "cant_contain_&^('identifier only accepts alfa-numerics, uderscores and dashes')",
    "fun(123.0) and invalid_number(123.456.2323)"
  ]

  @error_messages_lexer [
    "Illegal characters: '! '.",
    "Illegal characters: '{'.",
    "Illegal characters: '#'.",
    "Illegal characters: '_'.",
    "Illegal characters: '&'.",
    "Illegal characters: '.'."
  ]

  test "lexer returns error when invalid string is given" do
    params = @valid_params_examples |> Enum.at(0)

    @invald_strings_lexer
    |> Enum.with_index()
    |> Enum.map(fn {string, index} ->
      assert {:error, message} = When.evaluate(string, params)
      specific_error = @error_messages_lexer |> Enum.at(index)
      assert {message, index} ==
        {"Lexical error on line 1. - " <> specific_error, index}
    end)
  end

  test "when 'dry_run: true' option is given => funtions are not executed" do
    string = "failing_fun('param 1')"
    params = @valid_params_examples |> Enum.at(0)

    assert {:ok, false} = When.evaluate(string, params, dry_run: true)
  end

  test "when 'dry_run: true' option is given => no of params for function is checked" do
    string = "failing_fun('param 1', 'one too many param')"
    params = @valid_params_examples |> Enum.at(0)

    assert {:error, msg} = When.evaluate(string, params, dry_run: true)
    assert msg == "Function 'failing_fun' accepts 1 parameter(s) and was provided with 2."
  end

  def test_fun_0(_params), do: {:ok, true}

  def test_fun_1(branch, params) do
    {:ok, params["branch"] == branch}
  end

  def test_fun_2(branch, int, params) when is_integer(int) do
    {:ok, params["branch"] == branch and int > 1}
  end

  def test_fun_2(_branch, _int, _params), do: {:error, "Second parameter must be integer."}

  def failing_fun(_param, _params), do: {:error, "This always fails."}

  def test_fun_3(_list_1, _list_2, _params), do: {:ok, false}
end
