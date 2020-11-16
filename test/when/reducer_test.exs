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

  @keywords ~w(branch tag pull_request result result_reason)
  @binary_ops ["and", "or", "=", "!=", "=~", "!~"]

  def reduce(ast, params) do
    reduce(ast, params, Result.new())
  end

  def reduce({:keyword, keyword}, params, result) when keyword in @keywords do
    input = Map.get(params, keyword)

    if input == nil do
      Result.add_missing_input(result, {:keyword, keyword})
    else
      Result.set_ast(result, input)
    end
  end

  defp reduce({op, first, second}, input, result) when op in @binary_ops do
    l_result = reduce(first, input, result)
    r_result = reduce(second, input, result)

    case op do
      "and" ->
        Result.set_ast(result, "false")

      "or" ->
        Result.set_ast(result, "false")

      "=" ->
        Result.set_ast(result, "false")

      "!=" ->
        Result.set_ast(result, "false")

      "=~" ->
        Result.set_ast(result, "false")

      "!~" ->
        Result.set_ast(result, "false")

      _ ->
        false
    end
  end

  defp reduce(v, _params, result) when is_boolean(boolean), do: Result.set_ast(result, v)
  defp reduce(v, _params, result) when is_binary(string), do: Result.set_ast(result, v)
  defp reduce(v, _params, result) when is_integer(integer), do: Result.set_ast(result, v)
  defp reduce(v, _params, result) when is_float(float), do: Result.set_ast(result, v)
  defp reduce(v, _params, result) when is_list(list), do: Result.set_ast(result, v)
  defp reduce(v, _params, result) when is_map(map), do: Result.set_ast(result, v)

  # Utility

  defmodule Result do
    defstruct :missing_input

    def new(), do: %__MODULE__{ast: nil, missing_params: []}
    def add_missing_input(result, missing), do: %{result | missing_input: missing}
    def set_ast(result, ast), do: %{result | ast: ast}

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

  defp apply_opp(error = {:error, _msg}, _r_value, _module, _func), do: error
  defp apply_opp(_l_value, error = {:error, _msg}, _module, _func), do: error
  defp apply_opp(_pattern, "", _module, :match?), do: false
  defp apply_opp(_pattern, "", _module, :not_match?), do: true

  defp apply_opp(l_value, r_value, module, func) do
    apply(module, func, [l_value, r_value])
  end

  # Helper matching function

  def not_match?(pattern, string), do: not Regex.match?(pattern, string)

  ## This is required because both Kernel.and and Kernel.or are macros, so they can
  ## not be called directly from apply/3
  def and_func(first, second), do: first and second
  def or_func(first, second), do: first or second

  defp to_str(val) when is_binary(val), do: val

  defp to_str([elem | list]) when is_integer(elem) and is_list(list) and length(list) >= 2 do
    "#{elem}, #{to_str(list)}"
  end

  defp to_str(list) when is_list(list) and length(list) == 2,
    do: "#{Enum.at(list, 0)} or #{Enum.at(list, 1)}"

  defp to_str(list) when is_list(list) and length(list) == 1, do: "#{Enum.at(list, 0)}"
  defp to_str(val), do: "#{inspect(val)}"
end
