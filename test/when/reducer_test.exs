defmodule When.Interpreter.Test do
  use ExUnit.Case

  alias When.{Reducer}

  test "reduces equality" do
    {:ok, ast} = When.ast("branch = 'master'")

    result = Reducer.reduce(ast, %{"branch" => "master"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    result = Reducer.reduce(ast, %{"branch" => "dev"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}]
    assert result.ast == {"=", {:keyword, "branch"}, "master"}
    assert result.expression == "branch = 'master'"
  end

  test "reduces inequality" do
    {:ok, ast} = When.ast("branch != 'master'")

    result = Reducer.reduce(ast, %{"branch" => "master"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{"branch" => "dev"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}]
    assert result.ast == {"!=", {:keyword, "branch"}, "master"}
    assert result.expression == "branch != 'master'"
  end

  test "reduces regex match" do
    {:ok, ast} = When.ast("branch =~ 'mast.*'")

    result = Reducer.reduce(ast, %{"branch" => "master"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    result = Reducer.reduce(ast, %{"branch" => "dev"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}]
    assert result.ast == {"=~", {:keyword, "branch"}, "mast.*"}
    assert result.expression == "branch =~ 'mast.*'"
  end

  test "reduces negative regex match" do
    {:ok, ast} = When.ast("branch !~ 'mast.*'")

    result = Reducer.reduce(ast, %{"branch" => "master"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{"branch" => "dev"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}]
    assert result.ast == {"!~", {:keyword, "branch"}, "mast.*"}
    assert result.expression == "branch !~ 'mast.*'"
  end

  test "reduces and operations" do
    {:ok, ast} = When.ast("branch = 'master' and result = 'passed'")

    # true and true
    result = Reducer.reduce(ast, %{"branch" => "master", "result" => "passed"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    # true and false
    result = Reducer.reduce(ast, %{"branch" => "master", "result" => "failed"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    # false and true
    result = Reducer.reduce(ast, %{"branch" => "dev", "result" => "passed"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    # false and false
    result = Reducer.reduce(ast, %{"branch" => "dev", "result" => "failed"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}, {:keyword, "result"}]
    assert {op, left, right} = result.ast
    assert op == "and"
    assert left == {"=", {:keyword, "branch"}, "master"}
    assert right == {"=", {:keyword, "result"}, "passed"}
    assert result.expression == "branch = 'master' and result = 'passed'"
  end

  test "reduces or operations" do
    {:ok, ast} = When.ast("branch = 'master' or result = 'passed'")

    # true and true
    result = Reducer.reduce(ast, %{"branch" => "master", "result" => "passed"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    # true and false
    result = Reducer.reduce(ast, %{"branch" => "master", "result" => "failed"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    # false and true
    result = Reducer.reduce(ast, %{"branch" => "dev", "result" => "passed"})
    assert result.missing_input == []
    assert result.ast == true
    assert result.expression == "true"

    # false and false
    result = Reducer.reduce(ast, %{"branch" => "dev", "result" => "failed"})
    assert result.missing_input == []
    assert result.ast == false
    assert result.expression == "false"

    result = Reducer.reduce(ast, %{})
    assert result.missing_input == [{:keyword, "branch"}, {:keyword, "result"}]
    assert {op, left, right} = result.ast
    assert op == "or"
    assert left == {"=", {:keyword, "branch"}, "master"}
    assert right == {"=", {:keyword, "result"}, "passed"}
    assert result.expression == "branch = 'master' or result = 'passed'"
  end
end
