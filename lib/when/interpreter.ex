defmodule When.Interpreter do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces all keywords
  with actual values from given params map, and evaluates expression in order to
  return boolean value for when condition which given expression represents.
  """

  @keywords ~w(branch tag pr result result_reason)

  def evaluate(error = {:error, _}, _params), do: error

  def evaluate(keyword, params) when keyword in @keywords do
    error_404 = {:error, "Missing value of keyword parameter '#{keyword}'."}
    Map.get(params, keyword, error_404)
  end

  def evaluate("false", _params), do: false

  # any other string that is not 'false' or keyword is considered as true
  def evaluate(string, _params) when is_binary(string), do: true

  def evaluate({"and", first, second}, params) do
    l_value = evaluate(first, params)
    r_value = evaluate(second, params)
    evaluate_(l_value, r_value, __MODULE__, :and_func)
  end

  def evaluate({"or", first, second}, params) do
    l_value = evaluate(first, params)
    r_value = evaluate(second, params)
    evaluate_(l_value, r_value, __MODULE__, :or_func)
  end

  def evaluate({"=", keyword, r_value}, params) do
    l_value = evaluate(keyword, params)
    evaluate_(l_value, r_value, Kernel, :"==")
  end

  def evaluate({"!=", keyword, r_value}, params) do
    l_value = evaluate(keyword, params)
    evaluate_(l_value, r_value, Kernel, :"!=")
  end

  def evaluate({"=~", keyword, pattern}, params) do
    value = evaluate(keyword, params)
    evaluate_(~r/#{pattern}/, value, Regex, :match?)
  end

  def evaluate({"!~", keyword, pattern}, params) do
    value = evaluate(keyword, params)
    evaluate_(~r/#{pattern}/, value, __MODULE__, :not_match?)
  end

  def evaluate(error_value, _params) do
    {:error, "Unsupported value found while interpreting expression: '#{to_str(error_value)}'"}
  end

  # Utility

  defp evaluate_(error = {:error, _msg}, _r_value, _module, _func), do: error
  defp evaluate_(_l_value, error = {:error, _msg}, _module, _func), do: error
  defp evaluate_(_pattern, "", _module, :match?), do: false
  defp evaluate_(_pattern, "", _module, :not_match?), do: true
  defp evaluate_(l_value, r_value, module, func) do
    apply(module, func, [l_value, r_value])
  end

  # Helper matching function

  def not_match?(pattern, string), do: not Regex.match?(pattern, string)

  ## This is rquired because both Kernel.and and Kernel.or are macros, so they can
  ## not be called directly from apply/3
  def and_func(first, second), do: first and second
  def or_func(first, second), do: first or second

  defp to_str(val) when is_binary(val), do: val
  defp to_str(val), do: "#{inspect val}"
end
