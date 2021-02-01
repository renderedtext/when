defmodule When.Reducer do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces keywords
  with actual values from given input map, and reduces expression to a simpler
  one.

  Example:

    ast = When.ast("branch = 'master' and result = 'passed'")
    inputs = Inputs.new() |> Inputs.add(:keyword, branch, "master")

    result = When.Reducer.reduce(ast, inputs)

    result.ast
    # => {"and", true, {"=", {:keyword, "result"}, "passed"}

    When.Ast.to_expt(result.ast)
    # => true and (result = 'passed')

    result.missing_inputs
    # => [
    #   %{type: :keyword, name: "result"},
    # ]

  To list all the necessary input for an expression, call reduce without inputs:

    ast = When.ast("branch = 'master' and result = 'passed'")
    inputs = Inputs.new() |> Inputs.add(:keyword, branch, "master")

    result = When.Reducer.reduce(ast, inputs)

    result.missing_inputs
    # => [
    #   %{type: :keyword, name: "result"},
    #   %{type: :keyword, name: "branch"}
    # ]
  """

  alias __MODULE__.Result
  alias __MODULE__.Inputs

  @keywords ~w(branch tag pull_request result result_reason)
  @binary_ops ["and", "or", "=", "!=", "=~", "!~"]

  #
  # Entry-points for the reducer.
  #
  # Call reduce(ast) to list all necessary inputs.
  # Call reduce(ast, inputs) to reduce the expression based on the inputs.
  #

  def reduce(ast) do
    reduce(ast, Inputs.new(), Result.new())
  end

  def reduce(ast, inputs) do
    reduce(ast, inputs, Result.new())
  end

  #
  # Iterating through the AST, elements can be either:
  #
  #  - simple-values
  #  - {:keywords, keyword}
  #  - {:fun, name, params}
  #  - {binary_op, left_tree, right_tree}
  #

  def reduce("false", _params, result), do: Result.set_ast(result, false)
  def reduce("true", _params, result), do: Result.set_ast(result, true)

  def reduce(v, _params, result) when is_boolean(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_binary(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_integer(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_float(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_list(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_map(v), do: Result.set_ast(result, v)

  def reduce({:keyword, keyword}, inputs, result) when keyword in @keywords do
    kw = Inputs.get_keyword(inputs, keyword)

    if kw == nil do
      result
      |> Result.add_missing(:keyword, keyword)
      |> Result.set_ast({:keyword, keyword})
    else
      result |> Result.set_ast(kw)
    end
  end

  def reduce({:fun, name, fparams}, inputs, result) do
    fun = Inputs.get_function(inputs, Atom.to_string(name), fparams)

    if fun == nil do
      result
      |> Result.add_missing(:fun, name, fparams)
      |> Result.set_ast({:fun, name, fparams})
    else
      result |> Result.set_ast(fun["result"])
    end
  end

  def reduce({op, first, second}, input, result) when op in @binary_ops do
    l_result = reduce(first, input, result)
    r_result = reduce(second, input, result)

    if Result.missing_inputs?(l_result) or Result.missing_inputs?(r_result) do
      result = %{result | missing_inputs: Result.join_missing_inputs(l_result, r_result)}

      result |> Result.set_ast({op, l_result.ast, r_result.ast})
    else
      binary_op_res = binary_op(op, l_result, r_result)

      result |> Result.set_ast(binary_op_res)
    end
  end

  def binary_op(op, l_result, r_result) do
    case op do
      "and" ->
        Result.to_bool(l_result) and Result.to_bool(r_result)

      "or" ->
        Result.to_bool(l_result) or Result.to_bool(r_result)

      "=" ->
        l_result.ast == r_result.ast

      "!=" ->
        l_result.ast != r_result.ast

      "=~" ->
        regex_match?(r_result.ast, l_result.ast)

      "!~" ->
        not regex_match?(r_result.ast, l_result.ast)

      _ ->
        # TODO
        raise "not yet implemented"
    end
  end

  def regex_match?(pattern, value) do
    value != "" and Regex.match?(~r/#{pattern}/, value)
  end
end
