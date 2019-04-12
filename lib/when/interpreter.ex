defmodule When.Interpreter do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces all keywords
  with actual values from given params map, and evaluates expression in order to
  return boolean value for when condition which given expression represents.
  """

  @keywords ~w(branch tag result result_reason)

  def evaluate(keyword, params) when keyword in @keywords do
    Map.get(params, keyword)
  end

  def evaluate("false", _params), do: false

  # any other string that is not 'false' or keyword is considered as true
  def evaluate(string, _params) when is_binary(string), do: true

  def evaluate({"and", first, second}, params) do
    evaluate(first, params) and evaluate(second, params)
  end

  def evaluate({"or", first, second}, params) do
    evaluate(first, params) or evaluate(second, params)
  end

  def evaluate({"=", keyword, value}, params) do
    evaluate(keyword, params) == value
  end

  def evaluate({"!=", keyword, value}, params) do
    evaluate(keyword, params) != value
  end

  def evaluate({"=~", keyword, pattern}, params) do
    value = evaluate(keyword, params)
    Regex.match?(~r/#{pattern}/, value)
  end

  def evaluate({"!~", keyword, pattern}, params) do
    value = evaluate(keyword, params)
    not Regex.match?(~r/#{pattern}/, value)
  end

  def evaluate(error_value, _params) do
    {:error, "Unsupported value found while interpreting expression: '#{to_str(error_value)}'"}
  end

  defp to_str(val) when is_binary(val), do: val
  defp to_str(val), do: "#{inspect val}"
end
