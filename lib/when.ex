defmodule When do
  @moduledoc """
  Module takes string which represents some expression in DSL used for specifying
  when conditions in Semaphore yaml configurations and evaluates it into boolean
  value based on actual values of branch, tag, result etc. which are passed in
  params map.
  """

  alias When.{Lexer, Parser, Interpreter}

  def evaluate(string_expression, params, opts \\ []) do
    with {:ok, tokens} <- Lexer.tokenize(string_expression),
         {:ok, ast} <- Parser.parse(tokens),
         result when is_boolean(result) <-
           Interpreter.evaluate(ast, params, opts) do
      {:ok, result}
    end
  end

  def ast(string_expression) do
    with {:ok, tokens} <- Lexer.tokenize(string_expression),
         {:ok, ast} <- Parser.parse(tokens) do
      {:ok, ast}
    end
  end

  def ast!(string_expression) do
    {:ok, ast} = ast(string_expression)
    ast
  end

  def list_function_instances(string_expression, function_name) do
    {:ok, tokens} = Lexer.tokenize(string_expression)
    {:ok, ast} = Parser.parse(tokens)

    change_in_funs =
      When.AST.function_calls(ast)
      |> Enum.filter(fn %{name: name} ->
        name == "change_in"
      end)

    IO.inspect(change_in_funs)
  end
end
