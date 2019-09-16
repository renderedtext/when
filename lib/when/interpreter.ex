defmodule When.Interpreter do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces all keywords
  with actual values from given params map, and evaluates expression in order to
  return boolean value for when condition which given expression represents.
  """

  @keywords ~w(branch tag pull_request result result_reason)

  def evaluate(string, params) do
    case evaluate_(string, params) do
      bool when is_boolean(bool)
        -> bool
      int when is_integer(int) and int >= 0
        -> true
      int when is_integer(int) and int < 0
        -> false
      float when is_float(float) and float >= 0.0
        -> true
      float when is_float(float) and float < 0.0
        -> false
      str when is_binary(str) and str != "false"
        -> true
      error -> error
    end
  end

  defp evaluate_(error = {:error, _}, _params), do: error

  defp evaluate_({:keyword, keyword}, params) when keyword in @keywords do
    error_404 = {:error, "Missing value of keyword parameter '#{keyword}'."}
    Map.get(params, keyword, error_404)
  end

  defp evaluate_("false", _params), do: false
  defp evaluate_("true", _params), do: true

  defp evaluate_(boolean, _params) when is_boolean(boolean), do: boolean
  defp evaluate_(string, _params) when is_binary(string), do: string
  defp evaluate_(integer, _params) when is_integer(integer), do: integer
  defp evaluate_(float, _params) when is_float(float), do: float

  defp evaluate_({"and", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(l_value, r_value, __MODULE__, :and_func)
  end

  defp evaluate_({"or", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(l_value, r_value, __MODULE__, :or_func)
  end

  defp evaluate_({"=", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(l_value, r_value, Kernel, :"==")
  end

  defp evaluate_({"!=", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(l_value, r_value, Kernel, :"!=")
  end

  defp evaluate_({"=~", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(~r/#{r_value}/, l_value, Regex, :match?)
  end

  defp evaluate_({"!~", first, second}, params) do
    l_value = evaluate_(first, params)
    r_value = evaluate_(second, params)
    apply_opp(~r/#{r_value}/, l_value, __MODULE__, :not_match?)
  end

  defp evaluate_(error_value, _params) do
    {:error, "Unsupported value found while interpreting expression: '#{to_str(error_value)}'"}
  end

  # Utility

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
  defp to_str(val), do: "#{inspect val}"
end
