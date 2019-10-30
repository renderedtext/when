defmodule When do
  @moduledoc """
  Module takes string which represents some expression in DSL used for specifying
  when conditions in Semaphore yaml configurations and evaluates it into boolean
  value based on actual values of branch, tag, result etc. which are passed in
  params map.
  """

  alias  When.{Lexer, Parser, Interpreter}

  def evaluate(string_expression, params, opts \\ []) do
    with {:ok, tokens} <- Lexer.tokenize(string_expression),
         {:ok, ast}    <- Parser.parse(tokens),
         result when is_boolean(result)
                       <- Interpreter.evaluate(ast, params, opts)
    do
      {:ok, result}
    end
  end
end
