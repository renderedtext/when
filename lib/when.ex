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

  #
  #
  # PoC change_in evaluator.
  # Should be extracted from when parser into a dedicated system.
  #
  # The result of the evaluation is a list of evaluated change_in expressions.
  #
  # Example:
  #
  # [
  #   %{pattern: "lib/**/*.ex", options: %{...}, result: false},
  #   %{pattern: "test/lib/**/*.exs", options: %{...}, result: true}
  # ]
  #
  #
  def evaluate_change_in(input) do
    {:ok, tokens} = Lexer.tokenize(input)
    {:ok, ast} = Parser.parse(tokens)

    result = evaluate_change_in_from_ast(ast)

    IO.inspect(result)

    result
  end

  def evaluate_change_in_from_ast({"and", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({"or", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({"=", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({"!=", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({"=~", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({"!~", left, right}) do
    evaluate_change_in_from_ast(left) ++ evaluate_change_in_from_ast(right)
  end

  def evaluate_change_in_from_ast({:keyword, _}) do
    []
  end

  def evaluate_change_in_from_ast(str) when is_binary(str) do
    []
  end

  def evaluate_change_in_from_ast({:fun, :change_in, [pattern]}) do
    evaluate_change_in_from_ast({:fun, :change_in, [pattern, %{}]})
  end

  def evaluate_change_in_from_ast({:fun, :change_in, [pattern, options]}) do
    default_options = %{
      default_branch: "master",
      default_range: "somthing",
      branch_range: "#somthing...12312312",
      pipeline_file: "track",
      on_tags: true
    }

    options = Map.merge(default_options, options)

    [%{pattern: pattern, options: options, result: false}]
  end
end
