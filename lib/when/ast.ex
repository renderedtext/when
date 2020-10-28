defmodule When.AST do
  @binary_operators ~w(and or = != =~ !~)

  @doc """
  Returns a list of function calls for provided function.

  Example:
    iex> "other_fun('b') and change_in('lib/*', {a: 'b'})"
    ...> |> When.ast!()
    ...> |> When.AST.function_calls(function_name: :change_in)
    [
      %{name: :change_in, params: ["lib/*", %{a: "b"}]}
    ]
  """
  def function_calls(ast, function_name: name) do
    function_calls(ast) |> Enum.filter(fn call -> call.name == name end)
  end

  @doc """
  Returns a list of all function calls in the provided AST.

  Example:
    iex> "branch = 'master' and change_in('lib/*', {a: 'b'})"
    ...> |> When.ast!()
    ...> |> When.AST.function_calls()
    [
      %{name: :change_in, params: ["lib/*", %{a: "b"}]}
    ]
  """
  def function_calls(ast) do
    case ast do
      {:fun, name, params} = ast ->
        [%{name: name, params: params}]

      {op, left, right} when op in @binary_operators ->
        function_calls(left) ++ function_calls(right)

      _ ->
        []
    end
  end
end
