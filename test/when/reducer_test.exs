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

  describe "regex" do
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

    test "empty values with regex matches" do
      {:ok, ast1} = When.ast("branch =~ '.*'")
      {:ok, ast2} = When.ast("branch !~ '.*'")

      result = Reducer.reduce(ast1, %{"branch" => ""})
      assert result.ast == false

      result = Reducer.reduce(ast2, %{"branch" => ""})
      assert result.ast == true
    end
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
    assert result.expression == "(branch = 'master') and (result = 'passed')"
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
    assert {"or", left, right} = result.ast
    assert left == {"=", {:keyword, "branch"}, "master"}
    assert right == {"=", {:keyword, "result"}, "passed"}
    assert result.expression == "(branch = 'master') or (result = 'passed')"
  end

  test "reduces bracketed ops" do
    {:ok, ast} = When.ast("(branch = 'master' and result = 'passed') or result = 'failed'")

    result = Reducer.reduce(ast, %{})

    assert result.missing_input == [
             {:keyword, "branch"},
             {:keyword, "result"},
             {:keyword, "result"}
           ]

    assert {"or", {"and", and_left, and_right}, or_right} = result.ast
    assert and_left == {"=", {:keyword, "branch"}, "master"}
    assert and_right == {"=", {:keyword, "result"}, "passed"}
    assert or_right == {"=", {:keyword, "result"}, "failed"}

    assert result.expression ==
             "((branch = 'master') and (result = 'passed')) or (result = 'failed')"
  end
end
