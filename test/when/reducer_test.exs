defmodule When.Interpreter.Test do
  use ExUnit.Case

  alias When.{Reducer}
  alias When.Reducer.{Inputs}

  describe "= operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch = 'master'")

      result = Reducer.reduce(ast)

      assert result.ast == {"=", {:keyword, "branch"}, "master"}

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"}
             ]
    end

    test "equal values" do
      {:ok, ast} = When.ast("branch = 'master'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    test "different values" do
      {:ok, ast} = When.ast("branch = 'master'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")

      assert Reducer.reduce(ast, inputs).ast == false
    end
  end

  describe "!= operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch != 'master'")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"}
             ]

      assert result.ast == {"!=", {:keyword, "branch"}, "master"}
    end

    test "equal values" do
      {:ok, ast} = When.ast("branch != 'master'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")

      assert Reducer.reduce(ast, inputs).ast == false
    end

    test "different values" do
      {:ok, ast} = When.ast("branch != 'master'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")

      assert Reducer.reduce(ast, inputs).ast == true
    end
  end

  describe "=~ operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch =~ 'mast.*'")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"}
             ]

      assert result.ast == {"=~", {:keyword, "branch"}, "mast.*"}
    end

    test "matched values" do
      {:ok, ast} = When.ast("branch =~ 'mast.*'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    test "non-matching values" do
      {:ok, ast} = When.ast("branch =~ 'mast.*'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")

      assert Reducer.reduce(ast, inputs).ast == false
    end

    # TODO
    # test "empty values with regex matches" do
    #   {:ok, ast1} = When.ast("branch =~ '.*'")
    #   {:ok, ast2} = When.ast("branch !~ '.*'")

    #   result = Reducer.reduce(ast1, %{"branch" => ""})
    #   assert result.ast == false

    #   result = Reducer.reduce(ast2, %{"branch" => ""})
    #   assert result.ast == true
    # end
  end

  describe "!~ operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch !~ 'mast.*'")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"}
             ]

      assert result.ast == {"!~", {:keyword, "branch"}, "mast.*"}
    end

    test "matched values" do
      {:ok, ast} = When.ast("branch !~ 'mast.*'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")

      assert Reducer.reduce(ast, inputs).ast == false
    end

    test "non-matching values" do
      {:ok, ast} = When.ast("branch !~ 'mast.*'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    # TODO
    # test "empty values with regex matches" do
    #   {:ok, ast1} = When.ast("branch =~ '.*'")
    #   {:ok, ast2} = When.ast("branch !~ '.*'")

    #   result = Reducer.reduce(ast1, %{"branch" => ""})
    #   assert result.ast == false

    #   result = Reducer.reduce(ast2, %{"branch" => ""})
    #   assert result.ast == true
    # end
  end

  describe "and operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch = 'master' and result = 'passed'")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"},
               %{type: :keyword, name: "result"}
             ]

      assert {"and", left, right} = result.ast
      assert left == {"=", {:keyword, "branch"}, "master"}
      assert right == {"=", {:keyword, "result"}, "passed"}
    end

    test "evaluating true and true" do
      {:ok, ast} = When.ast("branch = 'master' and result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")
        |> Inputs.add(:keyword, "result", "passed")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    test "evaluating true and false" do
      {:ok, ast} = When.ast("branch = 'master' and result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")
        |> Inputs.add(:keyword, "result", "failed")

      assert Reducer.reduce(ast, inputs).ast == false
    end

    test "evaluating false and false" do
      {:ok, ast} = When.ast("branch = 'master' and result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")
        |> Inputs.add(:keyword, "result", "failed")

      assert Reducer.reduce(ast, inputs).ast == false
    end
  end

  describe "or operation" do
    test "reduction without inputs" do
      {:ok, ast} = When.ast("branch = 'master' or result = 'passed'")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :keyword, name: "branch"},
               %{type: :keyword, name: "result"}
             ]

      assert {"or", left, right} = result.ast
      assert left == {"=", {:keyword, "branch"}, "master"}
      assert right == {"=", {:keyword, "result"}, "passed"}
    end

    test "evaluating true or true" do
      {:ok, ast} = When.ast("branch = 'master' or result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")
        |> Inputs.add(:keyword, "result", "passed")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    test "evaluating true or false" do
      {:ok, ast} = When.ast("branch = 'master' or result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "master")
        |> Inputs.add(:keyword, "result", "failed")

      assert Reducer.reduce(ast, inputs).ast == true
    end

    test "evaluating false or false" do
      {:ok, ast} = When.ast("branch = 'master' or result = 'passed'")

      inputs =
        Inputs.new()
        |> Inputs.add(:keyword, "branch", "dev")
        |> Inputs.add(:keyword, "result", "failed")

      assert Reducer.reduce(ast, inputs).ast == false
    end
  end

  test "reduces bracketed ops" do
    {:ok, ast} = When.ast("(branch = 'master' and result = 'passed') or result = 'failed'")

    result = Reducer.reduce(ast)

    assert result.missing_inputs == [
             %{type: :keyword, name: "branch"},
             %{type: :keyword, name: "result"},
             %{type: :keyword, name: "result"}
           ]

    assert {"or", {"and", and_left, and_right}, or_right} = result.ast
    assert and_left == {"=", {:keyword, "branch"}, "master"}
    assert and_right == {"=", {:keyword, "result"}, "passed"}
    assert or_right == {"=", {:keyword, "result"}, "failed"}
  end

  describe "functions" do
    test "reduction with no inputs" do
      {:ok, ast} = When.ast("change_in('lib')")

      result = Reducer.reduce(ast)

      assert result.missing_inputs == [
               %{type: :fun, name: :change_in, params: ["lib"]}
             ]
    end

    test "reduction with inputs" do
      {:ok, ast} = When.ast("change_in('lib')")

      inputs =
        Inputs.new()
        |> Inputs.add(:fun, "change_in", ["lib"], true)

      assert Reducer.reduce(ast, inputs).ast == true
    end
  end
end
