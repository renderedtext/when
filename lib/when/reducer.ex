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

  defmodule Result do
    defstruct [:ast, :missing_input]

    def new(), do: %__MODULE__{ast: nil, missing_input: []}

    def add_missing_input(result, missing) do
      %{result | missing_input: result.missing_input ++ [missing]}
    end

    def set_ast(result, ast), do: %{result | ast: ast}

    def to_bool(result), do: When.Ast.to_bool(result.ast)
  end

  defmodule Inputs do
    def new() do
      %{
        "keywords" => %{},
        "functions" => []
      }
    end

    def add(inputs, :keyword, name, value) do
      keywords = Map.merge(inputs["keywords"], %{name => value})

      %{inputs | "keywords" => keywords}
    end

    def add(inputs, :fun, name, params, result) do
      entry = %{"name" => name, "params" => params, "result" => result}

      %{inputs | "functions" => inputs["functions"] ++ [entry]}
    end

    def get_keyword(inputs, name) do
      Map.get(inputs["keywords"], name)
    end

    def get_function(inputs, name, params) do
      inputs["functions"]
      |> Enum.find(fn el ->
        el["name"] == name && el["params"] == params
      end)
    end
  end

  alias __MODULE__.Result
  alias __MODULE__.Inputs

  @keywords ~w(branch tag pull_request result result_reason)
  @binary_ops ["and", "or", "=", "!=", "=~", "!~"]

  def reduce(ast) do
    reduce(ast, Inputs.new(), Result.new())
  end

  def reduce(ast, inputs) do
    reduce(ast, inputs, Result.new())
  end

  def reduce({:keyword, keyword}, inputs, result) when keyword in @keywords do
    kw = Inputs.get_keyword(inputs, keyword)

    if kw == nil do
      result
      |> Result.add_missing_input({:keyword, keyword})
      |> Result.set_ast({:keyword, keyword})
    else
      result |> Result.set_ast(kw)
    end
  end

  def reduce({:fun, name, fparams}, inputs, result) do
    fun = Inputs.get_function(inputs, Atom.to_string(name), fparams)

    if fun == nil do
      result
      |> Result.add_missing_input({:fun, name, fparams})
      |> Result.set_ast({:fun, name, fparams})
    else
      result |> Result.set_ast(fun["result"])
    end
  end

  def reduce({op, first, second}, input, result) when op in @binary_ops do
    l_result = reduce(first, input, result)
    r_result = reduce(second, input, result)

    if l_result.missing_input == [] && r_result.missing_input == [] do
      case op do
        "and" ->
          if Result.to_bool(l_result) and Result.to_bool(r_result) do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        "or" ->
          if Result.to_bool(l_result) or Result.to_bool(r_result) do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        "=" ->
          if l_result.ast == r_result.ast do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        "!=" ->
          if l_result.ast != r_result.ast do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        "=~" ->
          if regex_match?(r_result.ast, l_result.ast) do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        "!~" ->
          if not regex_match?(r_result.ast, l_result.ast) do
            result |> Result.set_ast(true)
          else
            result |> Result.set_ast(false)
          end

        _ ->
          # TODO
          false
      end
    else
      result = %{result | missing_input: l_result.missing_input ++ r_result.missing_input}

      result |> Result.set_ast({op, l_result.ast, r_result.ast})
    end
  end

  def reduce("false", _params, result), do: Result.set_ast(result, false)
  def reduce("true", _params, result), do: Result.set_ast(result, true)

  def reduce(v, _params, result) when is_boolean(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_binary(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_integer(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_float(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_list(v), do: Result.set_ast(result, v)
  def reduce(v, _params, result) when is_map(v), do: Result.set_ast(result, v)

  def regex_match?(pattern, value) do
    value != "" and Regex.match?(~r/#{pattern}/, value)
  end
end
