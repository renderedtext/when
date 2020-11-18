defmodule When.Reducer.Result do
  @moduledoc """
  A result accumulator structure for the reducer.

  Example:

    ast = When.ast("branch = 'master' and result = 'passed'")
    inputs = Inputs.new() |> Inputs.add(:keyword, branch, "master")

    result = When.Reducer.reduce(ast, inputs)

    result.ast
    # => {"and", {...}, {...}}

    result.missing_inputs
    # => [
    #   %{type: :keyword, name: "result"}
    # ]
  """

  def new() do
    %{
      ast: nil,
      missing_inputs: []
    }
  end

  def set_ast(result, ast), do: %{result | ast: ast}

  def add_missing(result, :keyword, name) do
    update_in(result, [:missing_inputs], fn inputs ->
      inputs ++ [%{type: :keyword, name: name}]
    end)
  end

  def add_missing(result, :fun, name, params) do
    update_in(result, [:missing_inputs], fn inputs ->
      inputs ++ [%{type: :fun, name: name, params: params}]
    end)
  end

  def to_bool(result), do: When.Ast.to_bool(result.ast)

  def missing_inputs?(result) do
    result.missing_inputs != []
  end

  def join_missing_inputs(r1, r2) do
    r1.missing_inputs ++ r2.missing_inputs
  end
end
