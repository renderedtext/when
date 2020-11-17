defmodule When.Reducer do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces keywords
  with actual values from given input map, and reduces expression to a simpler
  one.

  Example:

  ast = {"and", {"=", "branch", "master"}, {"fun", "change_in", ["lib"]}}
  input = %{branch: "master"}

  output = Reducer.reduce(ast, input)
  # => {"and", true, {"fun", "change_in", ["lib"]}}
  """

  alias __MODULE__.Result

  @keywords ~w(branch tag pull_request result result_reason)
  @binary_ops ["and", "or", "=", "!=", "=~", "!~"]

  def reduce(ast, params) do
    reduce(ast, params, Result.new())
  end

  def reduce({:keyword, keyword}, params, result) when keyword in @keywords do
    input = Map.get(params, keyword)

    if input == nil do
      result
      |> Result.add_missing_input({:keyword, keyword})
      |> Result.set_ast({:keyword, keyword})
      |> Result.set_expression(keyword)
    else
      result
      |> Result.set_ast(input)
      |> Result.set_expression(input)
    end
  end

  def reduce({:fun, name, fparams}, input, result) do
    result
    |> Result.add_missing_input({:fun, name, fparams})
    |> Result.set_expression("#{name}(#{inspect(fparams)})")
  end

  def reduce({op, first, second}, input, result) when op in @binary_ops do
    l_result = reduce(first, input, result)
    r_result = reduce(second, input, result)

    if l_result.missing_input == [] && r_result.missing_input == [] do
      case op do
        "and" ->
          if Result.to_bool(l_result) and Result.to_bool(r_result) do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        "or" ->
          if Result.to_bool(l_result) or Result.to_bool(r_result) do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        "=" ->
          if l_result.ast == r_result.ast do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        "!=" ->
          if l_result.ast != r_result.ast do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        "=~" ->
          if regex_match?(r_result.ast, l_result.ast) do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        "!~" ->
          if not regex_match?(r_result.ast, l_result.ast) do
            result |> Result.set_ast(true) |> Result.set_expression("true")
          else
            result |> Result.set_ast(false) |> Result.set_expression("false")
          end

        _ ->
          # TODO
          false
      end
    else
      result = %{result | missing_input: l_result.missing_input ++ r_result.missing_input}
      result = result |> Result.set_ast({op, l_result.ast, r_result.ast})

      l_exp =
        if match?({op, _, _}, l_result.ast) and op in @binary_ops do
          "(#{l_result.expression})"
        else
          l_result.expression
        end

      r_exp =
        if match?({op, _, _}, r_result.ast) and op in @binary_ops do
          "(#{r_result.expression})"
        else
          r_result.expression
        end

      result |> Result.set_expression("#{l_exp} #{op} #{r_exp}")
    end
  end

  def reduce("false", _params, result), do: Result.set_ast(result, false)
  def reduce("true", _params, result), do: Result.set_ast(result, true)

  def reduce(v, _params, result) when is_boolean(v),
    do: result |> Result.set_ast(v) |> Result.set_expression(v)

  def reduce(v, _params, result) when is_binary(v),
    do: result |> Result.set_ast(v) |> Result.set_expression("'#{v}'")

  def reduce(v, _params, result) when is_integer(v),
    do: result |> Result.set_ast(v) |> Result.set_expression(v)

  def reduce(v, _params, result) when is_float(v),
    do: result |> Result.set_ast(v) |> Result.set_expression(v)

  def reduce(v, _params, result) when is_list(v),
    do: result |> Result.set_ast(v) |> Result.set_expression(v)

  def reduce(v, _params, result) when is_map(v),
    do: result |> Result.set_ast(v) |> Result.set_expression(v)

  # Utility

  defmodule Result do
    defstruct [:ast, :missing_input, :expression]

    def new(), do: %__MODULE__{ast: nil, expression: nil, missing_input: []}

    def add_missing_input(result, missing) do
      %{result | missing_input: result.missing_input ++ [missing]}
    end

    def set_ast(result, ast), do: %{result | ast: ast}
    def set_expression(result, expression), do: %{result | expression: expression}

    def to_bool(result) do
      if result.missing_input == [] do
        case result.ast do
          bool when is_boolean(bool) ->
            bool

          int when is_integer(int) and int >= 0 ->
            true

          int when is_integer(int) and int < 0 ->
            false

          float when is_float(float) and float >= 0.0 ->
            true

          float when is_float(float) and float < 0.0 ->
            false

          str when is_binary(str) and str != "false" ->
            true

          list when is_list(list) and length(list) == 0 ->
            false

          list when is_list(list) and length(list) > 0 ->
            true

          map when is_map(map) and map_size(map) == 0 ->
            false

          map when is_map(map) and map_size(map) > 0 ->
            true

          _ ->
            # do this better
            {:error, "Can't"}
        end
      else
        # do this better
        {:error, "Missing values"}
      end
    end
  end

  def regex_match?(pattern, value) do
    value != "" and Regex.match?(~r/#{pattern}/, value)
  end

  def to_str(val) when is_binary(val), do: val

  def to_str([elem | list]) when is_integer(elem) and is_list(list) and length(list) >= 2 do
    "#{elem}, #{to_str(list)}"
  end

  def to_str(list) when is_list(list) and length(list) == 2,
    do: "#{Enum.at(list, 0)} or #{Enum.at(list, 1)}"

  def to_str(list) when is_list(list) and length(list) == 1, do: "#{Enum.at(list, 0)}"
  def to_str(val), do: "#{inspect(val)}"
end
