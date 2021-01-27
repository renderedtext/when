defmodule When do
  @moduledoc """
  Module takes string which represents some expression in DSL used for specifying
  when conditions in Semaphore yaml configurations and evaluates it into boolean
  value based on actual values of branch, tag, result etc. which are passed in
  params map.
  """

  alias When.{Lexer, Parser, Interpreter}

  def evaluate(string_expression, params, opts \\ []) do
    with {:ok, ast} <- ast(string_expression),
         result when is_boolean(result) <- Interpreter.evaluate(ast, params) do
      {:ok, result}
    end
  end

  def ast(exression) do
    {:ok, tokens} = Lexer.tokenize(exression)

    Parser.parse(tokens)
  end

  def inputs(expression) do
    with {:ok, ast} <- ast(expression),
         result <- When.Reducer.reduce(ast),
         {:ok, result} <- When.Reducer.Result.to_tuple(result) do
      {:ok, result}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def reduce(expression, inputs) do
    with {:ok, ast} <- ast(expression),
         result <- When.Reducer.reduce(ast, inputs),
         ast <- When.Ast.to_expr(result.ast) do
      {:ok, ast}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
