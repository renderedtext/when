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
end
