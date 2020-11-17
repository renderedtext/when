defmodule When.Ast do
  @binary_ops ["and", "or", "=", "!=", "=~", "!~"]

  defguard(is_binary_op?(op) when op in @binary_ops)

  def to_bool(ast) do
    case ast do
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
  end

  def to_expr(ast) do
    case ast do
      false ->
        "false"

      true ->
        "true"

      "true" ->
        "true"

      "false" ->
        "false"

      v when is_binary(v) ->
        "'#{v}'"

      v when is_integer(v) ->
        v

      v when is_float(v) ->
        v

      v when is_list(v) ->
        entries = Enum.map(v, &to_expr/1)

        "[" <> Enum.join(entries, ", ") <> "]"

      v when is_map(v) ->
        entries = Enum.map(v, fn {k, v} -> "#{k}: #{to_expr(v)}" end)

        "{" <> Enum.join(entries, ", ") <> "}"

      {:keyword, name} ->
        name

      {op, left, right} when is_binary_op?(op) ->
        binary_op_to_expr(op, left, right)

      {:fun, name, params} ->
        fun_to_expr(name, params)

      _ ->
        {:error, "sda"}
    end
  end

  def binary_op_to_expr(op, left, right) do
    "#{bracketize(left)} #{op} #{bracketize(right)}"
  end

  def bracketize(ast = {op, left, right}) when is_binary_op?(op), do: "(#{to_expr(ast)})"
  def bracketize(ast), do: to_expr(ast)

  def fun_to_expr(name, params) do
    params_expression = Enum.map(params, fn p -> to_expr(p) end) |> Enum.join(", ")

    "#{name}(#{params_expression})"
  end
end
